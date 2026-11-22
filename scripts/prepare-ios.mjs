// Autoria de Lucas Soares Gonçalves RA 25009467
import { createHash, randomUUID } from 'node:crypto';
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
const destinoJava = {
  host: env.JAVA_TCP_HOST || destino.host,
  port: Number(env.JAVA_TCP_PORT || 3000),
  tempo: 2500,
};

if (!Number.isInteger(destinoJava.port) || destinoJava.port < 1 || destinoJava.port > 65535) {
  throw new Error('Informe uma porta TCP válida em JAVA_TCP_PORT.');
}

async function iniciarEmSegundoPlano(comando, argumentos, nome, cwd, ambiente = process.env) {
  const log = await open(path.join(local, nome + '.log'), 'a');

  try {
    const filho = spawn(comando, argumentos, {
      cwd, env: ambiente, detached: true, stdio: ['ignore', log.fd, log.fd],
    });
    await once(filho, 'spawn');
    filho.unref();
    await salvarArquivoLocal(nome + '.pid', String(filho.pid));
    return filho;
  } finally {
    await log.close();
  }
}

async function salvarArquivoLocal(nome, conteudo) {
  // Substitui o arquivo sem precisar baixar uma versão antiga do OneDrive.
  const temporario = path.join(local, nome + '.' + randomUUID() + '.tmp');
  await writeFile(temporario, conteudo);
  await rename(temporario, path.join(local, nome));
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
  if (caminho === '/health/live' && resposta && resposta.corpo?.autenticacao !== 'java-http') {
    throw new Error('A porta TCP do Node está em uso por outra versão. Encerre a execução anterior e tente novamente.');
  }
  return resposta;
}

let estado = await consultarApi('/health/live');
const grafoLocal = ['localhost', '127.0.0.1', '[::1]'].includes(new URL(config.NEO4J_URI).hostname);
if (estado && estado.corpo.grafo !== (grafoLocal ? 'local' : 'remoto')) {
  throw new Error('A API já está em execução com outra configuração do Neo4j. Encerre a execução anterior para trocar de banco.');
}

// Confere primeiro se o Java está escutando, mesmo se o Node ainda não subiu.
const respostaJava = await enviarPedidoTcp(
  { tipo: 'VALIDAR_LOGIN', email: 'invalido', senha: 'teste' }, destinoJava,
).catch(() => null);
if (respostaJava?.codigo !== 'VALIDACAO_INVALIDA') {
  throw new Error(`Inicie o Java em ${destinoJava.host}:${destinoJava.port} conforme docs/EXECUCAO_SERVIDOR.md.`);
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

// O e-mail reservado tem formato válido e não pertence a uma conta. A recusa
// esperada confirma que a solicitação chegou ao Node e consultou o MongoDB.
const respostaIntegracao = await enviarPedidoTcp({
  tipo: 'VALIDAR_LOGIN', email: 'verificacao-' + randomUUID() + '@example.test', senha: 'sonda-local',
}, { ...destinoJava, tempo: 14000 }).catch(() => null);
if (respostaIntegracao?.codigo !== 'OPERACAO_RECUSADA' ||
    respostaIntegracao.mensagem !== 'E-mail ou senha incorretos.') {
  throw new Error('O Java respondeu, mas o login não chegou ao MongoDB. Confira -Dnode.url e AUTH_HTTP_PORT.');
}

const prontidao = await consultar({ metodo: 'GET', caminho: '/health/ready' }, {
  ...destino, tempo: 15000,
}).catch(() => null);
if (prontidao?.status !== 200) {
  console.warn('Catálogo Neo4j indisponível. O diagnóstico e a prática precisam do grafo.');
}

// O terminal e o VS Code usam os endereços que o preparo acabou de testar.
// O arquivo do Flutter contém apenas hosts e portas.
await salvarArquivoLocal('frontend-tcp.json', JSON.stringify({
  API_TCP_HOST: destino.host,
  API_TCP_PORT: String(destino.port),
  JAVA_TCP_HOST: destinoJava.host,
  JAVA_TCP_PORT: String(destinoJava.port),
}));

console.log(`Node e Java prontos em ${destino.host}:${destino.port} e ${destinoJava.host}:${destinoJava.port}.`);
