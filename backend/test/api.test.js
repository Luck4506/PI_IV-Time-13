import { test } from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { Duplex } from 'node:stream';
import { atenderConexao } from '../src/tcp-server.js';
import { createApp } from '../src/app.js';
import { ensureCollection } from '../src/mongo-collections.js';
import jwt from 'jsonwebtoken';

function fixture() {
  const rows = [];
  const graphCalls = [];
  const verificationRows = [];
  const matches = (row, filter) => Object.entries(filter).every(([key, value]) => {
    if (value?.$exists !== undefined) return (row[key] !== undefined) === value.$exists;
    if (value?.$gt !== undefined) return row[key] > value.$gt;
    if (value?.$lte !== undefined) return row[key] <= value.$lte;
    return String(row[key]) === String(value);
  });
  const find = filter => rows.find(row => matches(row, filter));
  const verifications = {
    async insertOne(row) { verificationRows.push(row); },
    async findOne(filter) { return verificationRows.find(row => matches(row, filter)) ?? null; },
    async findOneAndUpdate(filter, update) {
      const row = verificationRows.find(row => matches(row, filter));
      return row ? Object.assign(row, update.$set) : null;
    },
    async updateOne(filter, update) {
      const row = verificationRows.find(row => matches(row, filter));
      if (!row) return { modifiedCount: 0 };
      Object.assign(row, update.$set);
      for (const field of Object.keys(update.$unset)) delete row[field];
      return { modifiedCount: 1 };
    },
  };
  const databases = {
    mongo: {
      async withSession(callback) {
        return callback({ withTransaction: task => task() });
      },
    },
    users: {
      async findOne(filter) {
        const user = find(filter);
        return user ? { ...user } : null;
      },
      async insertOne(user) {
        if (rows.some(x => x.email === user.email)) throw Object.assign(new Error(), { code: 11000 });
        rows.push(user); return { insertedId: user._id };
      },
      async findOneAndUpdate(filter, update) {
        const user = find(filter);
        return user ? Object.assign(user, update.$set) : null;
      },
      async updateOne(filter, update) {
        const user = find(filter);
        if (user) user.tokenVersion += update.$inc.tokenVersion;
      },
    },
    db: {
      async command() { return { ok: 1 }; },
      collection(name) {
        if (name === 'verificacoes_email') return verifications;
        if (name !== 'escolas') return {};
        return {
          find() {
            return {
              sort: () => ({
                toArray: async () => [
                  { _id: 'ESCOLA-ATIVA', nome: 'Escola Ativa' },
                  { _id: 'ESCOLA-DEMO-001', nome: 'Escola de Demonstração', demonstracao: true },
                ],
              }),
            };
          },
          async findOne({ _id, ativa }) {
            return _id === 'ESCOLA-DEMO-001' && ativa === true ? { _id, ativa } : null;
          },
        };
      },
    },
    async query(query, parameters) {
      graphCalls.push({ query, parameters });
      if (query.includes('AS catalogoOficial')) return { records: [{ get: () => databases.examCount ?? 1 }] };
      if (query.includes('q:Questao')) {
        const question = {
          id: 'Q1',
          questao: 'Quanto é 2 + 2?',
          alternativaA: '4',
          alternativaB: '2',
          alternativaC: '3',
          alternativaD: '5',
          gabarito: parameters.id ? databases.answerKey : 'A',
          gabarito_declarado: databases.legacyAnswerKey,
          senha: 'never',
        };
        return { records: [{ get: () => question }] };
      }
      return { records: [] };
    },
  };
  return { databases, rows, graphCalls, verificationRows };
}
async function enviarEmMemoria(atender, partes) {
  const resposta = [];
  const socket = new Duplex({
    read() {},
    write(parte, _encoding, concluir) {
      resposta.push(parte);
      concluir();
    },
  });
  socket.remoteAddress = '127.0.0.1';

  atenderConexao(socket, atender);
  const fim = once(socket, 'finish');
  for (const parte of partes) socket.push(parte);
  socket.push(null);
  await fim;

  return JSON.parse(Buffer.concat(resposta).toString('utf8'));
}

