import { readConfig } from './config.js';
import { createDatabases, initializeMongo } from './databases.js';
import { createApp } from './app.js';

let config;
try { config = readConfig(); }
catch { console.error('Configuração incompleta. Preencha backend/.env conforme .env.example.'); process.exit(1); }
const databases = createDatabases(config);
try {
  await databases.connect();
  await initializeMongo(databases);
  const server = createApp({ databases, config }).listen(config.PORT, config.HOST, () => {
    console.log(`API Trilha em http://${config.HOST}:${config.PORT}; MongoDB e Neo4j conectados.`);
  });
  let stopping = false;
  const stop = () => {
    if (stopping) return;
    stopping = true;
    server.close(async () => { await databases.close(); process.exit(0); });
    setTimeout(() => process.exit(1), 10000).unref();
  };
  process.on('SIGTERM', stop); process.on('SIGINT', stop);
} catch (error) {
  console.error('Não foi possível conectar aos bancos:', error.name, error.code ?? 'verifique_acesso');
  await databases.close(); process.exit(1);
}
