import assert from 'node:assert/strict';
import neo4j from 'neo4j-driver';
import { answerKey, loadCatalog } from '../src/trails.js';
import { diagnosticExamples, selectableQuestion } from '../src/exam-questions.js';
import { catalogRelations, makeCatalog } from './questions/catalog.js';

export async function auditGraph(databases) {
  const expectedTopics = makeCatalog();
  const expectedRelations = catalogRelations(expectedTopics);
  const catalog = await loadCatalog(databases);
  const byId = new Map(catalog.questions.map(question => [question.id, question]));
  assert.equal(byId.size, catalog.questions.length, 'IDs de questão duplicados');

  const selectable = catalog.questions.filter(selectableQuestion);
  const expectedCount = expectedTopics.reduce((count, topic) => count + topic.rows.length, 0);
  assert.equal(selectable.length, expectedCount, 'Questão ativa fora do catálogo conferido');
  const activeIds = new Set(selectable.map(question => question.id));

  for (const q of selectable) {
    assert(answerKey(q) && q.conteudos.length && q.disciplina !== 'Outros assuntos', q.id);
  }

  const fields = ['banca', 'ano', 'caderno', 'numero', 'paginaProva', 'provaUrl',
    'gabarito', 'gabaritoUrl', 'dificuldade', 'origem', 'lote'];
  for (const topic of expectedTopics) {
    for (const expected of topic.rows) {
      const found = byId.get(expected.id);
      assert(found && selectableQuestion(found), `Questão oficial ausente: ${expected.id}`);
      assert.equal(found.disciplina, topic.subject, expected.id);
      assert.deepEqual(found.conteudos, [topic.name], expected.id);
      for (const key of fields) {
        const value = neo4j.isInt(found[key]) ? found[key].toNumber() : found[key];
        assert.equal(value, expected[key], `${expected.id} · ${key}`);
      }
    }
  }

  const activeEdges = catalog.edges.filter(edge => activeIds.has(edge.de) && activeIds.has(edge.para));
  const edges = new Set(activeEdges.map(edge => [edge.tipo, edge.de, edge.para].join('|')));
  assert.equal(edges.size, activeEdges.length, 'Relações duplicadas no catálogo ativo');

  const counts = new Map();
  for (const edge of activeEdges) {
    assert.notEqual(edge.de, edge.para, 'Questão relacionada a ela mesma');
    counts.set(edge.tipo, (counts.get(edge.tipo) ?? 0) + 1);
  }
  for (const [type, count] of [
    ['MESMO_TEMA', expectedRelations.sameTopic.length],
    ['PARECIDA_COM', expectedRelations.similar.length],
    ['MESMO_RACIOCINIO', expectedRelations.reasoning.length],
    ['MAIS_FACIL_QUE', expectedRelations.difficulty.length],
    ['MAIS_DIFICIL_QUE', expectedRelations.difficulty.length],
  ]) {
    assert.equal(counts.get(type), count, `Número de relações inesperado: ${type}`);
  }

  const exists = (type, from, to) => edges.has([type, from, to].join('|'));
  for (const [a, b] of expectedRelations.sameTopic) assert(exists('MESMO_TEMA', a, b), a + ' / ' + b);
  for (const [a, b] of expectedRelations.similar) assert(exists('PARECIDA_COM', a, b), a + ' / ' + b);
  for (const { from, to } of expectedRelations.reasoning) assert(exists('MESMO_RACIOCINIO', from, to), from + ' / ' + to);
  for (const { easy, hard } of expectedRelations.difficulty) {
    assert(exists('MAIS_FACIL_QUE', easy, hard) && exists('MAIS_DIFICIL_QUE', hard, easy), easy + ' / ' + hard);
    assert(Number(byId.get(easy).dificuldade) < Number(byId.get(hard).dificuldade), easy + ' / ' + hard);
    assert(!exists('MAIS_FACIL_QUE', hard, easy) && !exists('MAIS_DIFICIL_QUE', easy, hard), easy + ' / ' + hard);
  }

  const schema = await databases.query('SHOW CONSTRAINTS YIELD name RETURN name');
  const constraints = schema.records.map(record => record.get('name'));
  for (const required of ['questao_id', 'disciplina_nome', 'conteudo_nome_disciplina']) {
    assert(constraints.includes(required), `Restrição ausente: ${required}`);
  }
  assert.deepEqual(diagnosticExamples.map(id => answerKey(byId.get(id))), ['A', 'C', 'D']);

  return {
    byId,
    topics: expectedTopics,
    report: {
      questoesAtivas: selectable.length,
      questoesHistoricas: byId.size - selectable.length,
      disciplinasAtivas: new Set(selectable.map(q => q.disciplina)).size,
      conteudosCatalogo: expectedTopics.length,
      paresMesmoTema: expectedRelations.sameTopic.length,
      paresParecidos: expectedRelations.similar.length,
      paresMesmoRaciocinio: expectedRelations.reasoning.length,
      paresComDificuldade: expectedRelations.difficulty.length,
      restricoes: constraints.length,
    },
  };
}
