import { readConfig } from '../src/config.js';
import { createDatabases } from '../src/databases.js';
const databases = createDatabases(readConfig());
try {
  const queries = {
    labels: 'MATCH (n) UNWIND labels(n) AS label RETURN label, count(*) AS total ORDER BY label',
    relacionamentos: 'MATCH ()-[r]->() RETURN type(r) AS tipo, count(*) AS total ORDER BY tipo',
    constraints: 'SHOW CONSTRAINTS YIELD name, type, labelsOrTypes, properties RETURN *',
    indices: 'SHOW INDEXES YIELD name, type, labelsOrTypes, properties RETURN *',
  };
  for (const [name, query] of Object.entries(queries)) {
    const result = await databases.query(query);
    console.log(name, JSON.stringify(result.records.map(r => r.toObject()), (_, v) => v?.toNumber ? v.toNumber() : v));
  }
} finally { await databases.close(); }
