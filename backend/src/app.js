// Autoria de Lucas Soares Gonçalves RA 25009467
import { z } from 'zod';
import { ApiError } from './api-error.js';
import { mountAccountRoutes } from './auth/account-routes.js';
import { createSessions, role } from './auth/session.js';
import { countExamQuestions } from './exam-questions.js';
import { mountQuestionRoutes, questionView } from './question-routes.js';
import { mountClassRoutes } from './school/class-routes.js';
import { createClassService } from './school/classes.js';
import { mountActivityRoutes } from './student/activity-routes.js';
import { criarRotas } from './tcp-router.js';
import { mountTrailRoutes } from './trails.js';

export { questionView } from './question-routes.js';

export function createApp({
  databases,
  config,
  databaseReady = () => true,
  emailOptions = {},
}) {
  const app = criarRotas(respostaDeErro, path => {
    if (path.startsWith('/api/') && !databaseReady()) {
      throw new ApiError(503, 'Conexão com o banco indisponível. Aguarde e tente novamente.');
    }
  });

  const sessions = createSessions(databases.users, config.JWT_SECRET);
  const classes = createClassService(databases);
  const auth = sessions.authenticate;
  const student = role('student');

  mountHealthRoutes(app, databases, config, databaseReady);
  mountAccountRoutes(app, { databases, config, sessions, classes, emailOptions });
  mountQuestionRoutes(app, auth, student, databases);
  mountClassRoutes(app, auth, databases, classes);
  mountActivityRoutes(app, auth, databases);
  mountTrailRoutes(app, [auth, student], databases, questionView);

  return app.atender;
}

function mountHealthRoutes(app, databases, config, databaseReady) {
  const graphHost = config.NEO4J_URI ? new URL(config.NEO4J_URI).hostname : null;
  const graphSource = ['localhost', '127.0.0.1', '[::1]'].includes(graphHost) ? 'local' : 'remoto';

  app.get('/health/live', (_req, res) => {
    res.json({
      status: 'ok',
      protocolo: 'trilha-tcp',
      autenticacao: 'java-http',
      mongodb: databaseReady(),
      grafo: graphSource,
    });
  });

  app.get('/health/ready', async (_req, res) => {
    if (!databaseReady()) {
      return res.status(503).json({
        status: 'indisponivel',
        mongodb: false,
        neo4j: false,
        catalogo: false,
      });
    }

    // Uma conexão aberta com o grafo ainda pode ter o catálogo vazio.
    const [mongo, graph] = await Promise.allSettled([
      databases.db.command({ ping: 1 }),
      countExamQuestions(databases),
    ]);

    const mongodb = mongo.status === 'fulfilled';
    const neo4j = graph.status === 'fulfilled';
    const catalogo = neo4j && graph.value > 0;
    const ready = mongodb && catalogo;

    return res.status(ready ? 200 : 503).json({
      status: ready ? 'ok' : 'indisponivel',
      mongodb,
      neo4j,
      catalogo,
    });
  });
}

function respostaDeErro(erro, caminho) {
  if (erro instanceof ApiError) {
    return { status: erro.status, corpo: { erro: erro.message } };
  }

  if (erro instanceof z.ZodError) {
    const campos = erro.issues.map(issue => ({
      campo: issue.path.join('.'),
      mensagem: issue.message,
    }));

    return { status: 400, corpo: { erro: 'Revise os dados informados.', campos } };
  }

  if (erro?.code === 11000) {
    const duplicateEmail = erro.keyPattern
      ? Boolean(erro.keyPattern.email)
      : caminho === '/api/auth/cadastro';
    const mensagem = duplicateEmail
      ? 'Este e-mail já está cadastrado.'
      : 'O registro já existe. Atualize a tela e tente novamente.';

    return { status: 409, corpo: { erro: mensagem } };
  }

  // O detalhe pode conter campos do banco. Registramos só o tipo e o código.
  console.error('Falha na API:', erro?.name ?? 'Erro', erro?.code ?? 'sem_codigo');
  return { status: 503, corpo: { erro: 'Serviço indisponível. Tente novamente em instantes.' } };
}
