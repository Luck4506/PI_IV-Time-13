import { z } from 'zod';

const port = z.coerce.number().int().min(1).max(65535);
const booleanText = z.enum(['true', 'false']);

const configSchema = z.object({
  TCP_HOST: z.string().trim().min(1).default('127.0.0.1'),
  TCP_PORT: port.default(3002),
  JAVA_VALIDATOR_PORT: port.default(3001),

  MONGODB_URI: z.string().regex(/^mongodb(?:\+srv)?:\/\//),
  MONGODB_DATABASE: z.string().default('trilha'),
  NEO4J_URI: z.string().regex(/^neo4j(\+s)?:\/\//),
  NEO4J_USERNAME: z.string().default('neo4j'),
  NEO4J_PASSWORD: z.string().min(1),
  NEO4J_DATABASE: z.string().default('neo4j'),

  JWT_SECRET: z.string().min(32),
  ALLOW_TEACHER_REGISTRATION: booleanText.default('true'),
  EMAIL_VERIFICATION_REQUIRED: booleanText.default('true'),
  SMTP_HOST: z.string().min(1).optional(),
  SMTP_PORT: port.default(587),
  SMTP_USER: z.string().min(1).optional(),
  SMTP_PASSWORD: z.string().min(1).optional(),
  SMTP_FROM: z.string().email().optional(),
}).refine(config => Boolean(config.SMTP_USER) === Boolean(config.SMTP_PASSWORD), {
  path: ['SMTP_PASSWORD'],
  message: 'Preencha usuário e senha SMTP juntos.',
});

export function readConfig(env = process.env) {
  const settings = { ...env };

  // No modelo de .env, os campos de e-mail ficam vazios até serem configurados.
  for (const [key, value] of Object.entries(env)) {
    if (key.startsWith('SMTP_') && value === '') delete settings[key];
  }

  return configSchema.refine(config => {
    return env.NODE_ENV !== 'production' || config.EMAIL_VERIFICATION_REQUIRED === 'true';
  }, {
    path: ['EMAIL_VERIFICATION_REQUIRED'],
    message: 'A confirmação é obrigatória em produção.',
  }).parse(settings);
}
