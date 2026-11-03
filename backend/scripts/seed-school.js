import { MongoClient } from 'mongodb';

const mongo = new MongoClient(process.env.MONGODB_URI, { serverSelectionTimeoutMS: 15000 });
try {
  const db = mongo.db(process.env.MONGODB_DATABASE ?? 'trilha');
  const schools = db.collection('escolas');
  await schools.updateOne({ _id: 'ESCOLA-DEMO-001' }, { $setOnInsert: {
    codigo: 'ESCOLA-DEMO-001', nome: 'Escola Horizonte — Demonstração',
    cidade: 'Campinas', uf: 'SP', demonstracao: true, ativa: true,
    descricao: 'Instituição fictícia para testar o seletor de cadastro. Não comprova vínculo escolar.',
    criadoEm: new Date(),
  } }, { upsert: true });
  const school = await schools.findOne({ _id: 'ESCOLA-DEMO-001' });
  console.log(JSON.stringify({ banco: db.databaseName, colecao: 'escolas',
    codigo: school.codigo, nome: school.nome, demonstracao: school.demonstracao }));
} finally { await mongo.close(); }
