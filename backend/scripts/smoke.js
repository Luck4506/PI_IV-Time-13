import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';
import { MongoClient } from 'mongodb';
const base = 'http://127.0.0.1:3000';
const mongo = new MongoClient(process.env.MONGODB_URI);
const users = mongo.db(process.env.MONGODB_DATABASE).collection('usuarios');
let temporaryId;
const report = { checkedAt: new Date().toISOString(), checks: {} };
async function call(path, method = 'GET', body, token) {
  const response = await fetch(base + path, { method, headers: {
    'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}),
  }, ...(body ? { body: JSON.stringify(body) } : {}) });
  return { status: response.status, body: response.status === 204 ? null : await response.json() };
}
try {
  assert.equal((await call('/health/ready')).status, 200);
  report.checks.databasesReady = true;
  const cadastro = { nome: 'Teste temporário de integração', email: `integracao-${randomBytes(6).toString('hex')}@trilha.example`,
    senha: randomBytes(20).toString('base64url'), perfil: 'student', anoEscolar: '3º ano', termosAceitos: true };
  const created = await call('/api/auth/cadastro', 'POST', cadastro);
  assert.equal(created.status, 201);
  const stored = await users.findOne({ email: cadastro.email });
  temporaryId = stored._id;
  assert.match(stored.senhaHash, /^scrypt\$/);
  assert.equal(stored.senha, undefined);
  assert.equal(created.body.usuario.senhaHash, undefined);
  report.checks.registrationPersistedWithHashedPassword = true;
  assert.equal((await call('/api/auth/cadastro', 'POST', cadastro)).status, 409);
  report.checks.duplicateEmailRejected = true;
  const logged = await call('/api/auth/login', 'POST', { email: cadastro.email, senha: cadastro.senha, perfil: 'student' });
  assert.equal(logged.status, 200);
  const token = logged.body.token;
  const me = await call('/api/usuarios/me', 'GET', undefined, token);
  assert.equal(me.body.usuario.id, created.body.usuario.id);
  report.checks.loginAndProfile = true;
  const questions = await call('/api/questoes?limit=100', 'GET', undefined, token);
  assert.equal(questions.status, 200);
  assert.equal(questions.body.questoes.length, 45);
  const disciplines = await call('/api/disciplinas', 'GET', undefined, token);
  assert.equal(disciplines.body.disciplinas.length, 3);
  report.checks.graphQuestions = questions.body.questoes.length;
  report.checks.graphDisciplines = disciplines.body.disciplinas.length;
  const first = questions.body.questoes[0];
  assert.equal(first.gabarito, undefined);
  const answer = await call(`/api/questoes/${encodeURIComponent(first.id)}/responder`, 'POST', { alternativa: 'A' }, token);
  assert.equal(answer.status, 200);
  report.checks.answerEndpoint = true;
  report.checks.firstQuestionHasAnswerKey = answer.body.corrigida;
  assert.equal((await call('/api/auth/logout', 'POST', undefined, token)).status, 204);
  assert.equal((await call('/api/usuarios/me', 'GET', undefined, token)).status, 401);
  report.checks.logoutRevokesSession = true;
  const accounts = JSON.parse(await readFile('../.local/test-accounts.json', 'utf8'));
  for (const account of accounts) {
    assert.equal((await call('/api/auth/login', 'POST', { email: account.email, senha: account.senha, perfil: account.perfil })).status, 200);
  }
  report.checks.bothExampleProfiles = true;
  const collections = await mongo.db(process.env.MONGODB_DATABASE).listCollections({}, { nameOnly: true }).toArray();
  assert.deepEqual(collections.map(x => x.name).filter(x => !x.startsWith('system.')), ['usuarios']);
  report.checks.mongoContainsOnlyUsersCollection = true;
  report.status = 'ok';
} finally {
  if (temporaryId) await users.deleteOne({ _id: temporaryId });
  await mongo.close();
  await writeFile('../.local/VERIFICACAO.json', JSON.stringify(report, null, 2));
}
console.log(JSON.stringify(report, null, 2));
