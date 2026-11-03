import { test } from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { createApp } from '../src/app.js';
import jwt from 'jsonwebtoken';

function fixture() {
  const rows = [];
  const graphCalls = [];
  const find = filter => rows.find(x => Object.entries(filter).every(([k,v]) => String(x[k]) === String(v)));
  const databases = {
    users: {
      async findOne(filter) { return find(filter) ?? null; },
      async insertOne(user) {
        if (rows.some(x => x.email === user.email)) throw Object.assign(new Error(), { code: 11000 });
        rows.push(user); return { insertedId: user._id };
      },
      async findOneAndUpdate(filter, update) { const user = find(filter); Object.assign(user, update.$set); return user; },
      async updateOne(filter, update) { find(filter).tokenVersion += update.$inc.tokenVersion; },
    },
    db: { async command() { return { ok: 1 }; } },
    async query(query, parameters) {
      graphCalls.push({ query, parameters });
      if (query.includes('AS gabarito')) return { records: [{ get: () => databases.answerKey ?? null }] };
      if (query.includes('q:Questao')) return { records: [{ get: () => ({ id: 'Q1', questao: 'Quanto é 2 + 2?', alternativaA: '4', gabarito: 'A', senha: 'never' }) }] };
      return { records: [] };
    },
  };
  return { databases, rows, graphCalls };
}
async function withServer(t, callback, extraConfig = {}, options = {}) {
  const data = fixture();
  const server = createApp({ ...options, databases: data.databases, config: {
    JWT_SECRET: 'test-only-secret-that-is-longer-than-thirty-two-characters',
    CORS_ORIGINS: 'http://localhost:5173', ALLOW_TEACHER_REGISTRATION: 'false', ...extraConfig,
  } }).listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = async (path, { token, cookie, headers = {}, method = 'GET', body } = {}) => {
    const response = await fetch(base + path, { method, headers: {
      'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(cookie ? { Cookie: cookie } : {}), ...headers,
    }, ...(body ? { body: JSON.stringify(body) } : {}) });
    return { status: response.status, headers: response.headers, data: response.status === 204 ? null : await response.json() };
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
  assert.equal(result.data.usuario.cadastroEducacional, true);
  assert.equal(result.data.usuario.codigoEscola, 'ESCOLA-DEMO-001');
}));
test('professor é sempre educacional, sem ampliar permissões por escolher escola', async t => withServer(t, async ({ call, rows }) => {
  const teacher = { ...registration, perfil: 'teacher', codigoEscola: 'ESCOLA-DEMO-001' };
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
  assert.equal(rows.length, 1);
  assert.equal((await call('/api/questoes?limit=10000', { token })).status, 400);
  assert.equal((await call('/api/usuarios/me', { token, method: 'PATCH', body: { perfil: 'teacher' } })).status, 400);
}));
test('prontidão informa indisponibilidade sem expor credenciais', async t => withServer(t, async ({ call, databases }) => {
  assert.equal((await call('/health/ready')).status, 200);
  databases.query = async () => { throw new Error('secret-uri'); };
  const result = await call('/health/ready');
  assert.equal(result.status, 503);
  assert.deepEqual(result.data, { status: 'indisponivel', mongodb: true, neo4j: false });
}));
test('correção usa gabarito do grafo e informa quando está ausente', async t => withServer(t, async ({ call, databases, rows }) => {
  const { data: { token } } = await call('/api/auth/cadastro', { method: 'POST', body: registration });
  const answer = body => call('/api/questoes/Q1/responder', { method: 'POST', token, body });
  assert.equal((await answer({ alternativa: 'A' })).data.corrigida, false);
  databases.answerKey = 'C';
  assert.deepEqual((await answer({ alternativa: 'C' })).data, { corrigida: true, correta: true, gabarito: 'C' });
  assert.equal((await answer({ alternativa: 'A' })).data.correta, false);
  assert.equal((await answer({ alternativa: 'F' })).status, 400);
  assert.equal(rows[0].questoes, undefined);
  assert.equal(rows.length, 1);
}));