async function withServer(_t, callback, extraConfig = {}, options = {}) {
  const data = fixture();
  const atender = createApp({
    databases: data.databases,
    config: {
      JWT_SECRET: 'test-only-secret-that-is-longer-than-thirty-two-characters',
      ALLOW_TEACHER_REGISTRATION: 'false',
      ...extraConfig,
    },
    javaValidator: async () => ({ valido: true, mensagem: 'Campos válidos.' }),
    ...options,
  });
  const call = async (path, { token, method = 'GET', body } = {}) => {
    const linha = JSON.stringify({ metodo: method, caminho: path, token, dados: body }) + '\n';
    const { status, corpo } = await enviarEmMemoria(atender, [Buffer.from(linha)]);
    return { status, data: corpo };
  };
  await callback({ ...data, call });
}

const registration = { nome: 'Estudante Teste', email: 'TESTE@example.com', senha: 'SenhaTeste123!',
  perfil: 'student', anoEscolar: '3º ano', termosAceitos: true };

test('cadastro, login, perfil e logout revogam a sessão e protegem senha', async t => withServer(t, async ({ call, rows }) => {
  const register = await call('/api/auth/cadastro', { method: 'POST', body: registration });
  assert.equal(register.status, 201);
  assert.equal(rows[0].email, 'teste@example.com');
  assert.match(rows[0].senhaHash, /^scrypt\$/);
  assert.equal(rows[0].senha, undefined);
  assert.equal(register.data.usuario.senhaHash, undefined);
  assert.equal((await call('/api/auth/login', { method: 'POST', body: { email: 'teste@example.com', senha: 'errada123' } })).status, 401);
  const login = await call('/api/auth/login', { method: 'POST', body: { email: 'teste@example.com', senha: registration.senha, perfil: 'student' } });
  assert.equal(login.status, 200);
  const token = login.data.token;
  assert.equal((await call('/api/usuarios/me', { token })).data.usuario.nome, registration.nome);
  assert.equal((await call('/api/usuarios/me', { method: 'PATCH', token, body: { nome: 'Novo Nome' } })).data.usuario.nome, 'Novo Nome');
  assert.equal((await call('/api/auth/logout', { method: 'POST', token })).status, 204);
  assert.equal((await call('/api/usuarios/me', { token })).status, 401);
}));

test('saídas simultâneas com o mesmo token revogam a versão uma única vez', async t => withServer(t, async ({ call, rows, databases }) => {
  const created = await call('/api/auth/cadastro', { method: 'POST', body: registration });
  const { token } = created.data;
  const updateOne = databases.users.updateOne;
  const gate = Promise.withResolvers();
  let requests = 0;

  databases.users.updateOne = async (filter, update) => {
    if (++requests === 2) gate.resolve();
    await gate.promise;
    return updateOne(filter, update);
  };

  const logout = () => call('/api/auth/logout', { method: 'POST', token });
  const responses = await Promise.all([logout(), logout()]);
  assert.deepEqual(responses.map(response => response.status), [204, 204]);
  assert.equal(rows[0].tokenVersion, 1);
  assert.equal((await call('/api/usuarios/me', { token })).status, 401);
}));

