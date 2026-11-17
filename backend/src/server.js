import { readConfig } from './config.js';
import { createDatabases, initializeMongo } from './databases.js';
import { createApp } from './app.js';
import { criarServidorTcp } from './tcp-server.js';

let config;
let databases;

try {
  config = readConfig();
  databases = createDatabases(config);
} catch {
  console.error('Configuração incompleta. Preencha backend/.env conforme .env.example.');
  process.exit(1);
}

let ready = false;
let stopping = false;
let retry;

// A porta TCP fica disponível enquanto o Node conecta ao MongoDB.
const atender = createApp({ databases, config, databaseReady: () => ready });
const servidorTcp = criarServidorTcp(atender);

servidorTcp.on('error', erro => {
  console.error(`Não foi possível abrir a API TCP em ${config.TCP_HOST}:${config.TCP_PORT} (${erro.code}).`);
  process.exit(1);
});

servidorTcp.listen(config.TCP_PORT, config.TCP_HOST, () => {
  console.log(`API TCP do Gabariteii em ${config.TCP_HOST}:${config.TCP_PORT}; conectando aos bancos.`);
});

async function connectMongo() {
  try {
    await databases.mongo.connect();
    await initializeMongo(databases);
    ready = true;
    console.log('MongoDB conectado e inicializado. Neo4j consultado sob demanda.');
  } catch (error) {
    ready = false;
    console.error('Conexão indisponível:', error.name, error.code ?? 'verifique_acesso', '— nova tentativa em 15 segundos.');
    if (!stopping) retry = setTimeout(connectMongo, 15_000);
  }
}

connectMongo();

function stop() {
  if (stopping) return;

  stopping = true;
  clearTimeout(retry);

  // Para de aceitar conexões e deixa os pedidos em andamento terminarem.
  servidorTcp.close(async () => {
    await databases.close();
    process.exit(0);
  });

  setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', stop);
process.on('SIGINT', stop);
