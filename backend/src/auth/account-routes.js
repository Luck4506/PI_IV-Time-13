import { ObjectId } from 'mongodb';
import { z } from 'zod';
import { ApiError } from '../api-error.js';
import { limitarTentativas } from '../tcp-router.js';
import { dummyHash, hashPassword, verifyPassword } from '../security.js';
import { codeField } from '../school/class-routes.js';
import { emailSchema, passwordSchema, SCHOOL_YEAR_CODES, schoolYearSchema } from './account-fields.js';
import { createEmailVerification, emailPendingCode, mountEmailVerification } from './email-verification.js';
import { publicUser } from './session.js';

const registration = z.object({
  nome: z.string().trim().min(2).max(120),
  email: emailSchema,
  senha: passwordSchema,
  perfil: z.enum(['student', 'teacher']),
  anoEscolar: schoolYearSchema.optional(),
  dataNascimento: z.iso.date().optional(),
  codProfessor: z.string().regex(/^[0-9]{4}$/).optional(),
  cadastroEducacional: z.boolean().optional(),
  codigoEscola: z.string().trim().max(80).optional(),
  codigoTurma: codeField.optional(),
  termosAceitos: z.literal(true),
}).strict()
  .refine(data => data.perfil !== 'student' || Boolean(data.anoEscolar), {
    message: 'Informe o ano escolar.',
    path: ['anoEscolar'],
  })
  .refine(data => data.perfil !== 'teacher' || data.cadastroEducacional !== false, {
    message: 'O cadastro de professor é sempre educacional.',
    path: ['cadastroEducacional'],
  })
  .refine(data => data.cadastroEducacional !== true || Boolean(data.codigoEscola), {
    message: 'Selecione sua escola.',
    path: ['codigoEscola'],
  })
  .refine(data => data.cadastroEducacional !== false || !data.codigoEscola, {
    message: 'Ative o cadastro educacional para selecionar uma escola.',
    path: ['codigoEscola'],
  })
  .refine(data => !data.codigoTurma || (data.perfil === 'student' && data.cadastroEducacional === true), {
    message: 'O código de turma está disponível para alunos com cadastro educacional.',
    path: ['codigoTurma'],
  });

const login = z.object({
  email: emailSchema,
  senha: passwordSchema,
  perfil: z.enum(['student', 'teacher']).optional(),
}).strict();

const profile = z.object({
  nome: z.string().trim().min(2).max(120).optional(),
  anoEscolar: schoolYearSchema.optional(),
}).strict().refine(data => Object.keys(data).length > 0, 'Informe um campo para atualizar.');

