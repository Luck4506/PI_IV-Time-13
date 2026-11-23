// Autoria de Lucas Soares Gonçalves RA 25009467
import { ANSWER_LETTERS } from './exam-questions.js';
import { ensureCollection } from './mongo-collections.js';

export const recentFirst = { criadoEm: -1, _id: -1 };

export const trailValidator = {
  $jsonSchema: {
    bsonType: 'object',
    additionalProperties: false,
    required: ['_id', 'usuarioId', 'tipo', 'modo', 'status', 'versao', 'itens', 'criadoEm', 'atualizadoEm'],
    properties: {
      _id: { bsonType: 'objectId' },
      usuarioId: { bsonType: 'objectId' },
      tipo: { enum: ['diagnostico', 'pratica', 'revisao', 'exploracao'] },
      modo: { enum: ['normal', 'exemplo'] },
      status: { enum: ['em_andamento', 'concluida'] },
      versao: { bsonType: 'int', minimum: 1 },
      chave: { bsonType: 'string' },
      origemId: { bsonType: 'objectId' },
      proximaTrilhaId: { bsonType: 'objectId' },
      criadoEm: { bsonType: 'date' },
      atualizadoEm: { bsonType: 'date' },
      concluidaEm: { bsonType: 'date' },
      itens: {
        bsonType: 'array',
        minItems: 1,
        maxItems: 20,
        items: {
          bsonType: 'object',
          additionalProperties: false,
          required: ['questaoId', 'nome', 'disciplina', 'conteudos', 'motivo'],
          properties: {
            questaoId: { bsonType: 'string' },
            nome: { bsonType: 'string' },
            disciplina: { bsonType: 'string' },
            conteudos: { bsonType: 'array', items: { bsonType: 'string' } },
            motivo: { bsonType: 'object' },
            resposta: {
              bsonType: 'object',
              additionalProperties: false,
              required: ['alternativa', 'gabarito', 'correta', 'corrigida', 'respondidaEm'],
              properties: {
                alternativa: { enum: ANSWER_LETTERS },
                gabarito: { enum: ANSWER_LETTERS },
                correta: { bsonType: 'bool' },
                corrigida: { bsonType: 'bool' },
                respondidaEm: { bsonType: 'date' },
              },
            },
          },
        },
      },
    },
  },
};

export async function initializeTrails(databases) {
  await ensureCollection(databases.db, 'trilhas', { validator: trailValidator });

  await databases.trails.createIndex(
    { usuarioId: 1, modo: 1, ...recentFirst },
    { name: 'historico_por_modo' },
  );
  await databases.trails.createIndex(
    { usuarioId: 1, modo: 1, ...recentFirst, status: 1 },
    { name: 'trilha_em_andamento', partialFilterExpression: { status: 'em_andamento' } },
  );
  // Trilhas antigas podem não ter chave ou origem. O índice só compara
  // documentos em que cada campo existe com o tipo esperado.
  await databases.trails.createIndex({ usuarioId: 1, chave: 1 }, {
    name: 'inicio_idempotente',
    unique: true,
    partialFilterExpression: { chave: { $type: 'string' } },
  });
  await databases.trails.createIndex({ origemId: 1 }, {
    name: 'uma_continuacao_por_trilha',
    unique: true,
    partialFilterExpression: { origemId: { $type: 'objectId' } },
  });

  for (const name of ['materiais_conteudo', 'progresso_conteudos']) {
    await ensureCollection(databases.db, name);
  }
  await databases.db.collection('progresso_conteudos').createIndex(
    { usuarioId: 1, trilhaId: 1, conteudoId: 1 }, { unique: true, name: 'leitura_por_usuario_etapa' });
}
