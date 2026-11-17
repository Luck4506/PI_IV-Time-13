import { MongoClient } from 'mongodb';
import neo4j from 'neo4j-driver';
import { ensureCollection } from './mongo-collections.js';
import { initializeTrails } from './trail-storage.js';
import { verificationCollection } from './auth/email-verification.js';
import { initializeClasses } from './school/classes.js';

export function createDatabases(config) {
  const mongo = new MongoClient(config.MONGODB_URI, {
    serverSelectionTimeoutMS: 10_000,
    maxPoolSize: 10,
  });
  const graphAuth = neo4j.auth.basic(config.NEO4J_USERNAME, config.NEO4J_PASSWORD);
  const graph = neo4j.driver(config.NEO4J_URI, graphAuth, {
    maxConnectionPoolSize: 10,
    connectionAcquisitionTimeout: 10_000,
    connectionTimeout: 10_000,
    maxTransactionRetryTime: 10_000,
  });
  const db = mongo.db(config.MONGODB_DATABASE);

  return {
    mongo,
    graph,
    db,
    users: db.collection('usuarios'),
    trails: db.collection('trilhas'),

    async connect() {
      await Promise.all([mongo.connect(), graph.verifyConnectivity()]);
    },

    async close() {
      await Promise.allSettled([mongo.close(), graph.close()]);
    },

    async query(cypher, parameters = {}) {
      const session = graph.session({
        database: config.NEO4J_DATABASE,
        defaultAccessMode: neo4j.session.READ,
      });

      try {
        return await session.executeRead(tx => tx.run(cypher, parameters), { timeout: 10_000 });
      } finally {
        await session.close();
      }
    },
  };
}

export const userValidator = {
  $jsonSchema: {
    bsonType: 'object',
    additionalProperties: false,
    required: [
      '_id', 'nome', 'email', 'perfil', 'senhaHash', 'termosAceitosEm',
      'criadoEm', 'atualizadoEm', 'tokenVersion',
    ],
    properties: {
      _id: { bsonType: 'objectId' },
      nome: { bsonType: 'string', minLength: 2, maxLength: 120 },
      email: { bsonType: 'string', maxLength: 254 },
      perfil: { enum: ['student', 'teacher'] },
      senhaHash: { bsonType: 'string' },
      anoEscolar: { bsonType: 'string', maxLength: 60 },
      codigoEscola: { bsonType: 'string', maxLength: 80 },
      termosAceitosEm: { bsonType: 'date' },
      criadoEm: { bsonType: 'date' },
      atualizadoEm: { bsonType: 'date' },
      tokenVersion: { bsonType: 'int' },
    },
  },
};

export async function initializeMongo(databases) {
  const { db, users } = databases;
  const existing = await ensureCollection(db, 'usuarios', { validator: userValidator });

  // Algumas instalações iniciais já têm a coleção, mas sem o validador.
  if (existing && !existing.options?.validator?.$jsonSchema) {
    await db.command({
      collMod: 'usuarios',
      validator: userValidator,
      validationLevel: 'strict',
    });
  }

  await users.createIndex({ email: 1 }, { unique: true, name: 'email_unico' });
  await db.collection(verificationCollection).createIndex(
    { tokenHash: 1 }, { name: 'link_de_confirmacao_unico', unique: true, sparse: true },
  );

  await initializeTrails(databases);
  await initializeClasses(databases);
}
