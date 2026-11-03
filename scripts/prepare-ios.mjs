import { createHash } from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import { access, lstat, mkdir, open, readlink, realpath, rename, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const frontend = path.join(repo, 'frontend');
const local = path.join(repo, '.local');
await mkdir(local, { recursive: true });

// Keep only generated build artifacts outside cloud-sync folders. Sources stay
// in the original workspace so VS Code breakpoints and hot reload keep working.
const key = createHash('sha256').update(await realpath(frontend)).digest('hex').slice(0, 12);
const cache = path.join(tmpdir(), `trilha-ios-${key}`, 'build');
const build = path.join(frontend, 'build');
await mkdir(cache, { recursive: true });
const current = await lstat(build).catch(error => { if (error.code !== 'ENOENT') throw error; });
if (current?.isSymbolicLink()) {
  const existing = path.resolve(path.dirname(build), await readlink(build));
  if (existing !== cache) throw Error('A pasta build já aponta para outro local. Preserve essa configuração antes de continuar.');
} else if (current) {
  if (!current.isDirectory()) throw Error('O caminho frontend/build não é uma pasta.');
  const copied = spawnSync('/usr/bin/rsync', ['-a', '--exclude=.DS_Store', `${build}/`, `${cache}/`], { encoding: 'utf8' });
  if (copied.status !== 0) throw Error('Não foi possível preparar o cache iOS: ' + (copied.stderr ?? copied.error?.message ?? 'falha na cópia'));
  const backup = path.join(local, 'ios-build-backups');
  await mkdir(backup, { recursive: true });
  await rename(build, path.join(backup, `build-${Date.now()}`));
  await symlink(cache, build, 'dir');
} else {
  await symlink(cache, build, 'dir');
}
console.log('Cache de compilação preparado fora do OneDrive. Código-fonte preservado.');
if (process.argv.includes('--cache-only')) process.exit(0);

const base = 'http://127.0.0.1:3000';
async function status() {
  let live;
  try {
    live = await fetch(base + '/health/live', { signal: AbortSignal.timeout(2000) });
  } catch {
    return { running: false, ready: false };
  }
  let service;
  try { service = await live.json(); } catch { /* Handled by the compatibility check below. */ }
  if (!live.ok || service?.status !== 'ok') throw Error('Outro serviço está usando a porta 3000.');
  try {
    const response = await fetch(base + '/health/ready', { signal: AbortSignal.timeout(3000) });
    const data = await response.json();
    if (typeof data.mongodb !== 'boolean' || typeof data.neo4j !== 'boolean') {
      throw Error('Resposta incompatível na porta 3000.');
    }
    return { running: true, ready: response.ok && data.mongodb && data.neo4j };
  } catch (error) {
    if (error.message === 'Resposta incompatível na porta 3000.') throw error;
    return { running: true, ready: false };
  }
}

let state = await status();
if (!state.running) {
  await access(path.join(repo, 'backend', '.env'));
  const log = await open(path.join(local, 'api-ios.log'), 'a');
  const child = spawn(process.execPath, ['--env-file=.env', 'src/server.js'], {
    cwd: path.join(repo, 'backend'), detached: true, stdio: ['ignore', log.fd, log.fd],
  });
  child.unref();
  await log.close();
  await writeFile(path.join(local, 'api-ios.pid'), String(child.pid));
}
const deadline = Date.now() + 40000;
while (!state.ready && Date.now() < deadline) {
  await new Promise(resolve => setTimeout(resolve, 1000));
  state = await status();
}
if (!state.ready) throw Error('API ou bancos ainda indisponíveis. Confira .local/api-ios.log e a liberação do IP atual no Atlas.');
console.log('API, MongoDB e Neo4j prontos para o simulador em ' + base);
