// Autoria de Lucas Soares Gonçalves RA 25009467
import { spawn } from 'node:child_process';
import { resolve } from 'node:path';
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import neo4j from 'neo4j-driver';

const directory = resolve('backups/projeto-integrador');
const command = process.env.NEO4J_ADMIN_PATH;
if (!command || !process.env.NEO4J_PASSWORD) throw new Error('Defina NEO4J_ADMIN_PATH e configure a conexão do Aura no .env.');
if (!/^neo4j\+s:\/\/[a-z0-9]+\.databases\.neo4j\.io$/.test(process.env.NEO4J_URI ?? '')) {
  throw new Error('Destino deve ser uma instância Aura com TLS.');
}
const driver = neo4j.driver(process.env.NEO4J_URI, neo4j.auth.basic(process.env.NEO4J_USERNAME, process.env.NEO4J_PASSWORD));
try {
  const result = await driver.executeQuery('MATCH (n) RETURN count(n) AS total', {}, { database: process.env.NEO4J_DATABASE, routing: 'READ' });
  if (!result.records[0].get('total').equals(neo4j.int(0))) throw new Error('Destino contém dados. Migração recusada para preservar o grafo existente.');
} finally { await driver.close(); }
const dump = await readFile(resolve(directory, 'neo4j.dump'));
const manifest = { origin: 'Projeto_integrador', sourceVersion: '2026.09.0',
  destination: process.env.NEO4J_URI, bytes: dump.length,
  sha256: createHash('sha256').update(dump).digest('hex'), startedAt: new Date().toISOString() };
await writeFile(resolve(directory, 'migracao.json'), JSON.stringify(manifest, null, 2));
const child = spawn(command, ['database', 'upload', 'neo4j', `--from-path=${directory}`,
  `--to-uri=${process.env.NEO4J_URI}`, '--overwrite-destination=true'], {
  env: process.env, stdio: 'inherit',
});
const exit = await new Promise((res, rej) => { child.on('exit', res); child.on('error', rej); });
manifest.exitCode = exit;
manifest.finishedAt = new Date().toISOString();
await writeFile(resolve(directory, 'migracao.json'), JSON.stringify(manifest, null, 2));
process.exitCode = exit ?? 1;