test('cookie persistente restaura conta sem senha, protege contra CSRF e é revogado ao sair', async t => withServer(t, async ({ call, rows }) => {
  const created = await call('/api/auth/cadastro', { method: 'POST', body: registration });
  const header = created.headers.get('set-cookie');
  assert.match(header, /HttpOnly/); assert.match(header, /SameSite=Strict/);
  assert.match(header, /Max-Age=43200/); assert.match(header, /Path=\/api/);
  const cookie = header.split(';')[0];
  const restored = await call('/api/usuarios/me', { cookie });
  assert.equal(restored.status, 200);
  assert.equal(restored.data.usuario.id, created.data.usuario.id);
  assert.equal(restored.headers.get('cache-control'), 'no-store');
  assert.equal((await call('/api/usuarios/me', { cookie, method: 'PATCH', body: { nome: 'Invasor' } })).status, 403);
  const allowed = { 'Origin': 'http://localhost:5173', 'X-Trilha-Client': 'app' };
  assert.equal((await call('/api/usuarios/me', { cookie, headers: { ...allowed, Origin: 'https://evil.example' }, method: 'PATCH', body: { nome: 'Invasor' } })).status, 403);
  assert.equal((await call('/api/usuarios/me', { cookie, headers: allowed, method: 'PATCH', body: { nome: 'Nome autorizado' } })).status, 200);
  const ended = await call('/api/auth/logout', { cookie, headers: allowed, method: 'POST' });
  assert.equal(ended.status, 204); assert.match(ended.headers.get('set-cookie'), /Expires=Thu, 01 Jan 1970/);
  assert.equal((await call('/api/usuarios/me', { cookie })).status, 401);
  const reused = await call('/api/auth/login', { method: 'POST', body: { email: 'TESTE@example.com', senha: registration.senha, perfil: 'student' } });
  assert.equal(reused.status, 200); assert.equal(reused.data.usuario.id, created.data.usuario.id);
  assert.equal(rows.length, 1);
}));

test('HTTPS usa cookie Secure; token expirado, adulterado ou de conta removida não autentica', async t => withServer(t, async ({ call, rows }) => {
  const created = await call('/api/auth/cadastro', { method: 'POST', body: registration });
  assert.match(created.headers.get('set-cookie'), /Secure/);
  const expired = jwt.sign({ v: 0 }, 'test-only-secret-that-is-longer-than-thirty-two-characters', {
    subject: created.data.usuario.id, expiresIn: -1, issuer: 'trilha-api', audience: 'trilha-app', algorithm: 'HS256',
  });
  assert.equal((await call('/api/usuarios/me', { token: expired })).status, 401);
  assert.equal((await call('/api/usuarios/me', { token: created.data.token + 'tampered' })).status, 401);
  rows.length = 0;
  assert.equal((await call('/api/usuarios/me', { token: created.data.token })).status, 401);
}, { COOKIE_SECURE: 'true' }));

test('resposta de token antigo não apaga cookie de uma sessão nova', async t => withServer(t, async ({ call }) => {
  const created = await call('/api/auth/cadastro', { method: 'POST', body: registration });
  await call('/api/auth/logout', { method: 'POST', token: created.data.token });
  const current = await call('/api/auth/login', { method: 'POST', body: { email: registration.email, senha: registration.senha } });
  const cookie = current.headers.get('set-cookie').split(';')[0];
  const old = await call('/api/usuarios/me', { token: created.data.token, cookie });
  assert.equal(old.status, 401);
  assert.equal(old.headers.get('set-cookie'), null);
  assert.equal((await call('/api/usuarios/me', { cookie })).status, 200);
}));

test('API permanece acessível e bloqueia operações até os índices do banco estarem prontos', async t => {
  let ready = false;
  await withServer(t, async ({ call, rows }) => {
    assert.equal((await call('/health/live')).status, 200);
    assert.deepEqual((await call('/health/ready')).data, { status: 'indisponivel', mongodb: false, neo4j: false });
    assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: registration })).status, 503);
    assert.equal((await call('/api/usuarios/me')).status, 503);
    assert.equal(rows.length, 0);
    ready = true;
    assert.equal((await call('/health/ready')).status, 200);
    assert.equal((await call('/api/auth/cadastro', { method: 'POST', body: registration })).status, 201);
  }, {}, { databaseReady: () => ready });
});
