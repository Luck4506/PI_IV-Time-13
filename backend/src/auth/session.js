import jwt from 'jsonwebtoken';
import { ObjectId } from 'mongodb';

const issuer = 'trilha-api';
const audience = 'trilha-app';
const algorithm = 'HS256';

export function createSessions(users, secret) {
  function sendSession(res, user, status = 200) {
    const token = jwt.sign({ v: user.tokenVersion }, secret, {
      subject: user._id.toString(),
      expiresIn: '12h',
      algorithm,
      issuer,
      audience,
    });

    return res.status(status).json({ token, usuario: publicUser(user) });
  }

  async function authenticate(req, res, next) {
    if (!req.token) {
      return res.status(401).json({ erro: 'Entre na sua conta para continuar.' });
    }

    let payload;
    try {
      payload = jwt.verify(req.token, secret, { algorithms: [algorithm], issuer, audience });

      if (typeof payload.sub !== 'string' || !ObjectId.isValid(payload.sub)) {
        throw new Error('Identificador de usuário inválido.');
      }
    } catch {
      return res.status(401).json({ erro: 'Sessão inválida ou expirada. Entre novamente.' });
    }

    const user = await users.findOne({ _id: new ObjectId(payload.sub) });
    if (!user || user.tokenVersion !== payload.v) {
      return res.status(401).json({ erro: 'Sessão encerrada. Entre novamente.' });
    }

    req.user = user;
    return next();
  }

  return { authenticate, sendSession };
}

export function publicUser(user) {
  return {
    id: user._id.toString(),
    nome: user.nome,
    email: user.email,
    perfil: user.perfil,
    ...(user.anoEscolar ? { anoEscolar: user.anoEscolar } : {}),
    ...(user.codigoEscola ? { codigoEscola: user.codigoEscola } : {}),
    cadastroEducacional: user.perfil === 'teacher' || Boolean(user.codigoEscola),
    criadoEm: user.criadoEm,
  };
}

export function role(expected) {
  return (req, res, next) => {
    if (req.user.perfil !== expected) {
      return res.status(403).json({ erro: 'Sua conta não tem acesso a esta área.' });
    }
    return next();
  };
}