test('e-mail único normalizado e campos extras bloqueados', async t => withServer(t, async ({ call }) => {
  assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: registration })).status, 201);
  assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: { ...registration, email: 'teste@example.com' } })).status, 409);
  assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: { ...registration, questoes: ['Q1'] } })).status, 400);
  assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: { ...registration, email: { $ne: null } } })).status, 400);
}));
test('valida termos, ano escolar e autorização para professor', async t => withServer(t, async ({ call, rows }) => {
  for (const body of [{ ...registration, termosAceitos: false }, { ...registration, anoEscolar: undefined }]) {
    assert.equal((await call('/api/auth/cadastro', { method: 'POST', body })).status, 400);
  }
  assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: { ...registration, perfil: 'teacher' } })).status, 403);
  assert.equal(rows.length, 0);
}));
test('cadastro rejeita séries fora da lista e preserva o acesso de conta antiga', async t =>
  withServer(t, async ({ call, rows }) => {
    for (const anoEscolar of ['6º ano do Ensino Fundamental', 0]) {
      const rejected = await call('/api/auth/cadastro', {
        method: 'POST', body: { ...registration, anoEscolar },
      });
      assert.equal(rejected.status, 400);
    }

    const created = await call('/api/auth/cadastro', { method: 'POST', body: registration });
    assert.equal(created.status, 201);
    rows[0].anoEscolar = '6º ano do Ensino Fundamental';
    const login = await call('/api/auth/login', { method: 'POST', body: {
      email: registration.email, senha: registration.senha,
    } });
    assert.equal(login.status, 200);
    assert.equal(login.data.usuario.anoEscolar, '6º ano do Ensino Fundamental');
  }));

test('cadastro educacional salva a escola declarada e exige seleção quando ativo', async t => withServer(t, async ({ call, rows }) => {
  const educational = { ...registration, cadastroEducacional: true };
  assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: educational })).status, 400);
  assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: {
    ...educational, codigoEscola: '   ',
  } })).status, 400);
  assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: {
    ...educational, cadastroEducacional: false, codigoEscola: 'ESCOLA-DEMO-001',
  } })).status, 400);
  const result = await call('/api/auth/cadastro', { method: 'POST', body: {
    ...educational, codigoEscola: 'ESCOLA-DEMO-001',
  } });
  assert.equal(result.status, 201);
  assert.equal(rows[0].codigoEscola, 'ESCOLA-DEMO-001');
  for (const codigoEscola of ['ESCOLA-INEXISTENTE', 'ESCOLA-INATIVA']) {
    const invalid = await call('/api/auth/cadastro', { method: 'POST', body: {
      ...educational, codigoEscola, email: 'outro@example.com',
    } });
    assert.equal(invalid.status, 400);
  }
  assert.equal(rows.length, 1);
  assert.equal(result.data.usuario.cadastroEducacional, true);
  assert.equal(result.data.usuario.codigoEscola, 'ESCOLA-DEMO-001');
}));

