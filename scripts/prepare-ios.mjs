import { createHash } from 'node:crypto';
import { spawn, execFileSync } from 'node:child_process';
import { once } from 'node:events';
import { access, lstat, mkdir, open, readFile, readlink, realpath, rename, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseEnv } from 'node:util';
import { setTimeout as esperar } from 'node:timers/promises';
import { enderecoApiTcp, enviarPedidoTcp } from '../backend/src/tcp-client.js';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const frontend = path.join(repo, 'frontend');
const local = path.join(repo, '.local');
await mkdir(local, { recursive: true });

// Só os arquivos gerados saem do OneDrive. O código fica no projeto para
// manter os pontos de parada do VS Code e o hot reload.
const key = createHash('sha256').update(await realpath(frontend)).digest('hex').slice(0, 12);
const cache = path.join(tmpdir(), `trilha-ios-${key}`);
const backups = path.join(local, 'ios-build-backups');

async function prepareGeneratedDirectory(destination, name) {
  const target = path.join(cache, name);
  await mkdir(target, { recursive: true });

  const current = await lstat(destination).catch(error => {
    if (error.code !== 'ENOENT') throw error;
  });
  if (current?.isSymbolicLink()) {
    const existing = path.resolve(path.dirname(destination), await readlink(destination));
    if (existing !== target) throw Error(`A pasta ${name} já aponta para outro local. Confira o caminho antes de continuar.`);
    return;
  }

  if (current) {
    if (!current.isDirectory()) throw Error(`O caminho ${destination} não é uma pasta.`);

    // Renomear evita ler artefatos que o OneDrive deixou só na nuvem.
    // O Flutter recria os arquivos gerados no cache local.
    await mkdir(backups, { recursive: true });
    await rename(destination, path.join(backups, `${name}-${Date.now()}`));
  }

  await symlink(target, destination, 'dir');
}

await prepareGeneratedDirectory(path.join(frontend, 'build'), 'build');
await prepareGeneratedDirectory(path.join(frontend, 'ios', 'Flutter', 'ephemeral'), 'ephemeral');
console.log('Build e pacotes gerados pelo Flutter preparados fora do OneDrive.');
if (process.argv.includes('--cache-only')) process.exit(0);

const backend = path.join(repo, 'backend');
const arquivoEnv = path.join(backend, '.env');
const valores = await readFile(arquivoEnv, 'utf8').catch(error => {
  if (error.code !== 'ENOENT') throw error;
  throw new Error('Coloque o arquivo de configuração em backend/.env.');
});
const env = { ...parseEnv(valores), ...process.env };

try {
  await access(path.join(backend, 'node_modules', 'zod', 'package.json'));
} catch {
  console.log('Instalando as dependências do Node.js…');
  execFileSync('npm', ['ci', '--no-audit', '--no-fund'], { cwd: backend, stdio: 'inherit' });
}

const { readConfig } = await import('../backend/src/config.js');
let config;
try {
  config = readConfig(env);
} catch (error) {
  const campos = [...new Set(error.issues?.map(item => item.path.join('.')))];
  throw new Error('Confira a configuração em backend/.env: ' + campos.join(', '));
}
const destino = { ...enderecoApiTcp(config), tempo: 2500 };

async function iniciarEmSegundoPlano(comando, argumentos, nome, cwd, ambiente = process.env) {
  const log = await open(path.join(local, nome + '.log'), 'a');

  try {
    const filho = spawn(comando, argumentos, {
      cwd, env: ambiente, detached: true, stdio: ['ignore', log.fd, log.fd],
    });
    await once(filho, 'spawn');
    filho.unref();
    await writeFile(path.join(local, nome + '.pid'), String(filho.pid));
    return filho;
  } finally {
    await log.close();
  }
}

async function consultar(pedido, endereco) {
  try {
    return await enviarPedidoTcp(pedido, endereco);
  } catch (error) {
    if (error.code === 'ECONNREFUSED') return null;
    throw error;
  }
}

async function consultarApi(caminho) {
  const resposta = await consultar({ metodo: 'GET', caminho }, destino);
  if (caminho === '/health/live' && resposta && resposta.corpo?.protocolo !== 'trilha-tcp') {
    throw new Error('Já existe outro processo na porta TCP. Encerre a execução anterior e tente novamente.');
  }
  return resposta;
}

let estado = await consultarApi('/health/live');
const grafoLocal = ['localhost', '127.0.0.1', '[::1]'].includes(new URL(config.NEO4J_URI).hostname);
if (estado && estado.corpo.grafo !== (grafoLocal ? 'local' : 'remoto')) {
  throw new Error('A API já está em execução com outra configuração do Neo4j. Encerre a execução anterior para trocar de banco.');
}

let processoNode;
if (!estado) {
  processoNode = await iniciarEmSegundoPlano(process.execPath, ['src/server.js'], 'api-ios', backend, env);
}
const prazo = Date.now() + 45000;
while (!estado?.corpo?.mongodb && Date.now() < prazo) {
  if (processoNode && processoNode.exitCode !== null) break;
  await esperar(750);
  estado = await consultarApi('/health/live');
}
if (!estado?.corpo?.mongodb) {
  throw new Error('A API não confirmou a conexão com o MongoDB. Confira .local/api-ios.log.');
}

const prontidao = await consultarApi('/health/ready').catch(() => null);
if (prontidao?.status !== 200) {
  console.warn('Catálogo Neo4j indisponível. O diagnóstico e a prática precisam do grafo.');
}

// O terminal e o VS Code usam o mesmo endereço que o preparo acabou de testar.
// Só o host e a porta vão para o Flutter. O .env fica no backend.
await writeFile(path.join(local, 'frontend-tcp.json'), JSON.stringify({
  API_TCP_HOST: destino.host,
  API_TCP_PORT: String(destino.port),
}));

console.log(`API pronta. O aplicativo usa TCP em ${destino.host}:${destino.port}.`);
