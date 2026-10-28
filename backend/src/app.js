import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import jwt from 'jsonwebtoken';
import { ObjectId } from 'mongodb';
import neo4j from 'neo4j-driver';
import { z } from 'zod';
import { hashPassword, verifyPassword } from './security.js';

const email = z.string().trim().toLowerCase().email().max(254);
const password = z.string().min(8).max(128);
const registration = z.object({
  nome: z.string().trim().min(2).max(120), email, senha: password,
  perfil: z.enum(['student', 'teacher']),
  anoEscolar: z.string().trim().min(1).max(60).optional(),
  codigoEscola: z.string().trim().max(80).optional(), termosAceitos: z.literal(true),
}).strict().refine(x => x.perfil !== 'student' || !!x.anoEscolar, {
  message: 'Informe o ano escolar.', path: ['anoEscolar'],
});
const login = z.object({ email, senha: password, perfil: z.enum(['student', 'teacher']).optional() }).strict();
const profile = z.object({
  nome: z.string().trim().min(2).max(120).optional(),
  anoEscolar: z.string().trim().min(1).max(60).optional(),
  codigoEscola: z.string().trim().max(80).optional(),
}).strict().refine(x => Object.keys(x).length > 0, 'Informe um campo para atualizar.');
const pageSchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).max(100000).default(0),
});
const publicUser = user => ({
  id: user._id.toString(), nome: user.nome, email: user.email, perfil: user.perfil,
  ...(user.anoEscolar ? { anoEscolar: user.anoEscolar } : {}),
  ...(user.codigoEscola ? { codigoEscola: user.codigoEscola } : {}),
  criadoEm: user.criadoEm,
});
function serialize(value) {
  if (neo4j.isInt(value)) return value.inSafeRange() ? value.toNumber() : value.toString();
  if (Array.isArray(value)) return value.map(serialize);
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k,v]) => [k, serialize(v)]));
  return value;
}
// Only approved question fields leave the graph; answer keys are never returned here.
export function questionView(properties) {
  const allowed = ['id', 'nome', 'questao', 'enunciado', 'ano', 'banca', 'numero',
    'alternativaA', 'alternativaB', 'alternativaC', 'alternativaD', 'alternativaE',
    'topicosRelacionados', 'imagens', 'disciplina'];
  return serialize(Object.fromEntries(allowed.filter(k => properties[k] !== undefined).map(k => [k, properties[k]])));
}

