import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { access, mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseEnv } from 'node:util';
import { loadLocalGraph, startLocalGraph } from './neo4j-local.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const backend = path.join(root, 'backend');
const local = path.join(root, '.local');
const children = new Set();
let interrupted = false;
const args = process.argv.slice(2);
const checking = args.includes('--check');
const localGraph = args.includes('--neo4j-local');

function stop() {
  for (const child of children) {
    if (child.exitCode === null && !child.killed) child.kill('SIGTERM');
  }
}
for (const signal of ['SIGINT', 'SIGTERM']) {
  process.once(signal, () => { interrupted = true; stop(); });
}

function command(executable, args, cwd, quiet = false, overrides = {}) {
  const child = spawn(executable, args, {
    cwd, stdio: quiet ? 'ignore' : 'inherit',
    env: { ...process.env, ...overrides },
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
  if (previous !== fingerprint || !await exists(path.join(backend, 'node_modules', 'zod', 'package.json'))) {
    console.log('Instalando as dependências da API…');
    await command('npm', ['ci', '--no-audit', '--no-fund'], backend).finished;
    await mkdir(local, { recursive: true });
    await writeFile(marker, fingerprint);
  }
}

async function main() {
  const allowed = ['--check', '--neo4j-local', '--help', '-h'];
  if (args.some(arg => !allowed.includes(arg)) || new Set(args).size !== args.length) {
    throw new Error('Use node scripts/iniciar.mjs --help para consultar as opções.');
  }
  if (args.includes('--help') || args.includes('-h')) {
    console.log('Uso: node scripts/iniciar.mjs [--check] [--neo4j-local]\nSem opções: abre o app no iPhone simulado.\n--check: testa os dois bancos e encerra.\n--neo4j-local: usa o grafo deste computador e mantém o Atlas.');
    return;
  }
  if (Number(process.versions.node.split('.')[0]) < 22) throw new Error('Instale Node.js 22 ou mais recente antes de continuar.');
  const envFile = path.join(backend, '.env');
  if (!await exists(envFile)) throw new Error('Coloque o arquivo de credenciais recebido em backend/.env. Consulte o README.');
  const settings = localGraph ? await loadLocalGraph(backend) : null;
  const overrides = settings?.connection ?? {};
  const env = { ...parseEnv(await readFile(envFile, 'utf8')), ...process.env, ...overrides };
  await dependencies();
  const { readConfig } = await import('../backend/src/config.js');
  try { readConfig(env); }
  catch (error) {
    const fields = [...new Set((error.issues ?? []).map(issue => issue.path.join('.')))];
    throw new Error(`Arquivo backend/.env incompleto ou inválido${fields.length ? ': ' + fields.join(', ') : ''}. Confira o arquivo trilha-grupo.env e o README.`);
  }
  if (settings) await startLocalGraph(settings, command);
  if (checking) {
    await command(process.execPath, ['--env-file=.env', 'scripts/check.js'], backend, false, overrides).finished;
    console.log('Conexões verificadas. MongoDB e Neo4j disponíveis.');
    return;
  }
  await command('bash', ['scripts/rodar-iphone.sh'], root, false, overrides).finished;
}

try { await main(); }
catch (error) { if (!interrupted) console.error('\n' + error.message); process.exitCode = 1; }
finally { stop(); if (interrupted) process.exitCode = 130; }
