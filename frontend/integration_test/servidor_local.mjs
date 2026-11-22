// Autoria de Lucas Soares Gonçalves RA 25009467
import { once } from 'node:events';
import { createServer } from 'node:net';
import { createInterface } from 'node:readline';
import { createApp } from '../../backend/src/app.js';
import { criarServidorAuthHttp } from '../../backend/src/auth/http.js';
import { criarServidorTcp } from '../../backend/src/tcp-server.js';

// As contas ficam em memória. O Java simulado recebe o JSON do iPhone e
// encaminha por HTTP para testar as mesmas entradas do Node usadas pelo app.
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
});

const server = criarServidorTcp((request, ip) => {
  if (request?.metodo === 'GET' && request.caminho === '/health/qa') {
    return { status: 200, corpo: { modo: 'memoria', validador: 'simulado' } };
  }
  return app(request, ip);
});

const http = criarServidorAuthHttp(app);
const java = createServer(socket => {
  const lines = createInterface({ input: socket });
  socket.on('error', () => lines.close());
  lines.once('line', async line => {
    try {
      const { tipo, ...dados } = JSON.parse(line);
      const cadastro = tipo === 'VALIDAR_CADASTRO';
      if (!cadastro && tipo !== 'VALIDAR_LOGIN') throw new Error('Pedido inesperado.');

      const rota = cadastro ? 'cadastro' : 'login';
      const response = await fetch(`http://127.0.0.1:${http.address().port}/api/auth/${rota}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(dados),
      });
      const body = await response.json();
      const codigoSucesso = cadastro ? 'CADASTRO_REALIZADO' : 'LOGIN_REALIZADO';
      const result = response.ok
        ? { sucesso: true, codigo: codigoSucesso, mensagem: 'Operação realizada.', dados: body }
        : { sucesso: false, codigo: 'OPERACAO_RECUSADA', mensagem: body.erro, dados: null };
      socket.end(`${JSON.stringify(result)}\n`);
    } catch {
      socket.destroy();
    } finally {
      lines.close();
    }
  });
});

try {
  for (const listener of [server, http, java]) {
    listener.listen(0, '127.0.0.1');
    await once(listener, 'listening');
  }
  console.log(`API_TCP_PORT=${server.address().port} JAVA_TCP_PORT=${java.address().port}`);

  await Promise.race([
    once(process, 'SIGINT'),
    once(process, 'SIGTERM'),
  ]);
} finally {
  for (const listener of [server, http, java]) listener.close();
}
