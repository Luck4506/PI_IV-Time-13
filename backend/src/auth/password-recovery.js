// Autoria de Lucas Soares Gonçalves RA 25009467
import { z } from 'zod';
import { hashPassword } from '../security.js';
import { limitarTentativas } from '../tcp-router.js';
import { emailSchema, newPasswordSchema } from './account-fields.js';
import { emailCodePattern, hashEmailCode, newEmailCode } from './email-code.js';

export const recoveryCollection = 'recuperacoes_senha';

const requestInput = z.object({ email: emailSchema }).strict();
const resetInput = z.object({
  codigo: z.string().trim().regex(emailCodePattern),
  senha: newPasswordSchema,
}).strict();

export function mountPasswordRecovery(app, { databases, sendMail, now }) {
  const { users, mongo, db } = databases;
  const codes = db.collection(recoveryCollection);
  const limit = 'Muitas tentativas. Aguarde alguns minutos.';

  async function sendCode(email) {
    const user = await users.findOne({ email }, { projection: { _id: 1 } });
    if (!user) return;

    const time = now();
    const { token, fields } = newEmailCode(time);
    try {
      // Um pedido simultâneo ou dentro do intervalo tenta reutilizar o mesmo ID.
      await codes.updateOne({ _id: user._id, reenviarDepoisDe: { $lte: new Date(time) } },
        { $set: fields }, { upsert: true });
    } catch (error) {
      if (error.code === 11000) return;
      throw error;
    }

    await sendMail(email, token, 'recovery');
  }

  app.post('/api/auth/esqueci-senha', limitarTentativas(limit), (req, res) => {
    const { email } = requestInput.parse(req.body);
    if (!sendMail) return res.status(503).json({ erro: 'O envio de e-mail está indisponível. Tente novamente mais tarde.' });

    // O tempo de envio e o estado da conta ficam fora da resposta pública.
    setImmediate(() => {
      sendCode(email).catch(() => console.warn('Envio de recuperação de senha indisponível.'));
    });
    return res.status(202).json({ mensagem: 'Se o e-mail estiver cadastrado, você receberá um código. Aguarde um minuto entre pedidos.' });
  });

  app.post('/api/auth/redefinir-senha', limitarTentativas(limit), async (req, res) => {
    const { codigo, senha } = resetInput.parse(req.body);
    const tokenHash = hashEmailCode(codigo);
    const available = await codes.findOne({ tokenHash, expiraEm: { $gt: new Date(now()) } });
    if (!available) return res.status(400).json({ erro: 'Código inválido ou expirado. Peça outro código.' });

    const senhaHash = await hashPassword(senha);
    const changed = await mongo.withSession(session => session.withTransaction(async () => {
      const time = new Date(now());
      // Trocar a senha, revogar sessões e consumir o código são uma única operação.
      const consumed = await codes.findOneAndDelete({
        _id: available._id, tokenHash, expiraEm: { $gt: time },
      }, { session });
      if (!consumed) return false;

      const result = await users.updateOne({ _id: consumed._id }, {
        $set: { senhaHash, atualizadoEm: time }, $inc: { tokenVersion: 1 },
      }, { session });
      return result.modifiedCount === 1;
    }));

    if (!changed) return res.status(400).json({ erro: 'Código inválido ou expirado. Peça outro código.' });
    return res.json({ mensagem: 'Senha redefinida. Entre com a nova senha.' });
  });
}
