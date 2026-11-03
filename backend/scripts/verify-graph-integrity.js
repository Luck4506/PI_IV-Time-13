import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { createDatabases } from '../src/databases.js';
import { readConfig } from '../src/config.js';

const db = createDatabases(readConfig());
function normalize(value) {
  if (value?.toNumber) return value.inSafeRange() ? value.toNumber() : value.toString();
  if (Array.isArray(value)) return value.map(normalize);
  if (value && typeof value === 'object') return Object.fromEntries(Object.keys(value).sort().map(key => [key, normalize(value[key])]));
  return value;
}
const sorted = rows => rows.map(x => JSON.stringify(normalize(x))).sort();
try {
  const [nodes, edges, constraints, indexes] = await Promise.all([
    db.query('MATCH (n) RETURN labels(n) AS labels, properties(n) AS properties'),
    db.query('MATCH (a)-[r]->(b) RETURN labels(a) AS fromLabels, properties(a) AS fromProperties, type(r) AS type, properties(r) AS properties, labels(b) AS toLabels, properties(b) AS toProperties'),
    db.query('SHOW CONSTRAINTS YIELD name, type, labelsOrTypes, properties RETURN *'),
    db.query("SHOW INDEXES YIELD name, type, labelsOrTypes, properties, owningConstraint WHERE type <> 'LOOKUP' RETURN *"),
  ]);
  const nodeRows = nodes.records.map(x => x.toObject());
  const edgeRows = edges.records.map(x => x.toObject());
  const labels = {}, types = {};
  for (const node of nodeRows) for (const label of node.labels) labels[label] = (labels[label] ?? 0) + 1;
  for (const edge of edgeRows) types[edge.type] = (types[edge.type] ?? 0) + 1;
  const backup = JSON.parse(await readFile('backups/projeto-integrador/inventario-aura.json', 'utf8'));
  assert.equal(nodeRows.length, backup.nodes); assert.equal(edgeRows.length, backup.relationships);
  assert.deepEqual(labels, backup.labels); assert.deepEqual(types, backup.types);
  assert.deepEqual(sorted(constraints.records.map(x => x.toObject())), sorted(backup.constraints));
  assert.deepEqual(sorted(indexes.records.map(x => x.toObject())), sorted(backup.indexes));
  const hash = createHash('sha256').update(JSON.stringify({ nodes: sorted(nodeRows), edges: sorted(edgeRows) })).digest('hex');
  const report = { checkedAt: new Date().toISOString(), status: 'ok', nodes: nodeRows.length,
    relationships: edgeRows.length, labels, types, originalStructurePreserved: true, fullDataHash: hash };
  const startPath = '../.local/REVISAO_GRAFO_INICIO.json';
  if (process.argv.includes('--before')) await writeFile(startPath, JSON.stringify(report, null, 2));
  else {
    const before = JSON.parse(await readFile(startPath, 'utf8'));
    assert.equal(hash, before.fullDataHash);
    report.allGraphPropertiesUnchangedDuringTests = true;
    await writeFile('../.local/REVISAO_GRAFO.json', JSON.stringify(report, null, 2));
  }
  console.log(JSON.stringify(report, null, 2));
} finally { await db.close(); }