test('listagem diferencia escolas da demonstração para o cadastro final', async t => withServer(t, async ({ call }) => {
  const response = await call('/api/escolas');
  assert.equal(response.status, 200);
  assert.deepEqual(response.data.escolas, [
    { codigo: 'ESCOLA-ATIVA', nome: 'Escola Ativa' },
    { codigo: 'ESCOLA-DEMO-001', nome: 'Escola de Demonstração', demonstracao: true },
  ]);
}));
test('professor é sempre educacional, sem ampliar permissões por escolher escola', async t => withServer(t, async ({ call, rows }) => {
  const teacher = { ...registration, perfil: 'teacher', codigoEscola: 'ESCOLA-DEMO-001' };
  assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: {
    ...teacher, codigoEscola: undefined,
  } })).status, 400);
  assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: {
    ...teacher, cadastroEducacional: false,
  } })).status, 400);
  const result = await call('/api/auth/cadastro', { method: 'POST', body: {
    ...teacher, cadastroEducacional: true,
  } });
  assert.equal(result.status, 201);
  assert.equal(result.data.usuario.cadastroEducacional, true);
  assert.equal(result.data.usuario.perfil, 'teacher');
}, { ALLOW_TEACHER_REGISTRATION: 'true' }));
test('questões vêm do grafo, exigem sessão, omitem gabarito e validam paginação', async t => withServer(t, async ({ call, rows, graphCalls }) => {
  assert.equal((await call('/api/questoes')).status, 401);
  assert.equal((await call('/api/questoes', { token: 'invalid' })).status, 401);
  const { data: { token } } = await call('/api/auth/cadastro', { method: 'POST', body: registration });
  const result = await call('/api/questoes?limit=10&offset=0', { token });
  assert.equal(result.status, 200);
  assert.equal(result.data.questoes[0].questao, 'Quanto é 2 + 2?');
  assert.equal(result.data.questoes[0].gabarito, undefined);
  assert.equal(result.data.questoes[0].senha, undefined);
  assert.equal(graphCalls.length, 1);
  assert.equal(graphCalls[0].parameters.examOrigin, 'vestibular');
  assert.match(graphCalls[0].query, /q\.gabaritoUrl/);
  assert.equal(rows.length, 1);
  assert.equal((await call('/api/questoes?limit=10000', { token })).status, 400);
  assert.equal((await call('/api/usuarios/me', { token, method: 'PATCH', body: { perfil: 'teacher' } })).status, 400);
}));
test('prontidão informa indisponibilidade sem expor credenciais', async t => withServer(t, async ({ call, databases }) => {
  assert.equal((await call('/health/ready')).status, 200);
  databases.query = async () => { throw new Error('secret-uri'); };
  const result = await call('/health/ready');
  assert.equal(result.status, 503);
  assert.deepEqual(result.data, { status: 'indisponivel', mongodb: true, neo4j: false, catalogo: false });
}));
test('correção usa gabarito do grafo e informa quando está ausente', async t => withServer(t, async ({ call, databases, rows }) => {
  const { data: { token } } = await call('/api/auth/cadastro', { method: 'POST', body: registration });
  const answer = body => call('/api/questoes/Q1/responder', { method: 'POST', token, body });
  assert.equal((await answer({ alternativa: 'A' })).data.corrigida, false);
  databases.answerKey = 'C';
  assert.deepEqual((await answer({ alternativa: 'C' })).data, { corrigida: true, correta: true, gabarito: 'C' });
  assert.equal((await answer({ alternativa: 'A' })).data.correta, false);
  assert.equal((await answer({ alternativa: 'E' })).status, 400);
  assert.equal((await answer({ alternativa: 'F' })).status, 400);

  databases.answerKey = 'E'; // A alternativa E não existe nesta questão.
  assert.equal((await answer({ alternativa: 'A' })).data.corrigida, false);

  databases.answerKey = undefined;
  databases.legacyAnswerKey = 'A';
  assert.deepEqual((await answer({ alternativa: 'A' })).data, {
    corrigida: true, correta: true, gabarito: 'A',
  });
  assert.equal(rows[0].questoes, undefined);
  assert.equal(rows.length, 1);
}));

test('token expirado, adulterado ou de conta removida não autentica', async t => withServer(t, async ({ call, rows }) => {
  const created = await call('/api/auth/cadastro', { method: 'POST', body: registration });
  const expired = jwt.sign({ v: 0 }, 'test-only-secret-that-is-longer-than-thirty-two-characters', {
    subject: created.data.usuario.id, expiresIn: -1, issuer: 'trilha-api', audience: 'trilha-app', algorithm: 'HS256',
  });
  assert.equal((await call('/api/usuarios/me', { token: expired })).status, 401);
  assert.equal((await call('/api/usuarios/me', { token: created.data.token + 'tampered' })).status, 401);
  rows.length = 0;
  assert.equal((await call('/api/usuarios/me', { token: created.data.token })).status, 401);
}));

test('API permanece acessível e bloqueia operações até os índices do banco estarem prontos', async t => {
  let ready = false;
  await withServer(t, async ({ call, rows }) => {
    assert.equal((await call('/health/live')).status, 200);
    assert.deepEqual((await call('/health/ready')).data, { status: 'indisponivel', mongodb: false, neo4j: false, catalogo: false });
    assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: registration })).status, 503);
    assert.equal((await call('/api/usuarios/me')).status, 503);
    assert.equal((await call('/api/usuarios/me', { body: [] })).status, 400);
    assert.equal(rows.length, 0);
    ready = true;
    assert.equal((await call('/health/ready')).status, 200);
    assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: registration })).status, 201);
  }, {}, { databaseReady: () => ready });
});

