// Autoria de Lucas Soares Gonçalves RA 25009467
import { z } from 'zod';
import { dummyHash, verifyPassword } from '../security.js';
import { emailSchema, passwordSchema } from './account-fields.js';
import { emailCodePattern, hashEmailCode, newEmailCode } from './email-code.js';

export const verificationCollection = 'verificacoes_email';
export const emailPendingCode = 'EMAIL_NAO_CONFIRMADO';

export function createEmailVerification({ databases, config, sendMail, now }) {
  const records = databases.db.collection(verificationCollection);

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
      const { token, fields } = newEmailCode(now());
      await records.insertOne({ _id: user._id, email: user.email, ...fields }, { session });
      return token;
    },

    async deliverBefore(email, token, deadline) {
      const delivery = deliver(email, token);
      const remaining = deadline - performance.now();
      if (remaining <= 0) return null;

      let timer;
      try {
        const timeout = new Promise(resolve => { timer = setTimeout(resolve, remaining, null); });
        return await Promise.race([delivery, timeout]);
      } finally {
        clearTimeout(timer);
      }
    },

    async pending(user) {
      const record = await records.findOne({ _id: user._id });
      // Contas existentes antes da ativação da verificação não têm esse registro.
      return Boolean(record && !record.confirmadoEm);
    },

    async resend(email, password) {
      const user = await databases.users.findOne({ email });
      const valid = await verifyPassword(password, user?.senhaHash ?? dummyHash);
      if (!user || !valid) return;

      const { token, fields } = newEmailCode(now());
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
      const tokenHash = hashEmailCode(token);
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
    codigo: z.string().trim().regex(emailCodePattern),
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
