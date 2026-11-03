import { MongoClient } from 'mongodb';
import neo4j from 'neo4j-driver';
import { initializeTrails } from './trails.js';

export function createDatabases(config) {
  const mongo = new MongoClient(config.MONGODB_URI, {
    serverSelectionTimeoutMS: 10000, maxPoolSize: 10,
  });
  const graph = neo4j.driver(config.NEO4J_URI,
    neo4j.auth.basic(config.NEO4J_USERNAME, config.NEO4J_PASSWORD), {
      maxConnectionPoolSize: 10, connectionAcquisitionTimeout: 10000,
      connectionTimeout: 10000, maxTransactionRetryTime: 10000,
    });
  const db = mongo.db(config.MONGODB_DATABASE);
  return {
    mongo, graph, db, users: db.collection('usuarios'), trails: db.collection('trilhas'),
    async connect() {
      await Promise.all([mongo.connect(), graph.verifyConnectivity()]);
    },
    async close() { await Promise.allSettled([mongo.close(), graph.close()]); },
    async query(query, parameters = {}) {
      const session = graph.session({ database: config.NEO4J_DATABASE, defaultAccessMode: neo4j.session.READ });
      try {
        return await session.executeRead(tx => tx.run(query, parameters), { timeout: 10000 });
      } finally { await session.close(); }
    },
  };
}

export const userValidator = { $jsonSchema: {
  bsonType: 'object', additionalProperties: false,
  required: ['_id', 'nome', 'email', 'perfil', 'senhaHash', 'termosAceitosEm', 'criadoEm', 'atualizadoEm', 'tokenVersion'],
  properties: {
    _id: { bsonType: 'objectId' },
    nome: { bsonType: 'string', minLength: 2, maxLength: 120 },
    email: { bsonType: 'string', maxLength: 254 },
    perfil: { enum: ['student', 'teacher'] },
    senhaHash: { bsonType: 'string' },
    anoEscolar: { bsonType: 'string', maxLength: 60 },
    codigoEscola: { bsonType: 'string', maxLength: 80 },
    termosAceitosEm: { bsonType: 'date' },
    criadoEm: { bsonType: 'date' }, atualizadoEm: { bsonType: 'date' },
    tokenVersion: { bsonType: 'int' },
  },
} };

export async function initializeMongo(databases) {
  const exists = await databases.db.listCollections({ name: 'usuarios' }).hasNext();
  if (!exists) await databases.db.createCollection('usuarios', { validator: userValidator });
  else {
    const collection = await databases.db.listCollections({ name: 'usuarios' }).next();
    if (!collection.options?.validator?.$jsonSchema) {
      await databases.db.command({ collMod: 'usuarios', validator: userValidator, validationLevel: 'strict' });
    }
  }
  await databases.users.createIndex({ email: 1 }, { unique: true, name: 'email_unico' });
  await initializeTrails(databases);
}
