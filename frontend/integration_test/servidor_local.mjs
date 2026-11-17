import { once } from 'node:events';
import { createApp } from '../../backend/src/app.js';
import { criarServidorTcp } from '../../backend/src/tcp-server.js';

// A suíte usa as rotas do Node com contas em memória e uma resposta simulada
// do validador. Nenhum banco nem serviço externo participa da execução.
const accounts = [];

function findAccount(filter) {
  return accounts.find(account => Object.entries(filter).every(
    ([key, value]) => String(account[key]) === String(value),
  ));
}

const databases = {
  db: { collection: () => ({ findOne: async () => null }) },
  users: {
    async findOne(filter) {
      const account = findAccount(filter);
      return account ? { ...account } : null;
    },
    async insertOne(account) {
      accounts.push(account);
    },
    async updateOne(filter, update) {
      const account = findAccount(filter);
      if (account) account.tokenVersion += update.$inc.tokenVersion;
    },
  },
};

const app = createApp({
  databases,
  config: {
    JWT_SECRET: 'chave-ficticia-exclusiva-da-integracao-ios',
    EMAIL_VERIFICATION_REQUIRED: 'false',
  },
  javaValidator: async () => ({ valido: true, mensagem: 'Validação simulada.' }),
});

const server = criarServidorTcp((request, ip) => {
  if (request?.metodo === 'GET' && request.caminho === '/health/qa') {
    return { status: 200, corpo: { modo: 'memoria', validador: 'simulado' } };
  }
  return app(request, ip);
});

try {
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  console.log(server.address().port);

  await Promise.race([
    once(process, 'SIGINT'),
    once(process, 'SIGTERM'),
  ]);
} finally {
  server.close();
}
