import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { MongoClient } from 'mongodb';

const accounts = JSON.parse(await readFile('../.local/test-accounts.json', 'utf8'));
const mongo = new MongoClient(process.env.MONGODB_URI);
const db = mongo.db(process.env.MONGODB_DATABASE ?? 'trilha');
const report = { checkedAt: new Date().toISOString(), checks: {} };
async function call(path, { method = 'GET', body, cookie, token, headers = {} } = {}) {
  const response = await fetch('http://127.0.0.1:3000' + path, { method, headers: {
    'Content-Type': 'application/json', 'X-Trilha-Client': 'app',
    ...(cookie ? { Cookie: cookie } : {}), ...(token ? { Authorization: `Bearer ${token}` } : {}), ...headers,
  }, ...(body ? { body: JSON.stringify(body) } : {}) });
  return { status: response.status, headers: response.headers, data: response.status === 204 ? null : await response.json() };
}
try {
  const before = await db.collection('usuarios').countDocuments();
  for (const account of accounts) {
    const user = await db.collection('usuarios').findOne({ email: account.email });
    const trails = await db.collection('trilhas').countDocuments({ usuarioId: user._id });
    const login = await call('/api/auth/login', { method: 'POST', body: { email: account.email, senha: account.senha, perfil: account.perfil } });
    assert.equal(login.status, 200); assert.equal(login.data.usuario.id, user._id.toString());
    const cookieHeader = login.headers.get('set-cookie');
    assert.match(cookieHeader, /HttpOnly/); assert.match(cookieHeader, /SameSite=Strict/); assert.match(cookieHeader, /Max-Age=43200/);
    const cookie = cookieHeader.split(';')[0];
    const restored = await call('/api/usuarios/me', { cookie });
    assert.equal(restored.status, 200); assert.equal(restored.data.usuario.id, user._id.toString());
    assert.equal(restored.data.usuario.senhaHash, undefined);
    assert.equal((await call('/api/usuarios/me', { cookie, method: 'PATCH', body: { perfil: account.perfil === 'student' ? 'teacher' : 'student' } })).status, 400);
    assert.equal((await call('/api/auth/login', { method: 'POST', body: { email: account.email, senha: account.senha, perfil: account.perfil === 'student' ? 'teacher' : 'student' } })).status, 401);
    assert.equal((await call('/api/usuarios/me', { cookie, method: 'PATCH', body: { nome: 'Nome indevido' }, headers: { Origin: 'https://evil.example' } })).status, 403);
    if (account.perfil === 'teacher') {
      assert.equal((await call('/api/auth/logout', { cookie, method: 'POST' })).status, 204);
      assert.equal((await call('/api/usuarios/me', { cookie })).status, 401);
      assert.equal((await call('/api/usuarios/me', { token: login.data.token })).status, 401);
      const relogin = await call('/api/auth/login', { method: 'POST', body: { email: account.email, senha: account.senha, perfil: account.perfil } });
      assert.equal(relogin.data.usuario.id, user._id.toString());
    }
    assert.equal(await db.collection('trilhas').countDocuments({ usuarioId: user._id }), trails);
  }
  assert.equal((await call('/api/usuarios/me')).status, 401);
  assert.equal((await call('/api/trilhas')).status, 401);
  assert.equal(await db.collection('usuarios').countDocuments(), before);
  report.status = 'ok';
  report.checks = { existingAccountsReused: true, cookieRestoresIdentity: true, httpOnlyCookie: true,
    wrongRoleRejected: true, profileCannotEscalate: true, csrfRejected: true, logoutRevokesCookieAndToken: true,
    loggedOutCanSignInAgain: true, privateRoutesRequireSession: true, accountsAndTrailsPreserved: true };
  await writeFile('../.local/VERIFICACAO_AUTENTICACAO.json', JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
} finally { await mongo.close(); }
