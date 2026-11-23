// Autoria de Lucas Soares Gonçalves RA 25009467
import { execFile } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import net from 'node:net';
import path from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { promisify, parseEnv } from 'node:util';

const exec = promisify(execFile);
const keys = ['NEO4J_URI', 'NEO4J_USERNAME', 'NEO4J_PASSWORD', 'NEO4J_DATABASE'];

export async function loadLocalGraph(backend) {
  const file = path.join(backend, '.env.neo4j-local');
  const contents = await readFile(file, 'utf8').catch(error => {
    if (error.code !== 'ENOENT') throw error;
    throw Error('Configuração local ausente. Veja a seção Neo4j local no README.');
  });
  const values = parseEnv(contents);
  const uri = URL.parse(values.NEO4J_URI ?? '');
  if (!uri || uri.protocol !== 'neo4j:' || !['localhost', '127.0.0.1', '[::1]'].includes(uri.hostname) ||
      uri.username || uri.password || !keys.every(key => values[key])) {
    throw Error('Confira a conexão local em backend/.env.neo4j-local.');
  }

  const connection = Object.fromEntries(keys.map(key => [key, values[key]]));
  return { connection, home: values.TRILHA_NEO4J_HOME, java: values.TRILHA_JAVA_HOME };
}

export async function startLocalGraph({ home, java, connection }, launch) {
  // Se o Neo4j for gerenciado pelo Desktop ou Docker, basta informar a conexão.
  if (!home || process.platform === 'win32') return;

  const binary = path.join(home, 'bin', 'neo4j');
  const options = {
    cwd: home,
    env: { ...process.env, ...(java ? { JAVA_HOME: java } : {}) },
  };

  try {
    await exec(binary, ['status'], { ...options, timeout: 10000 });
    return;
  } catch (error) {
    if (error.code !== 3) throw Error('Não foi possível conferir a instalação local do Neo4j.');
  }

  const started = launch(binary, ['console'], home, true, java ? { JAVA_HOME: java } : {});
  let ended = false;
  started.finished.then(() => { ended = true; }, () => { ended = true; });

  const uri = new URL(connection.NEO4J_URI);
  const port = Number(uri.port || 7687);
  const host = uri.hostname === '[::1]' ? '::1' : uri.hostname;
  const deadline = Date.now() + 45000;
  while (!ended && Date.now() < deadline) {
    if (await listening(host, port)) {
      console.log('Neo4j local iniciado.');
      return;
    }
    await delay(500);
  }
  throw Error('Não foi possível iniciar o Neo4j local. Confira os registros na instalação local.');
}

function listening(host, port) {
  return new Promise(resolve => {
    const socket = net.createConnection({ host, port });
    const close = connected => {
      socket.destroy();
      resolve(connected);
    };
    socket.setTimeout(1000);
    socket.once('connect', () => close(true));
    socket.once('timeout', () => close(false));
    socket.once('error', () => close(false));
  });
}
