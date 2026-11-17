import { randomBytes, scrypt as scryptCallback, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';

const scrypt = promisify(scryptCallback);
const options = { N: 32768, r: 8, p: 1, maxmem: 64 * 1024 * 1024 };
const hashLength = 64;

// Mantém o custo da verificação de senha também para e-mails inexistentes.
export const dummyHash = `scrypt$0123456789abcdef0123456789abcdef$${'0'.repeat(hashLength * 2)}`;

export async function hashPassword(password) {
  const salt = randomBytes(16).toString('hex');
  const hash = await scrypt(password, salt, hashLength, options);
  return `scrypt$${salt}$${hash.toString('hex')}`;
}

export async function verifyPassword(password, encoded) {
  if (typeof encoded !== 'string') return false;

  const parts = encoded.split('$');
  if (parts.length !== 3) return false;

  const [algorithm, salt, hex] = parts;
  if (algorithm !== 'scrypt' || !salt || !/^[a-f0-9]{128}$/.test(hex)) {
    return false;
  }

  const hash = await scrypt(password, salt, hashLength, options);
  return timingSafeEqual(hash, Buffer.from(hex, 'hex'));
}
