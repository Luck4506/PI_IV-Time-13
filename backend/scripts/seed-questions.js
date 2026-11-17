import assert from 'node:assert/strict';
import { readConfig } from '../src/config.js';
import { createDatabases } from '../src/databases.js';
import { contentId } from '../src/trails.js';
import { catalogRelations, makeCatalog } from './questions/catalog.js';
import { ensureGraphSchema, publishGraph } from './questions/publish-graph.js';

const topics = makeCatalog();
const relations = catalogRelations(topics);
const totals = {
  bancas: new Set(topics.flatMap(topic => topic.rows.map(row => row.banca))).size,
  disciplinas: new Set(topics.map(topic => topic.subject)).size,
  conteudos: topics.length,
  questoes: topics.reduce((count, topic) => count + topic.rows.length, 0),
  paresMesmoRaciocinio: relations.reasoning.length,
  paresParecidos: relations.similar.length,
  paresMesmoTema: relations.sameTopic.length,
  paresComDificuldade: relations.difficulty.length,
};

if (process.argv.includes('--dry-run')) {
  console.log(JSON.stringify(totals));
} else {
  await publish();
}

async function publish() {
  const config = readConfig();
  const databases = createDatabases(config);
  const session = databases.graph.session({ database: config.NEO4J_DATABASE });

  try {
    await ensureGraphSchema(session);
    const autoraisArquivadas = await session.executeWrite(tx => publishGraph(tx, topics, relations));
    await publishTheory(databases);
    console.log(JSON.stringify({ neo4j: 'verificado', materiais: 'verificados', autoraisArquivadas, ...totals }));
  } finally {
    await session.close();
    await databases.close();
  }
}

async function publishTheory(databases) {
  const materials = databases.db.collection('materiais_conteudo');
  const writes = topics.map(topic => ({
    updateOne: {
      filter: { _id: contentId(topic.subject, topic.name) },
      update: { $setOnInsert: {
        nome: topic.name,
        disciplina: topic.subject,
        titulo: topic.name,
        versao: 1,
        publicado: true,
        origem: 'Material didático Trilha',
        atualizadoEm: new Date(),
        blocos: [{ titulo: 'Antes da prática', texto: topic.theory }],
      } },
      upsert: true,
    },
  }));
  await materials.bulkWrite(writes);
  const count = await materials.countDocuments({ _id: { $in: writes.map(write => write.updateOne.filter._id) } });
  assert.equal(count, topics.length);
}
