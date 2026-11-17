import { examOrigin, examQuestionFilter } from './exam-questions.js';
import { relationTypes } from './question-relations.js';

async function readQuestions(databases, match, parameters = {}) {
  const result = await databases.query(`
    ${match}
    OPTIONAL MATCH (q)-[:ABORDA]->(c:Conteudo)
    OPTIONAL MATCH (c)-[:FAZ_PARTE_DE]->(d:Disciplina)
    RETURN properties(q) AS questao, collect(DISTINCT c.nome) AS conteudos,
      collect(DISTINCT d.nome) AS disciplinas
    ORDER BY questao.id
  `, parameters);

  return result.records.map(record => ({
    ...record.get('questao'),
    conteudos: [...record.get('conteudos')].sort(),
    disciplina: record.get('disciplinas')[0] ?? 'Outros assuntos',
  }));
}

export function loadExamQuestions(databases, disciplina) {
  if (disciplina) {
    return readQuestions(databases, `
      MATCH (q:Questao)-[:ABORDA]->(:Conteudo)-[:FAZ_PARTE_DE]->(d:Disciplina {nome: $disciplina})
      WHERE ${examQuestionFilter}
      WITH DISTINCT q
    `, { examOrigin, disciplina });
  }
  return readQuestions(databases, `MATCH (q:Questao) WHERE ${examQuestionFilter}`, { examOrigin });
}

export async function loadQuestionsById(databases, ids) {
  if (!ids.length) return [];

  // A trilha guarda IDs no Mongo. O índice do grafo localiza essas questões,
  // inclusive as antigas que ainda precisam aparecer no histórico.
  return readQuestions(databases, 'UNWIND $ids AS id MATCH (q:Questao {id: id})', {
    ids: [...new Set(ids)],
  });
}

export async function loadCatalog(databases, { relationQuestionIds } = {}) {
  const questions = await readQuestions(databases, 'MATCH (q:Questao)');
  if (relationQuestionIds?.length === 0) return { questions, edges: [] };

  // A auditoria lê todas as relações. Para recomendar reforço, só importam
  // as relações ligadas aos erros, mantendo a direção que está no grafo.
  const match = relationQuestionIds
    ? 'UNWIND $ids AS id MATCH (q:Questao {id: id})-[r]-(:Questao)'
    : 'MATCH (:Questao)-[r]->(:Questao)';
  const edges = await databases.query(`
    ${match}
    WHERE type(r) IN $types
    WITH DISTINCT r
    RETURN startNode(r).id AS de, endNode(r).id AS para, type(r) AS tipo
  `, { types: relationTypes, ...(relationQuestionIds ? { ids: relationQuestionIds } : {}) });

  return { questions, edges: edges.records.map(record => record.toObject()) };
}
