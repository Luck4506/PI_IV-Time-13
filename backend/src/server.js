import { readConfig } from './config.js';
import { createDatabases, initializeMongo } from './databases.js';
import { createApp } from './app.js';

let config;
try { config = readConfig(); }
catch { console.error('Configuração incompleta. Preencha backend/.env conforme .env.example.'); process.exit(1); }
const databases = createDatabases(config);
let ready = false, stopping = false, retry;

// Keep the local API available to explain a connection failure. Data routes
// remain closed until MongoDB validation and indexes are initialized.
const server = createApp({ databases, config, databaseReady: () => ready }).listen(config.PORT, config.HOST, () => {
  console.log(`API Trilha em http://${config.HOST}:${config.PORT}; conectando aos bancos.`);
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
    if (!stopping) retry = setTimeout(connectMongo, 15000);
  }
}
connectMongo();

const stop = () => {
  if (stopping) return;
  stopping = true;
  clearTimeout(retry);
  server.close(async () => { await databases.close(); process.exit(0); });
  setTimeout(() => process.exit(1), 10000).unref();
};
process.on('SIGTERM', stop); process.on('SIGINT', stop);