test('prontidão diferencia grafo conectado de catálogo oficial vazio', async t => withServer(t, async ({ call, databases }) => {
  databases.examCount = 0;
  const health = await call('/health/ready');
  assert.equal(health.status, 503);
  assert.deepEqual(health.data, { status: 'indisponivel', mongodb: true, neo4j: true, catalogo: false });
}));

test('cadastro obrigatório fica indisponível quando não há remetente configurado', async t =>
  withServer(t, async ({ call, rows }) => {
    const result = await call('/api/auth/cadastro', { method: 'POST', body: registration });
    assert.equal(result.status, 503);
    assert.equal(rows.length, 0);
  }, { EMAIL_VERIFICATION_REQUIRED: 'true' }));

test('cadastro pendente bloqueia sessão e confirma somente com o código e a senha', async t => {
  const messages = [];
  await withServer(t, async ({ call, verificationRows }) => {
    const created = await call('/api/auth/cadastro', { method: 'POST', body: registration });
    assert.equal(created.status, 201);
    assert.deepEqual(created.data, { verificacaoPendente: true, emailEnviado: true });
    assert.equal(messages.length, 1);
    const [{ email, token }] = messages;
    assert.equal(email, 'teste@example.com');
    assert.match(verificationRows[0].tokenHash, /^[a-f0-9]{64}$/);
    assert(!JSON.stringify(verificationRows).includes(token));

    const login = (senha = registration.senha) => call('/api/auth/login', {
      method: 'POST', body: { email, senha },
    });
    assert.equal((await login()).data.codigo, 'EMAIL_NAO_CONFIRMADO');
    assert.equal((await login('senha-errada')).status, 401);
    const confirm = (senha = registration.senha) => call('/api/auth/confirmar-email', {
      method: 'POST', body: { codigo: token, senha },
    });

    assert.equal((await confirm('senha-errada')).status, 400);
    const results = await Promise.all([confirm(), confirm()]);
    assert.deepEqual(results.map(result => result.status).sort(), [200, 400]);
    assert.equal(verificationRows[0].tokenHash, undefined);
    assert(verificationRows[0].confirmadoEm instanceof Date);
    assert.equal((await login()).status, 200);
  }, { EMAIL_VERIFICATION_REQUIRED: 'true' }, {
    emailOptions: { sendMail: async (email, token) => messages.push({ email, token }) },
  });
});

test('reenvio após o intervalo substitui o código, inclusive após falha de entrega', async t => {
  const tokens = [];
  let time = Date.now();

  await withServer(t, async ({ call }) => {
    const { email, senha } = registration;
    const created = await call('/api/auth/cadastro', { method: 'POST', body: registration });
    assert.deepEqual(created.data, { verificacaoPendente: true, emailEnviado: false });

    const resend = (address = email) => call('/api/auth/reenviar-confirmacao', {
      method: 'POST', body: { email: address, senha },
    });
    const tooSoon = await resend();
    assert.equal(tooSoon.status, 202);
    assert.equal(tokens.length, 1);
    assert.deepEqual((await resend('desconhecido@example.com')).data, tooSoon.data);

    time += 60_000;
    await Promise.all([resend(), resend()]);
    assert.equal(tokens.length, 2);

    const confirm = token => call('/api/auth/confirmar-email', {
      method: 'POST', body: { codigo: token, senha },
    });
    assert.equal((await confirm(tokens[0])).status, 400);
    time += 30 * 60_000;
    assert.equal((await confirm(tokens[1])).status, 400);

    await resend();
    assert.equal(tokens.length, 3);
    assert.equal((await confirm(tokens[2])).status, 200);
  }, { EMAIL_VERIFICATION_REQUIRED: 'true' }, {
    emailOptions: {
      now: () => time,
      sendMail: async (_email, token) => {
        tokens.push(token);
        if (tokens.length === 1) throw new Error('SMTP indisponível');
      },
    },
  });
});

