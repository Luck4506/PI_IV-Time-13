// Autoria de Lucas Soares Gonçalves RA 25009467
import assert from 'node:assert/strict';
import neo4j from 'neo4j-driver';
import { readConfig } from '../src/config.js';
import { createDatabases } from '../src/databases.js';
import { contentId } from '../src/trail-planning.js';
import { makeCatalog } from './questions/catalog.js';
import { studyNotes } from './questions/study-materials.js';

const config = readConfig();
const databases = createDatabases(config);
const session = databases.graph.session({ database: config.NEO4J_DATABASE });

function materialFor(topic, published, original) {
  if (published?.blocos?.length) {
    // A mesma versão mantém o progresso de quem já concluiu esta leitura.
    return published;
  }

  const note = studyNotes[topic.disciplina]?.[topic.nome];
  if (note) {
    return {
      titulo: topic.nome,
      versao: 1,
      origem: 'Material didático Trilha',
      blocos: [
        { titulo: 'Conceito', texto: note[0] },
        { titulo: 'Antes da prática', texto: note[1] },
      ],
    };
  }

  assert(original, `Falta material de ${topic.disciplina} — ${topic.nome}`);
  return {
    titulo: topic.nome,
    versao: 1,
    origem: 'Material didático Trilha',
    blocos: [{ titulo: 'Antes da prática', texto: original.theory }],
  };
}

try {
  const result = await databases.query(`
    MATCH (c:Conteudo)-[:FAZ_PARTE_DE]->(d:Disciplina)
    RETURN DISTINCT c.nome AS nome, d.nome AS disciplina
    ORDER BY disciplina, nome
  `);
  const topics = result.records.map(record => {
    const { nome, disciplina } = record.toObject();
    return { id: contentId(disciplina, nome), nome, disciplina };
  });
  assert(topics.length > 0, 'Nenhum subtema encontrado no Neo4j.');

  const published = await databases.db.collection('materiais_conteudo').find({
    _id: { $in: topics.map(topic => topic.id) }, publicado: true,
  }).toArray();
  const publishedById = new Map(published.map(material => [material._id, material]));
  const originalById = new Map(makeCatalog().map(topic => [contentId(topic.subject, topic.name), topic]));
  let copied = 0;
  const rows = topics.map(topic => {
    const legacy = publishedById.get(topic.id);
    const material = materialFor(topic, legacy, originalById.get(topic.id));
    if (material === legacy) copied++;
    assert(Number.isSafeInteger(material.versao) && material.versao >= 1, topic.nome);
    assert(typeof material.titulo === 'string' && material.titulo.trim(), topic.nome);
    assert(material.blocos.every(bloco => typeof bloco.titulo === 'string' && bloco.titulo.trim() &&
      typeof bloco.texto === 'string' && bloco.texto.trim()), topic.nome);

    return {
      ...topic,
      titulo: material.titulo,
      versao: neo4j.int(material.versao),
      origem: material.origem ?? 'Material didático Trilha',
      titulosBlocos: material.blocos.map(bloco => bloco.titulo),
      textosBlocos: material.blocos.map(bloco => bloco.texto),
    };
  });

  if (process.argv.includes('--dry-run')) {
    console.log(JSON.stringify({ subtemas: rows.length, reaproveitados: copied, novos: rows.length - copied }));
  } else {
    await session.run('CREATE CONSTRAINT material_estudo_id IF NOT EXISTS FOR (m:MaterialEstudo) REQUIRE m.id IS UNIQUE');
    const writes = await session.executeWrite(async tx => {
      const result = await tx.run(`
        UNWIND $rows AS row
        MATCH (c:Conteudo {nome: row.nome})-[:FAZ_PARTE_DE]->(:Disciplina {nome: row.disciplina})
        MERGE (m:MaterialEstudo {id: row.id})
        ON CREATE SET m += row, m.publicado = true, m.atualizadoEm = datetime()
        MERGE (c)-[:TEM_MATERIAL]->(m)
        RETURN count(DISTINCT m) AS total
      `, { rows });
      assert.equal(Number(result.records[0].get('total')), rows.length);
      return result.summary.counters.updates().nodesCreated;
    });

    console.log(JSON.stringify({ subtemas: rows.length, criadosNoNeo4j: writes,
      reaproveitados: copied, novos: rows.length - copied }));
  }
} finally {
  await session.close();
  await databases.close();
}
