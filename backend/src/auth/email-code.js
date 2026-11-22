// Autoria de Lucas Soares Gonçalves RA 25009467
import { createHash, randomBytes } from 'node:crypto';

export const emailCodePattern = /^[A-Za-z0-9_-]{43}$/;
export const hashEmailCode = code => createHash('sha256').update(code).digest('hex');

export function newEmailCode(time) {
  const token = randomBytes(32).toString('base64url');
  return {
    token,
    fields: {
      tokenHash: hashEmailCode(token),
      expiraEm: new Date(time + 30 * 60_000),
      reenviarDepoisDe: new Date(time + 60_000),
    },
  };
}
