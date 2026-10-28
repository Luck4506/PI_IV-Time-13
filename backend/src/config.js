import { z } from 'zod';

export function readConfig(env = process.env) {
  return z.object({
    HOST: z.string().default('127.0.0.1'),
    PORT: z.coerce.number().int().min(1).max(65535).default(3000),
    MONGODB_URI: z.string().startsWith('mongodb'),
    MONGODB_DATABASE: z.string().default('trilha'),
    NEO4J_URI: z.string().regex(/^neo4j(\+s)?:\/\//),
    NEO4J_USERNAME: z.string().default('neo4j'),
    NEO4J_PASSWORD: z.string().min(1),
    NEO4J_DATABASE: z.string().default('neo4j'),
    JWT_SECRET: z.string().min(32),
    CORS_ORIGINS: z.string().default('http://localhost:5173,http://127.0.0.1:5173'),
    ALLOW_TEACHER_REGISTRATION: z.enum(['true', 'false']).default('false'),
  }).parse(env);
}
