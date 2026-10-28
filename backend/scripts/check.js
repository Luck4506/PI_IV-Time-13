import { readConfig } from '../src/config.js';
import { createDatabases } from '../src/databases.js';
const databases = createDatabases(readConfig());
try {
  await databases.connect();
  await databases.db.command({ ping: 1 });
  const result = await databases.query('MATCH (n) RETURN count(n) AS total');
  console.log(JSON.stringify({ mongodb: 'ok', neo4j: 'ok', nos: result.records[0].get('total').toNumber() }, null, 2));
} finally { await databases.close(); }