export function mountAccountRoutes(app, { databases, config, sessions, classes, javaValidator, emailOptions }) {
  const schools = databases.db.collection('escolas');
  const users = databases.users;
  const { authenticate, sendSession } = sessions;
  const authLimit = limitarTentativas('Muitas tentativas. Aguarde alguns minutos.');
  const verification = createEmailVerification({ databases, config, ...emailOptions });

  async function validateWithJava(pedido) {
    let result;
    try {
      result = await javaValidator(pedido);
    } catch {
      throw new ApiError(503, 'O servidor de validação está indisponível. Tente novamente.');
    }

    if (!result.valido) throw new ApiError(400, result.mensagem);
  }

  async function saveRegistration(user, turma) {
    if (!turma && !verification.required) {
      await users.insertOne(user);
      return;
    }

    // Se houver turma ou confirmação, gravamos todos os dados de uma vez.
    // O código só é enviado por e-mail depois que a transação termina.
    return databases.mongo.withSession(session => session.withTransaction(async () => {
      await users.insertOne(user, { session });
      if (turma) await classes.enroll(turma, user, session);
      if (verification.required) return verification.prepare(user, session);
    }));
  }

  mountEmailVerification(app, verification, authLimit);

  app.post('/api/auth/cadastro', authLimit, async (req, res) => {
    const data = registration.parse(req.body);
    const isTeacher = data.perfil === 'teacher';

    if (isTeacher && config.ALLOW_TEACHER_REGISTRATION !== 'true') {
      throw new ApiError(403, 'O cadastro de professor está desativado neste ambiente.');
    }
    if (isTeacher && !data.codigoEscola) {
      throw new ApiError(400, 'Selecione sua escola.');
    }

    // O MongoDB guarda o nome do ano letivo. O Java recebe o código da opção.
    await validateWithJava({
      tipo: 'VALIDAR_CADASTRO',
      nome: data.nome,
      email: data.email,
      senha: data.senha,
      dataNascimento: data.dataNascimento,
      perfil: isTeacher ? 2 : 1,
      ...(isTeacher
        ? { codProfessor: data.codProfessor }
        : { anoEscolar: SCHOOL_YEAR_CODES[data.anoEscolar] }),
    });

    if (data.codigoEscola) {
      const school = await schools.findOne({ _id: data.codigoEscola, ativa: true });
      if (!school) throw new ApiError(400, 'Selecione uma escola ativa.');
    }

    const turma = data.codigoTurma
      ? await classes.enrollmentTarget(data.codigoTurma, data.codigoEscola)
      : null;

    if (verification.required && !verification.available) {
      throw new ApiError(503, 'O envio de confirmação por e-mail está indisponível. Tente novamente mais tarde.');
    }

    const now = new Date();
    const user = {
      _id: new ObjectId(),
      nome: data.nome,
      email: data.email,
      perfil: data.perfil,
      senhaHash: await hashPassword(data.senha),
      termosAceitosEm: now,
      criadoEm: now,
      atualizadoEm: now,
      tokenVersion: 0,
    };

    if (!isTeacher) user.anoEscolar = data.anoEscolar;
    if ((isTeacher || data.cadastroEducacional === true) && data.codigoEscola) {
      user.codigoEscola = data.codigoEscola;
    }

    const confirmationCode = await saveRegistration(user, turma);
    if (confirmationCode) {
      const emailEnviado = await verification.deliver(user.email, confirmationCode);
      return res.status(201).json({ verificacaoPendente: true, emailEnviado });
    }

    return sendSession(res, user, 201);
  });

  app.post('/api/auth/login', authLimit, async (req, res) => {
    const { email, senha, perfil } = login.parse(req.body);
    await validateWithJava({ tipo: 'VALIDAR_LOGIN', email, senha });

    const user = await users.findOne({ email });
    const validPassword = await verifyPassword(senha, user?.senhaHash ?? dummyHash);
    if (!user || !validPassword || (perfil && user.perfil !== perfil)) {
      throw new ApiError(401, 'E-mail, senha ou perfil incorretos.');
    }
    if (await verification.pending(user)) {
      return res.status(403).json({ codigo: emailPendingCode, erro: 'Confirme seu e-mail para entrar.' });
    }

    return sendSession(res, user);
  });

  app.get('/api/usuarios/me', authenticate, (req, res) => {
    res.json({ usuario: publicUser(req.user) });
  });

  app.patch('/api/usuarios/me', authenticate, async (req, res) => {
    const data = profile.parse(req.body);
    if (req.user.perfil === 'teacher' && data.anoEscolar !== undefined) {
      throw new ApiError(400, 'Campo incompatível com o perfil.');
    }

    const user = await users.findOneAndUpdate(
      { _id: req.user._id },
      { $set: { ...data, atualizadoEm: new Date() } },
      { returnDocument: 'after' },
    );

    if (!user) throw new ApiError(401, 'Sessão encerrada. Entre novamente.');
    res.json({ usuario: publicUser(user) });
  });

  app.post('/api/auth/logout', authenticate, async (req, res) => {
    // Dois pedidos do mesmo token só podem revogar a versão uma vez.
    await users.updateOne(
      { _id: req.user._id, tokenVersion: req.user.tokenVersion },
      { $inc: { tokenVersion: 1 } },
    );
    res.status(204).end();
  });

  app.get('/api/escolas', async (_req, res) => {
    const activeSchools = await schools.find({ ativa: true }, { projection: { nome: 1, demonstracao: 1 } })
      .sort({ nome: 1 })
      .toArray();

    res.json({
      escolas: activeSchools.map(school => ({
        codigo: school._id,
        nome: school.nome,
        ...(school.demonstracao === true ? { demonstracao: true } : {}),
      })),
      validacaoJava: true,
    });
  });
}
