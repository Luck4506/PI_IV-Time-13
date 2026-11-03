import { readConfig } from '../src/config.js';
import { createDatabases } from '../src/databases.js';
let databases;
try { databases = createDatabases(readConfig()); }
catch { console.error('Configuração inválida. Confira backend/.env conforme o README.'); process.exit(1); }

function reason(error) {
  const message = String(error?.message ?? '') + ' ' + String(error?.cause?.message ?? '');
  if (/ENOTFOUND|EAI_AGAIN|ECONNREFUSED.*querySrv/.test(message)) return 'Não foi possível resolver o endereço. Confira a rede e se a instância está ativa no painel da nuvem.';
  if (/Authentication|Unauthorized|unauthorized|authentication|credentials/.test(message)) return 'Confira as credenciais recebidas com o responsável pelo grupo.';
  return 'Confira a conexão à internet, a disponibilidade da instância e as regras de acesso da rede.';
}
try {
  const [mongo, graph] = await Promise.allSettled([
    (async () => { await databases.mongo.connect(); await databases.db.command({ ping: 1 }); })(),
    databases.query('MATCH (n) RETURN count(n) AS total'),
  ]);
  console.log(JSON.stringify({
    mongodb: mongo.status === 'fulfilled' ? 'ok' : 'indisponivel',
    neo4j: graph.status === 'fulfilled' ? 'ok' : 'indisponivel',
    ...(graph.status === 'fulfilled' ? { nos: graph.value.records[0].get('total').toNumber() } : {}),
  }, null, 2));
  if (mongo.status === 'rejected') console.error('MongoDB: ' + reason(mongo.reason));
  if (graph.status === 'rejected') console.error('Neo4j: ' + reason(graph.reason));
  if (mongo.status === 'rejected' || graph.status === 'rejected') process.exitCode = 1;
} finally { await databases.close(); }
