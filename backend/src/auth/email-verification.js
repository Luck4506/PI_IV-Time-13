import { createHash, randomBytes } from 'node:crypto';
import { z } from 'zod';
import { dummyHash, verifyPassword } from '../security.js';
import { emailSchema, passwordSchema } from './account-fields.js';
import { createEmailMailer } from './email-mailer.js';

export const verificationCollection = 'verificacoes_email';
export const emailPendingCode = 'EMAIL_NAO_CONFIRMADO';

const tokenPattern = /^[A-Za-z0-9_-]{43}$/;
const tokenLife = 30 * 60 * 1000;
const resendDelay = 60 * 1000;
const hash = token => createHash('sha256').update(token).digest('hex');

export function createEmailVerification({ databases, config, sendMail = createEmailMailer(config), now = Date.now }) {
  const records = databases.db.collection(verificationCollection);

  function newCode() {
    const token = randomBytes(32).toString('base64url');
    const time = now();
    return {
      token,
      fields: {
        tokenHash: hash(token),
        expiraEm: new Date(time + tokenLife),
        reenviarDepoisDe: new Date(time + resendDelay),
      },
    };
  }

  async function deliver(email, token) {
    try {
      await sendMail(email, token);
      return true;
    } catch {
      // O aluno pode pedir outro código. O código e o e-mail ficam fora dos logs.
      console.warn('Envio de confirmação de e-mail indisponível.');
      return false;
    }
  }

  return {
    required: config.EMAIL_VERIFICATION_REQUIRED === 'true',
    available: Boolean(sendMail),

    async prepare(user, session) {
      const { token, fields } = newCode();
      await records.insertOne({ _id: user._id, email: user.email, ...fields }, { session });
      return token;
    },

    deliver,

    async pending(user) {
      const record = await records.findOne({ _id: user._id });
      // Contas existentes antes da ativação da verificação não têm esse registro.
      return Boolean(record && !record.confirmadoEm);
    },

    async resend(email, password) {
      const user = await databases.users.findOne({ email });
      const valid = await verifyPassword(password, user?.senhaHash ?? dummyHash);
      if (!user || !valid) return;

      const { token, fields } = newCode();
      // A consulta e a troca ocorrem juntas. Apenas um pedido atualiza o código.
      const record = await records.findOneAndUpdate(
        {
          _id: user._id,
          email,
          confirmadoEm: { $exists: false },
          reenviarDepoisDe: { $lte: new Date(now()) },
        },
        { $set: fields },
        { returnDocument: 'after' },
      );
      if (record) await deliver(email, token);
    },

    async confirm(token, password) {
      const tokenHash = hash(token);
      const record = await records.findOne({ tokenHash, expiraEm: { $gt: new Date(now()) } });
      const user = record
        ? await databases.users.findOne({ _id: record._id, email: record.email })
        : null;
      const valid = await verifyPassword(password, user?.senhaHash ?? dummyHash);
      if (!record || !user || !valid) return false;

      const time = new Date(now());
      const result = await records.updateOne(
        {
          _id: record._id,
          tokenHash,
          expiraEm: { $gt: time },
          confirmadoEm: { $exists: false },
        },
        { $set: { confirmadoEm: time }, $unset: { tokenHash: '', expiraEm: '', reenviarDepoisDe: '' } },
      );
      return result.modifiedCount === 1;
    },
  };
}

export function mountEmailVerification(app, verification, authLimit) {
  const resendInput = z.object({ email: emailSchema, senha: passwordSchema }).strict();
  const confirmation = z.object({
    codigo: z.string().trim().regex(tokenPattern),
    senha: passwordSchema,
  }).strict();

  app.post('/api/auth/reenviar-confirmacao', authLimit, async (req, res) => {
    const { email, senha } = resendInput.parse(req.body);
    if (!verification.available) {
      return res.status(503).json({ erro: 'O envio de e-mail está indisponível. Tente novamente mais tarde.' });
    }

    await verification.resend(email, senha);
    return res.status(202).json({
      mensagem: 'Se o cadastro estiver pendente e a senha estiver correta, enviaremos outro código. Aguarde um minuto entre pedidos.',
    });
  });

  app.post('/api/auth/confirmar-email', authLimit, async (req, res) => {
    const { codigo, senha } = confirmation.parse(req.body);

    if (!await verification.confirm(codigo, senha)) {
      return res.status(400).json({ erro: 'Confira o código e a senha. Se o código venceu, peça outro.' });
    }
    return res.json({ mensagem: 'E-mail confirmado. Entre com sua conta.' });
  });
}
