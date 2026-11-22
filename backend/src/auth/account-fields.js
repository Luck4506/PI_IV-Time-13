// Autoria de Lucas Soares Gonçalves RA 25009467
import { z } from 'zod';

export const emailSchema = z.string().trim().toLowerCase().email().max(254);
export const passwordSchema = z.string().min(8).max(128);
export const newPasswordSchema = z.string().refine(password =>
  passwordSchema.safeParse(password).success &&
  /\p{L}/u.test(password) &&
  (password.match(/\p{Nd}/gu)?.length ?? 0) >= 2 &&
  /[^\p{L}\p{Nd}\p{Z}\p{Cc}\s]/u.test(password),
'Use de 8 a 128 caracteres, com uma letra, dois números e um símbolo.');

export const SCHOOL_YEAR_CODES = {
  '1º ano do Ensino Médio': 1,
  '2º ano do Ensino Médio': 2,
  '3º ano do Ensino Médio': 3,
  'Outro': 0,
};

export const schoolYearSchema = z.preprocess(value => {
  if (typeof value !== 'string') return value;

  const year = value.trim();

  // As versões anteriores do app também enviavam a opção abreviada.
  return /^[1-3]º ano$/.test(year) ? `${year} do Ensino Médio` : year;
}, z.enum(Object.keys(SCHOOL_YEAR_CODES)));
