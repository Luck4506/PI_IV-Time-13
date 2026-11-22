// Autoria de Lucas Soares Gonçalves RA 25009467
import { readConfig } from '../src/config.js';
import { createDatabases } from '../src/databases.js';
import { countExamQuestions } from '../src/exam-questions.js';

let databases;
try {
  databases = createDatabases(readConfig());
} catch {
  console.error('Configuração inválida. Confira backend/.env conforme o README.');
  process.exit(1);
}

async function checkMongo() {
  await databases.mongo.connect();
  await databases.db.command({ ping: 1 });
}

async function checkGraph() {
  const [result, questoesOficiais] = await Promise.all([
    databases.query('MATCH (n) RETURN count(n) AS total'),
    countExamQuestions(databases),
  ]);
  const nos = result.records[0].get('total').toNumber();
  return { nos, questoesOficiais };
}

function reason(error) {
  const message = [error?.message, error?.cause?.message].join(' ');

  // Usamos mensagens genéricas porque alguns erros incluem o endereço do banco.
  if (/ENOTFOUND|EAI_AGAIN|ECONNREFUSED.*querySrv/.test(message)) {
    return 'Não foi possível resolver o endereço. Confira a rede e se a instância está ativa no painel da nuvem.';
  }
  if (/authentication|unauthorized|credentials/i.test(message)) {
    return 'Confira as credenciais no arquivo de configuração.';
  }
  return 'Confira a conexão à internet, a disponibilidade da instância e as regras de acesso da rede.';
}

try {
  const [mongo, graph] = await Promise.allSettled([checkMongo(), checkGraph()]);
  const mongoOk = mongo.status === 'fulfilled';
  const graphOk = graph.status === 'fulfilled';
  const report = {
    mongodb: mongoOk ? 'ok' : 'indisponivel',
    neo4j: graphOk ? 'ok' : 'indisponivel',
    ...(graphOk ? graph.value : {}),
  };
  console.log(JSON.stringify(report, null, 2));

  if (!mongoOk) console.error('MongoDB: ' + reason(mongo.reason));
  if (!graphOk) console.error('Neo4j: ' + reason(graph.reason));

  const catalogEmpty = graphOk && graph.value.questoesOficiais === 0;
  if (catalogEmpty) {
    console.error('O Neo4j está disponível, mas faltam as questões com enunciado e alternativas completos. Confira o catálogo do Aura.');
  }

  if (!mongoOk || !graphOk || catalogEmpty) process.exitCode = 1;
} finally {
  await databases.close();
}