export function createApp({ databases, config }) {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors({ origin: config.CORS_ORIGINS.split(',').map(x => x.trim()) }));
  app.use(express.json({ limit: '32kb' }));
  const authLimit = rateLimit({ windowMs: 15 * 60 * 1000, limit: 30,
    standardHeaders: 'draft-8', legacyHeaders: false,
    message: { erro: 'Muitas tentativas. Aguarde alguns minutos.' } });
  const issueToken = user => jwt.sign({ v: user.tokenVersion }, config.JWT_SECRET, {
    subject: user._id.toString(), expiresIn: '12h', algorithm: 'HS256',
    issuer: 'trilha-api', audience: 'trilha-app',
  });
  const auth = async (req, res, next) => {
    const token = req.headers.authorization?.match(/^Bearer (\S+)$/)?.[1];
    if (!token) return res.status(401).json({ erro: 'Entre na sua conta para continuar.' });
    let payload;
    try {
      payload = jwt.verify(token, config.JWT_SECRET, { algorithms: ['HS256'], issuer: 'trilha-api', audience: 'trilha-app' });
      if (!ObjectId.isValid(payload.sub)) throw new Error('invalid subject');
    } catch { return res.status(401).json({ erro: 'Sessão inválida ou expirada. Entre novamente.' }); }
    try {
      const user = await databases.users.findOne({ _id: new ObjectId(payload.sub) });
      if (!user || user.tokenVersion !== payload.v) return res.status(401).json({ erro: 'Sessão encerrada. Entre novamente.' });
      req.user = user;
      next();
    } catch (error) { next(error); }
  };

  app.get('/health/live', (_req, res) => res.json({ status: 'ok' }));
  app.get('/health/ready', async (_req, res) => {
    const checks = await Promise.allSettled([
      databases.db.command({ ping: 1 }), databases.query('RETURN 1 AS ok'),
    ]);
    const ok = checks.every(x => x.status === 'fulfilled');
    res.status(ok ? 200 : 503).json({ status: ok ? 'ok' : 'indisponivel',
      mongodb: checks[0].status === 'fulfilled', neo4j: checks[1].status === 'fulfilled' });
  });

  app.post('/api/auth/cadastro', authLimit, async (req, res) => {
    const data = registration.parse(req.body);
    if (data.perfil === 'teacher' && config.ALLOW_TEACHER_REGISTRATION !== 'true') {
      return res.status(403).json({ erro: 'Cadastro de professor depende de autorização da escola.' });
    }
    const now = new Date();
    const user = { _id: new ObjectId(), nome: data.nome, email: data.email, perfil: data.perfil,
      senhaHash: await hashPassword(data.senha), termosAceitosEm: now,
      criadoEm: now, atualizadoEm: now, tokenVersion: 0,
      ...(data.perfil === 'student' ? { anoEscolar: data.anoEscolar } : {}),
      ...(data.perfil === 'teacher' && data.codigoEscola ? { codigoEscola: data.codigoEscola } : {}),
    };
    await databases.users.insertOne(user);
    res.status(201).json({ token: issueToken(user), usuario: publicUser(user) });
  });
  app.post('/api/auth/login', authLimit, async (req, res) => {
    const data = login.parse(req.body);
    const user = await databases.users.findOne({ email: data.email });
    const valid = await verifyPassword(data.senha, user?.senhaHash ?? dummyHash);
    if (!user || !valid || (data.perfil && user.perfil !== data.perfil)) {
      return res.status(401).json({ erro: 'E-mail, senha ou perfil incorretos.' });
    }
    res.json({ token: issueToken(user), usuario: publicUser(user) });
  });
  app.get('/api/usuarios/me', auth, (req, res) => res.json({ usuario: publicUser(req.user) }));
  app.patch('/api/usuarios/me', auth, async (req, res) => {
    const data = profile.parse(req.body);
    if ((req.user.perfil === 'student' && data.codigoEscola !== undefined) ||
        (req.user.perfil === 'teacher' && data.anoEscolar !== undefined)) {
      return res.status(400).json({ erro: 'Campo incompatível com o perfil.' });
    }
    const user = await databases.users.findOneAndUpdate({ _id: req.user._id },
      { $set: { ...data, atualizadoEm: new Date() } }, { returnDocument: 'after' });
    res.json({ usuario: publicUser(user) });
  });
  app.post('/api/auth/logout', auth, async (req, res) => {
    await databases.users.updateOne({ _id: req.user._id }, { $inc: { tokenVersion: 1 } });
    res.status(204).end();
  });

  app.get('/api/disciplinas', auth, async (_req, res) => {
    const result = await databases.query('MATCH (d:Disciplina) RETURN properties(d) AS disciplina ORDER BY d.nome');
    res.json({ disciplinas: result.records.map(r => serialize(r.get('disciplina'))) });
  });
  app.get('/api/questoes', auth, async (req, res) => {
    const { limit, offset } = pageSchema.parse(req.query);
    const result = await databases.query(`MATCH (q:Questao)
      RETURN properties(q) AS questao ORDER BY q.id SKIP $offset LIMIT $limit`,
    { offset: neo4j.int(offset), limit: neo4j.int(limit) });
    res.json({ questoes: result.records.map(r => questionView(r.get('questao'))), limit, offset });
  });
  app.get('/api/questoes/:id', auth, async (req, res) => {
    const id = z.string().min(1).max(160).parse(req.params.id);
    const result = await databases.query('MATCH (q:Questao {id: $id}) RETURN properties(q) AS questao LIMIT 1', { id });
    if (!result.records.length) return res.status(404).json({ erro: 'Questão não encontrada.' });
    res.json({ questao: questionView(result.records[0].get('questao')) });
  });
  app.post('/api/questoes/:id/responder', auth, async (req, res) => {
    const id = z.string().min(1).max(160).parse(req.params.id);
    const { alternativa } = z.object({ alternativa: z.enum(['A', 'B', 'C', 'D', 'E']) }).strict().parse(req.body);
    const result = await databases.query(`MATCH (q:Questao {id: $id})
      RETURN coalesce(q.gabarito, q.gabarito_declarado, q.respostaCorreta) AS gabarito LIMIT 1`, { id });
    if (!result.records.length) return res.status(404).json({ erro: 'Questão não encontrada.' });
    const gabarito = String(result.records[0].get('gabarito') ?? '').trim().toUpperCase();
    if (!['A','B','C','D','E'].includes(gabarito)) return res.json({
      corrigida: false, mensagem: 'Esta questão ainda não tem gabarito cadastrado.',
    });
    res.json({ corrigida: true, correta: alternativa === gabarito, gabarito });
  });
  app.use((_req, res) => res.status(404).json({ erro: 'Rota não encontrada.' }));
  app.use((error, _req, res, _next) => {
    if (error instanceof z.ZodError) return res.status(400).json({ erro: 'Revise os dados informados.', campos: error.issues.map(x => ({ campo: x.path.join('.'), mensagem: x.message })) });
    if (error.code === 11000) return res.status(409).json({ erro: 'Este e-mail já está cadastrado.' });
    if (error.type === 'entity.parse.failed') return res.status(400).json({ erro: 'JSON inválido.' });
    if (error.type === 'entity.too.large') return res.status(413).json({ erro: 'Dados acima do limite permitido.' });
    console.error('Falha na API:', error.name, error.code ?? 'sem_codigo');
    res.status(503).json({ erro: 'Serviço indisponível. Tente novamente em instantes.' });
  });
  return app;
}
// Fixed dummy hash keeps a nonexistent account on the same password verification path.
const dummyHash = `scrypt$0123456789abcdef0123456789abcdef$${'0'.repeat(128)}`;