test('TCP reúne partes do JSON UTF-8 e recusa pedidos inválidos', async () => {
  const atender = async pedido => ({ status: 200, corpo: pedido });
  const linha = Buffer.from(JSON.stringify({ nome: 'João' }) + '\n');
  const indice = linha.indexOf(0xc3) + 1;
  assert.deepEqual(await enviarEmMemoria(atender, [linha.subarray(0, indice), linha.subarray(indice)]), {
    status: 200, corpo: { nome: 'João' },
  });
  assert.equal((await enviarEmMemoria(atender, [Buffer.from('incompleto{\n')])).status, 400);
  assert.equal((await enviarEmMemoria(atender, [Buffer.from([0xff, 10])])).status, 400);
  assert.equal((await enviarEmMemoria(atender, [Buffer.alloc(65537, 97)])).status, 413);
  assert.equal((await enviarEmMemoria(atender, [Buffer.from('{"nome":"João"}')])).status, 400);
});

test('a API rejeita dados TCP que não sejam um objeto, mesmo em rotas sem corpo', async t => {
  await withServer(t, async ({ call }) => {
    for (const body of [null, [], 'texto', true]) {
      const resposta = await call('/health/live', { body });
      assert.equal(resposta.status, 400);
    }
    assert.equal((await call('/health/live')).status, 200);
  });
});

test('inicialização aceita uma coleção criada por outra instância', async () => {
  let existing = null;
  const db = {
    listCollections: () => ({ next: async () => existing }),
    async createCollection(name) {
      existing = { name, options: {} };
      throw Object.assign(new Error('NamespaceExists'), { code: 48 });
    },
  };

  assert.deepEqual(await ensureCollection(db, 'usuarios'), { name: 'usuarios', options: {} });
});

test('Node envia perfil e ano escolar como números e delega somente cadastro e login ao Java', async t => {
  const pedidos = [];
  await withServer(t, async ({ call, rows }) => {
    const opcoes = [
      { escolha: '1º ano', codigo: 1, salvo: '1º ano do Ensino Médio' },
      { escolha: '2º ano', codigo: 2, salvo: '2º ano do Ensino Médio' },
      { escolha: '3º ano', codigo: 3, salvo: '3º ano do Ensino Médio' },
      { escolha: 'Outro', codigo: 0, salvo: 'Outro' },
    ];
    for (const { escolha, codigo, salvo } of opcoes) {
      const email = `ano${codigo}@example.com`;
      assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: {
        ...registration, email, anoEscolar: escolha, dataNascimento: '2009-08-15',
      } })).status, 201);
      assert.equal(pedidos.at(-1).tipo, 'VALIDAR_CADASTRO');
      assert.equal(pedidos.at(-1).perfil, 1);
      assert.equal(pedidos.at(-1).anoEscolar, codigo);
      assert.equal(rows.at(-1).perfil, 'student');
      assert.equal(rows.at(-1).anoEscolar, salvo);
    }

    const professor = await call('/api/auth/cadastro', { method: 'POST', body: {
      nome: 'Professor Teste', email: 'professor@example.com', senha: registration.senha,
      perfil: 'teacher', dataNascimento: '3000-01-01', codProfessor: '0123',
      codigoEscola: 'ESCOLA-DEMO-001', termosAceitos: true,
    } });
    assert.equal(professor.status, 201);
    assert.deepEqual(pedidos.at(-1), {
      tipo: 'VALIDAR_CADASTRO', nome: 'Professor Teste', email: 'professor@example.com',
      senha: registration.senha, dataNascimento: '3000-01-01', perfil: 2, codProfessor: '0123',
    });
    assert.equal(rows.at(-1).perfil, 'teacher');

    const login = await call('/api/auth/login', { method: 'POST', body: {
      email: rows[0].email, senha: registration.senha,
    } });
    assert.equal(login.status, 200);
    assert.deepEqual(pedidos.at(-1), {
      tipo: 'VALIDAR_LOGIN', email: rows[0].email, senha: registration.senha,
    });
    assert.equal((await call('/api/questoes', { token: login.data.token })).status, 200);
    assert.equal(pedidos.length, 6);
  }, { ALLOW_TEACHER_REGISTRATION: 'true' }, { javaValidator: async pedido => {
    pedidos.push(pedido);
    return { valido: true };
  } });
});
