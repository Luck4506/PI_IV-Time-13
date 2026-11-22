// Autoria de Lucas Soares Gonçalves RA 25009467
import neo4j from 'neo4j-driver';
import { z } from 'zod';
import { ApiError } from './api-error.js';
import { ANSWER_LETTERS, answerKey, examOrigin, examQuestionFilter } from './exam-questions.js';

const pageSchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).max(100000).default(0),
});
const idSchema = z.string().min(1).max(160);
const answerSchema = z.object({ alternativa: z.enum(ANSWER_LETTERS) }).strict();

const publicFields = [
  'id', 'nome', 'questao', 'enunciado', 'ano', 'banca', 'numero',
  'alternativaA', 'alternativaB', 'alternativaC', 'alternativaD', 'alternativaE',
  'topicosRelacionados', 'imagens', 'disciplina', 'caderno',
  'paginaProva', 'dificuldade', 'creditoFonte',
];

function serialize(value) {
  if (neo4j.isInt(value)) {
    return value.inSafeRange() ? value.toNumber() : value.toString();
  }
  if (Array.isArray(value)) return value.map(serialize);
  if (value && typeof value === 'object') {
    const entries = Object.entries(value).map(([key, field]) => [key, serialize(field)]);
    return Object.fromEntries(entries);
  }
  return value;
}

export function questionView(question) {
  // Listar apenas os campos públicos impede que o gabarito saia junto com a questão.
  const view = {};
  for (const field of publicFields) {
    if (question[field] !== undefined) view[field] = serialize(question[field]);
  }
  return view;
}

export function mountQuestionRoutes(app, auth, student, databases) {
  async function findQuestion(rawId) {
    const id = idSchema.parse(rawId);
    const result = await databases.query(`
      MATCH (q:Questao {id: $id})
      WHERE ${examQuestionFilter}
      RETURN properties(q) AS questao
      LIMIT 1
    `, { id, examOrigin });

    const record = result.records[0];
    if (!record) throw new ApiError(404, 'Questão não encontrada.');
    return record.get('questao');
  }

  app.get('/api/disciplinas', auth, async (_req, res) => {
    const result = await databases.query(`
      MATCH (q:Questao)-[:ABORDA]->(:Conteudo)-[:FAZ_PARTE_DE]->(d:Disciplina)
      WHERE ${examQuestionFilter}
      WITH DISTINCT d
      RETURN properties(d) AS disciplina
      ORDER BY d.nome
    `, { examOrigin });

    const disciplinas = result.records.map(record => serialize(record.get('disciplina')));
    res.json({ disciplinas });
  });

  app.get('/api/questoes', auth, student, async (req, res) => {
    const { limit, offset } = pageSchema.parse(req.query);
    const result = await databases.query(`
      MATCH (q:Questao)
      WHERE ${examQuestionFilter}
      RETURN properties(q) AS questao
      ORDER BY q.id SKIP $offset LIMIT $limit
    `, { offset: neo4j.int(offset), limit: neo4j.int(limit), examOrigin });

    const questoes = result.records.map(record => questionView(record.get('questao')));
    res.json({ questoes, limit, offset });
  });

  app.get('/api/questoes/:id', auth, student, async (req, res) => {
    const question = await findQuestion(req.params.id);
    res.json({ questao: questionView(question) });
  });

  app.post('/api/questoes/:id/responder', auth, student, async (req, res) => {
    const { alternativa } = answerSchema.parse(req.body);
    const question = await findQuestion(req.params.id);

    if (!question[`alternativa${alternativa}`]) {
      throw new ApiError(400, 'Alternativa não disponível nesta questão.');
    }

    const gabarito = answerKey(question);
    if (!gabarito) {
      return res.json({ corrigida: false, mensagem: 'Esta questão ainda não tem gabarito cadastrado.' });
    }

    res.json({ corrigida: true, correta: alternativa === gabarito, gabarito });
  });
}
