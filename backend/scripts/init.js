// Autoria de Lucas Soares Gonçalves RA 25009467
import { MongoClient } from 'mongodb';
import { initializeMongo } from '../src/databases.js';
if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI ausente.');
const mongo = new MongoClient(process.env.MONGODB_URI, { serverSelectionTimeoutMS: 15000 });
const db = mongo.db(process.env.MONGODB_DATABASE ?? 'trilha');
const databases = { mongo, db, users: db.collection('usuarios'), trails: db.collection('trilhas') };
try {
  await databases.mongo.connect();
  await initializeMongo(databases);
  console.log('MongoDB: usuarios e trilhas prontos, com validação e índices. Catálogo de questões mantido no Neo4j.');
} finally { await mongo.close(); }
