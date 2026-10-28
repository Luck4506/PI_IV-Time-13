import { MongoClient, ObjectId } from 'mongodb';
import { randomBytes } from 'node:crypto';
import { mkdir, writeFile, access } from 'node:fs/promises';
import { resolve } from 'node:path';
import { hashPassword } from '../src/security.js';
const file = resolve('../.local/test-accounts.json');
try { await access(file); console.log('Contas de teste já preparadas. Nenhuma senha foi alterada.'); process.exit(0); }
catch { /* First setup. */ }
const mongo = new MongoClient(process.env.MONGODB_URI, { serverSelectionTimeoutMS: 15000 });
try {
  await mongo.connect();
  const users = mongo.db(process.env.MONGODB_DATABASE ?? 'trilha').collection('usuarios');
  const accounts = [];
  for (const [perfil, nome, email] of [
    ['student', 'Estudante de teste', 'estudante.teste@trilha.example'],
    ['teacher', 'Professor de teste', 'professor.teste@trilha.example'],
  ]) {
    if (await users.findOne({ email })) throw new Error('Conta de exemplo já existe. Use o cadastro normal; nenhuma senha foi modificada.');
    const senha = randomBytes(18).toString('base64url');
    const now = new Date();
    await users.insertOne({ _id: new ObjectId(), nome, email, perfil,
      senhaHash: await hashPassword(senha), tokenVersion: 0, criadoEm: now,
      atualizadoEm: now, termosAceitosEm: now,
      ...(perfil === 'student' ? { anoEscolar: '3º ano' } : { codigoEscola: 'ESCOLA-TESTE' }),
    });
    accounts.push({ nome, email, senha, perfil });
  }
  await mkdir(resolve('../.local'), { recursive: true });
  await writeFile(file, JSON.stringify(accounts, null, 2), { mode: 0o600 });
  const markdown = '# Acessos de teste — Trilha\n\nDados fictícios. Senhas exclusivas deste ambiente de desenvolvimento.\n\nAbra http://127.0.0.1:5173 e escolha o perfil correspondente.\n\n' +
    accounts.map(x => `## ${x.perfil === 'student' ? 'Estudante' : 'Professor'}\n\nE-mail: ${x.email}\n\nSenha: ${x.senha}\n`).join('\n');
  await writeFile(resolve('../.local/ACESSOS_DE_TESTE.md'), markdown, { mode: 0o600 });
  console.log('Duas contas fictícias criadas no Atlas. Acessos salvos em .local/ACESSOS_DE_TESTE.md, fora do Git.');
} finally { await mongo.close(); }
