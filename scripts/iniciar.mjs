import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { access, mkdir, readFile, writeFile } from 'node:fs/promises';
import net from 'node:net';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseEnv } from 'node:util';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const backend = path.join(root, 'backend');
const frontend = path.join(root, 'frontend');
const local = path.join(root, '.local');
const children = new Set();
let interrupted = false;
const args = process.argv.slice(2);
const checking = args[0] === '--check';

function stop() {
  for (const child of children) {
    if (child.exitCode === null && !child.killed) child.kill('SIGTERM');
  }
}
for (const signal of ['SIGINT', 'SIGTERM']) {
  process.once(signal, () => { interrupted = true; stop(); });
}

function command(executable, args, cwd, quiet = false) {
  const child = spawn(executable, args, {
    cwd, stdio: quiet ? 'ignore' : 'inherit',
    // Windows runs npm.cmd and flutter.bat through its command interpreter.
    shell: process.platform === 'win32' && executable !== process.execPath,
  });
  children.add(child);
  child.once('close', () => children.delete(child));
  return { child, finished: new Promise((resolve, reject) => {
    child.once('error', () => reject(new Error(`Não foi possível executar ${executable}. Confira a instalação e o PATH.`)));
    child.once('close', code => code === 0 ? resolve() : reject(new Error(`${executable} encerrou sem concluir. Confira a mensagem acima.`)));
  }) };
}
async function exists(file) { try { await access(file); return true; } catch { return false; } }

async function dependencies() {
  const files = await Promise.all(['package.json', 'package-lock.json'].map(file => readFile(path.join(backend, file))));
  const fingerprint = createHash('sha256').update(Buffer.concat(files))
    .update(`${process.versions.node.split('.')[0]}-${process.platform}-${process.arch}`).digest('hex');
  const marker = path.join(local, 'backend-dependencies.sha256');
  const previous = await readFile(marker, 'utf8').catch(() => '');
  if (previous !== fingerprint || !await exists(path.join(backend, 'node_modules', 'express', 'package.json'))) {
    console.log('Instalando as dependências da API…');
    await command('npm', ['ci', '--no-audit', '--no-fund'], backend).finished;
    await mkdir(local, { recursive: true });
    await writeFile(marker, fingerprint);
  }
}

async function apiState() {
  let response;
  try { response = await fetch('http://127.0.0.1:3000/health/live', { signal: AbortSignal.timeout(2000) }); }
  catch { return { running: false, ready: false }; }
  let data;
  try { data = await response.json(); } catch { /* Verified below. */ }
  if (!response.ok || data?.status !== 'ok') throw new Error('A porta 3000 está ocupada por outro serviço. Encerre-o antes de iniciar o Trilha.');
  try {
    const ready = await fetch('http://127.0.0.1:3000/health/ready', { signal: AbortSignal.timeout(3000) });
    const data = await ready.json();
    return { running: true, ready: ready.ok && data.mongodb === true && data.neo4j === true };
  } catch { return { running: true, ready: false }; }
}

async function frontendPortBusy() {
  return new Promise(resolve => {
    const socket = net.createConnection({ host: '127.0.0.1', port: 5173 });
    socket.setTimeout(1500);
    socket.once('connect', () => { socket.destroy(); resolve(true); });
    socket.once('error', () => { socket.destroy(); resolve(false); });
    socket.once('timeout', () => { socket.destroy(); resolve(true); });
  });
}

async function main() {
  if (args.length > 1 || (args[0] && !['--check', '--help', '-h'].includes(args[0]))) {
    throw new Error('Use node scripts/iniciar.mjs ou node scripts/iniciar.mjs --check.');
  }
  if (args.includes('--help') || args.includes('-h')) {
    console.log('Uso: node scripts/iniciar.mjs [--check]\nSem opções: instala dependências e inicia API e app Web.\n--check: instala dependências da API e testa os dois bancos, sem abrir o app.');
    return;
  }
  if (Number(process.versions.node.split('.')[0]) < 22) throw new Error('Instale Node.js 22 ou mais recente antes de continuar.');
  const envFile = path.join(backend, '.env');
  if (!await exists(envFile)) throw new Error('Coloque o arquivo de credenciais recebido em backend/.env. Consulte o README.');
  const env = parseEnv(await readFile(envFile, 'utf8'));
  if ((env.HOST ?? '127.0.0.1') !== '127.0.0.1' || (env.PORT ?? '3000') !== '3000') {
    throw new Error('O iniciador usa HOST=127.0.0.1 e PORT=3000. Para outras portas, siga a execução manual no README.');
  }
  if (!checking) {
    if (!await exists(path.join(frontend, 'lib', 'main.dart'))) {
      throw new Error('Esta cópia está incompleta: falta frontend/lib/main.dart. Baixe a versão completa do projeto antes de executar o app.');
    }
    await command('flutter', ['--version'], root, true).finished;
    if (await frontendPortBusy()) throw new Error('A porta 5173 já está em uso. Encerre a execução anterior do app e tente novamente.');
  }
  await dependencies();
  const { readConfig } = await import('../backend/src/config.js');
  try { readConfig(env); }
  catch (error) {
    const fields = [...new Set((error.issues ?? []).map(issue => issue.path.join('.')))];
    throw new Error(`Arquivo backend/.env incompleto ou inválido${fields.length ? ': ' + fields.join(', ') : ''}. Peça o arquivo correto ao responsável do grupo.`);
  }
  if (checking) {
    await command(process.execPath, ['--env-file=.env', 'scripts/check.js'], backend).finished;
    console.log('Conexões verificadas. MongoDB e Neo4j disponíveis.');
    return;
  }
  console.log('Preparando as dependências do aplicativo…');
  await command('flutter', ['pub', 'get'], frontend).finished;
  let state = await apiState();
  let api;
  if (!state.running) {
    const started = command(process.execPath, ['--env-file=.env', 'src/server.js'], backend);
    api = started.child;
    // apiState supplies the readiness result; this handler prevents an unhandled rejection.
    started.finished.catch(() => {});
  } else console.log('Reutilizando a API que já está em execução na porta 3000.');
  const deadline = Date.now() + 45000;
  while (!state.ready && Date.now() < deadline && !interrupted) {
    if (api && api.exitCode !== null) throw new Error('A API encerrou antes de conectar aos bancos. Confira a mensagem acima.');
    await new Promise(resolve => setTimeout(resolve, 1000));
    state = await apiState();
  }
  if (interrupted) return;
  if (!state.ready) throw new Error('Os bancos ainda não responderam. Confira a internet e execute node scripts/iniciar.mjs --check.');
  console.log('\nAPI e bancos prontos. Aguarde o Flutter informar que o app está disponível.\nAbra http://127.0.0.1:5173 no navegador. Mantenha este terminal aberto.\nUse Ctrl+C ou q para encerrar esta execução.\n');
  await command('flutter', ['run', '-d', 'web-server', '--web-hostname=127.0.0.1', '--web-port=5173', '--dart-define=API_BASE_URL=http://127.0.0.1:3000'], frontend).finished;
}

try { await main(); }
catch (error) { if (!interrupted) console.error('\n' + error.message); process.exitCode = 1; }
finally { stop(); if (interrupted) process.exitCode = 130; }
