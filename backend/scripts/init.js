import { MongoClient } from 'mongodb';
import { initializeMongo } from '../src/databases.js';
if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI ausente.');
const mongo = new MongoClient(process.env.MONGODB_URI, { serverSelectionTimeoutMS: 15000 });
const db = mongo.db(process.env.MONGODB_DATABASE ?? 'trilha');
const databases = { mongo, db, users: db.collection('usuarios') };
try {
  await databases.mongo.connect();
  await initializeMongo(databases);
  console.log('MongoDB: coleção usuarios, validação e índice único de e-mail prontos. Nenhuma questão armazenada.');
} finally { await mongo.close(); }
