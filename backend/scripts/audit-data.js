// Autoria de Lucas Soares Gonçalves RA 25009467
import { createDatabases } from '../src/databases.js';
import { readConfig } from '../src/config.js';
import { auditGraph } from './audit-graph.js';
import { auditMongo } from './audit-mongo.js';

const databases = createDatabases(readConfig());
try {
  await databases.connect();
  const graph = await auditGraph(databases);
  const mongo = await auditMongo(databases, graph);
  console.log(JSON.stringify({ neo4j: graph.report, mongodb: mongo }, null, 2));
} finally {
  await databases.close();
}
