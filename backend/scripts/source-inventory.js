import neo4j from 'neo4j-driver';
import { writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';

const uri = process.env.INVENTORY_URI ?? 'neo4j://127.0.0.1:7687';
const password = process.env.INVENTORY_URI ? process.env.NEO4J_PASSWORD : process.env.SOURCE_NEO4J_PASSWORD;
if (!password) { console.error('Senha da origem ausente no arquivo .env.'); process.exit(1); }
const driver = neo4j.driver(uri, neo4j.auth.basic(process.env.INVENTORY_URI ? process.env.NEO4J_USERNAME : (process.env.SOURCE_NEO4J_USERNAME ?? 'neo4j'), password));
const session = driver.session({ database: process.env.INVENTORY_URI ? process.env.NEO4J_DATABASE : 'neo4j', defaultAccessMode: neo4j.session.READ });
function canonical(v) {
  if (neo4j.isInt(v)) return v.inSafeRange() ? v.toNumber() : v.toString();
  if (Array.isArray(v)) return v.map(canonical);
  if (v && typeof v === 'object') return Object.fromEntries(Object.keys(v).sort().map(k => [k, canonical(v[k])]));
  return v;
}
const hash = value => createHash('sha256').update(JSON.stringify(canonical(value))).digest('hex');
try {
  const nodes = await session.run('MATCH (n) RETURN elementId(n) AS eid, labels(n) AS labels, properties(n) AS properties');
  const nodeHashes = new Map(nodes.records.map(r => [r.get('eid'), hash([r.get('labels').sort(), r.get('properties')])]));
  const relationships = await session.run('MATCH (a)-[r]->(b) RETURN elementId(a) AS a, elementId(b) AS b, type(r) AS type, properties(r) AS properties');
  const relHashes = relationships.records.map(r => hash([nodeHashes.get(r.get('a')), r.get('type'), nodeHashes.get(r.get('b')), r.get('properties')]));
  const labels = {};
  for (const r of nodes.records) for (const label of r.get('labels')) labels[label] = (labels[label] ?? 0) + 1;
  const types = {};
  for (const r of relationships.records) types[r.get('type')] = (types[r.get('type')] ?? 0) + 1;
  const constraints = await session.run('SHOW CONSTRAINTS YIELD name, type, labelsOrTypes, properties RETURN *');
  const indexes = await session.run("SHOW INDEXES YIELD name, type, labelsOrTypes, properties, owningConstraint WHERE type <> 'LOOKUP' RETURN *");
  const data = { nodes: nodes.records.length, relationships: relationships.records.length,
    labels, types, nodeHash: hash([...nodeHashes.values()].sort()), relationshipHash: hash(relHashes.sort()),
    constraints: constraints.records.map(r => canonical(r.toObject())), indexes: indexes.records.map(r => canonical(r.toObject())),
  };
  if (process.env.INVENTORY_OUTPUT) await writeFile(process.env.INVENTORY_OUTPUT, JSON.stringify(data, null, 2));
  console.log(JSON.stringify(data, null, 2));
  const questions = nodes.records.filter(r => r.get('labels').some(x => /quest/i.test(x)));
  console.log('Amostra de questão:', JSON.stringify(canonical(questions[0]?.get('properties') ?? {})));
} finally { await session.close(); await driver.close(); }
