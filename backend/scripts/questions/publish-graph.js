import assert from 'node:assert/strict';
import neo4j from 'neo4j-driver';
import { edition } from './catalog.js';
import { retiredAuthorOrigin } from '../../src/exam-questions.js';

export async function ensureGraphSchema(session) {
  // As três chaves também existem no grafo original do Desktop.
  const constraints = [
    'CREATE CONSTRAINT questao_id IF NOT EXISTS FOR (q:Questao) REQUIRE q.id IS UNIQUE',
    'CREATE CONSTRAINT disciplina_nome IF NOT EXISTS FOR (d:Disciplina) REQUIRE d.nome IS UNIQUE',
    'CREATE CONSTRAINT conteudo_nome_disciplina IF NOT EXISTS FOR (c:Conteudo) REQUIRE (c.nome, c.disciplina) IS UNIQUE',
  ];
  for (const statement of constraints) {
    await session.run(statement);
  }
}

export async function publishGraph(tx, topics, relations) {
  for (const topic of topics) {
    await publishTopic(tx, topic);
  }

  const sameTopic = await tx.run(`
    UNWIND $pairs AS pair
    MATCH (a:Questao {id: pair[0]}), (b:Questao {id: pair[1]})
    MERGE (a)-[:MESMO_TEMA]->(b)
    RETURN count(*) AS total
  `, { pairs: relations.sameTopic });
  checkCount(sameTopic, relations.sameTopic.length);

  const similar = await tx.run(`
    UNWIND $pairs AS pair
    MATCH (a:Questao {id: pair[0]}), (b:Questao {id: pair[1]})
    MERGE (a)-[:PARECIDA_COM]->(b)
    RETURN count(*) AS total
  `, { pairs: relations.similar });
  checkCount(similar, relations.similar.length);

  const reasoning = await tx.run(`
    UNWIND $pairs AS pair
    MATCH (a:Questao {id: pair.from}), (b:Questao {id: pair.to})
    MERGE (a)-[r:MESMO_RACIOCINIO]->(b)
    SET r.justificativa = pair.reason
    RETURN count(*) AS total
  `, { pairs: relations.reasoning });
  checkCount(reasoning, relations.reasoning.length);

  const difficulty = await tx.run(`
    UNWIND $pairs AS pair
    MATCH (easy:Questao {id: pair.easy}), (hard:Questao {id: pair.hard})
    WHERE easy.dificuldade < hard.dificuldade
    MERGE (easy)-[easier:MAIS_FACIL_QUE]->(hard)
    MERGE (hard)-[harder:MAIS_DIFICIL_QUE]->(easy)
    SET easier.criterio = 'complexidade-resolucao', harder.criterio = 'complexidade-resolucao'
    RETURN count(*) AS total
  `, { pairs: relations.difficulty });
  checkCount(difficulty, relations.difficulty.length);

  await relateEarlierQuestions(tx);
  await tx.run(`
    MATCH (easy:Questao)-[:MAIS_FACIL_QUE]->(hard:Questao)
    WHERE easy <> hard AND coalesce(easy.lote, '') <> $edition AND coalesce(hard.lote, '') <> $edition
    MERGE (hard)-[r:MAIS_DIFICIL_QUE]->(easy)
    ON CREATE SET r.criterio = 'relacao-legada'
  `, { edition });
  const retired = await tx.run(`
    MATCH (q:Questao {origem: $retiredAuthorOrigin})
    SET q.retirada = true
    RETURN count(q) AS total
  `, { retiredAuthorOrigin });

  return retired.records[0].get('total').toNumber();
}

async function publishTopic(tx, topic) {
  const rows = topic.rows.map(row => ({
    ...row,
    ano: neo4j.int(row.ano),
    numero: neo4j.int(row.numero),
    paginaProva: neo4j.int(row.paginaProva),
    dificuldade: neo4j.int(row.dificuldade),
  }));

  const result = await tx.run(`
    MERGE (d:Disciplina {nome: $subject})
    WITH d
    OPTIONAL MATCH (existing:Conteudo {nome: $name})-[:FAZ_PARTE_DE]->(d)
    WITH d, collect(existing) AS oldTopics
    FOREACH (_ IN CASE WHEN size(oldTopics) = 0 THEN [1] ELSE [] END |
      MERGE (fresh:Conteudo {nome: $name, disciplina: $subject})
        ON CREATE SET fresh.id = $id
      MERGE (fresh)-[:FAZ_PARTE_DE]->(d)
    )
    WITH d
    MATCH (topic:Conteudo {nome: $name})-[:FAZ_PARTE_DE]->(d)
    WITH topic ORDER BY elementId(topic)
    WITH head(collect(topic)) AS c
    SET c.disciplina = $subject
    WITH c
    UNWIND $rows AS row
    MERGE (q:Questao {id: row.id})
      ON CREATE SET q += row
    WITH q, row, c
    WHERE q.lote = row.lote AND q.gabarito = row.gabarito
      AND q.banca = row.banca AND q.numero = row.numero AND q.ano = row.ano
      AND q.caderno = row.caderno AND q.disciplina = row.disciplina AND q.nome = row.nome
      AND q.provaUrl = row.provaUrl AND q.paginaProva = row.paginaProva
      AND q.gabaritoUrl = row.gabaritoUrl AND q.dificuldade = row.dificuldade
      AND coalesce(q.retirada, false) = false
    MERGE (q)-[:ABORDA]->(c)
    RETURN count(q) AS total
  `, { id: topic.id, subject: topic.subject, name: topic.name, rows });
  checkCount(result, rows.length, topic.id);
}

async function relateEarlierQuestions(tx) {
  // As ligações antigas ficam no grafo. Questões que dividem o mesmo
  // conteúdo ganham um caminho para as questões oficiais do novo lote.
  await tx.run(`
    MATCH (new:Questao {lote: $edition})-[:ABORDA]->(c:Conteudo)<-[:ABORDA]-(old:Questao)
    WHERE coalesce(old.lote, '') <> $edition
    MERGE (old)-[:MESMO_TEMA]->(new)
  `, { edition });

  const examples = [
    ['FIS-ENEM-01', 'VEST-PUCCAMP-2025-GERAL-Q025'],
    ['FIS-ENEM-01', 'VEST-UNESP-2025-F1-V1-Q077'],
    ['MAT-FUVEST-02', 'VEST-PUCCAMP-2025-GERAL-Q021'],
    ['POR-ENEM-03', 'VEST-UNICAMP-2025-F1-QZ-Q037'],
  ];
  await tx.run(`
    UNWIND $examples AS pair
    MATCH (old:Questao {id: pair[0]}), (fresh:Questao {id: pair[1]})
    MERGE (old)-[:PARECIDA_COM]->(fresh)
  `, { examples });
}

function checkCount(result, expected, context = 'Relacionamentos') {
  assert.equal(result.records[0].get('total').toNumber(), expected, context);
}
