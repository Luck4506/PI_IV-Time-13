import assert from 'node:assert/strict';
import { userValidator } from '../src/databases.js';
import { contentId } from '../src/trail-planning.js';
import { trailValidator } from '../src/trail-storage.js';

export async function auditMongo(databases, graph) {
  const { db, users, trails } = databases;
  const materials = db.collection('materiais_conteudo');
  const classes = db.collection('turmas');
  const members = db.collection('turmas_alunos');
  const teachers = db.collection('professores_disciplinas');
  const materialsIds = graph.topics.map(topic => contentId(topic.subject, topic.name));

  // Conferimos a regra no Atlas além de testar os documentos que já existem.
  await assertValidator(db, 'usuarios', userValidator);
  await assertValidator(db, 'trilhas', trailValidator);

  const [invalidUsers, invalidTrails, published, questionIds, orphanedTrails, orphanedMembers,
    orphanedClasses, orphanedReadings, orphanedSubjects, invalidDocentes, invalidAnswers,
    invalidTrailProgress, invalidContinuations] = await Promise.all([
    users.countDocuments({ $nor: [userValidator] }),
    trails.countDocuments({ $nor: [trailValidator] }),
    materials.countDocuments({ _id: { $in: materialsIds }, publicado: true, 'blocos.0': { $exists: true } }),
    trails.distinct('itens.questaoId'),
    missingReference(trails, 'usuarios', 'usuarioId'),
    members.aggregate([
      { $lookup: { from: 'usuarios', localField: '_id', foreignField: '_id', as: 'aluno' } },
      { $lookup: { from: 'turmas', localField: 'turmaId', foreignField: '_id', as: 'turma' } },
      { $match: { $or: [{ 'aluno.perfil': { $ne: 'student' } }, { turma: { $size: 0 } }] } },
      { $count: 'total' },
    ]).toArray(),
    missingReference(classes, 'escolas', 'codigoEscola'),
    missingReference(db.collection('progresso_conteudos'), 'trilhas', 'trilhaId'),
    missingReference(teachers, 'usuarios', '_id'),
    classes.aggregate([
      { $unwind: '$docentes' },
      { $lookup: { from: 'usuarios', localField: 'docentes.professorId', foreignField: '_id', as: 'professor' } },
      { $lookup: { from: 'professores_disciplinas', localField: 'docentes.professorId', foreignField: '_id', as: 'vinculo' } },
      { $match: { $expr: { $or: [
        { $ne: [{ $arrayElemAt: ['$professor.perfil', 0] }, 'teacher'] },
        { $ne: [{ $arrayElemAt: ['$professor.codigoEscola', 0] }, '$codigoEscola'] },
        { $ne: [{ $arrayElemAt: ['$vinculo.disciplina', 0] }, '$docentes.disciplina'] },
      ] } } },
      { $count: 'total' },
    ]).toArray(),
    trails.aggregate([
      { $unwind: '$itens' },
      { $match: { 'itens.resposta.corrigida': true, $expr: { $ne: [
        '$itens.resposta.correta', { $eq: ['$itens.resposta.alternativa', '$itens.resposta.gabarito'] },
      ] } } },
      { $count: 'total' },
    ]).toArray(),
    trails.aggregate([
      { $project: {
        status: 1,
        concluidaEm: { $ifNull: ['$concluidaEm', null] },
        total: { $size: '$itens' },
        questoesDistintas: { $size: { $setUnion: ['$itens.questaoId', []] } },
        respostas: { $size: '$itens.resposta' },
      } },
      { $match: { $expr: { $or: [
        { $ne: ['$total', '$questoesDistintas'] },
        { $ne: [{ $eq: ['$total', '$respostas'] }, { $eq: ['$status', 'concluida'] }] },
        { $ne: [{ $ne: ['$concluidaEm', null] }, { $eq: ['$status', 'concluida'] }] },
      ] } } },
      { $count: 'total' },
    ]).toArray(),
    trails.aggregate([
      { $match: { origemId: { $type: 'objectId' } } },
      { $lookup: { from: 'trilhas', localField: 'origemId', foreignField: '_id', as: 'origem' } },
      { $match: { $expr: { $or: [
        { $ne: [{ $arrayElemAt: ['$origem.usuarioId', 0] }, '$usuarioId'] },
        { $ne: [{ $arrayElemAt: ['$origem.modo', 0] }, '$modo'] },
        { $ne: [{ $arrayElemAt: ['$origem.status', 0] }, 'concluida'] },
        { $eq: ['$origemId', '$_id'] },
      ] } } },
      { $count: 'total' },
    ]).toArray(),
  ]);

  const missingQuestions = questionIds.filter(id => !graph.byId.has(id));
  assert.deepEqual(missingQuestions, [], 'Trilhas com referência de questão fora do grafo');
  assert.equal(published, materialsIds.length, 'Materiais teóricos ausentes');
  const issues = {
    usuariosInvalidos: invalidUsers,
    trilhasInvalidas: invalidTrails,
    trilhasSemUsuario: orphanedTrails,
    matriculasInconsistentes: total(orphanedMembers),
    turmasSemEscola: orphanedClasses,
    leiturasSemTrilha: orphanedReadings,
    disciplinasSemConta: orphanedSubjects,
    vinculosDocentesInvalidos: total(invalidDocentes),
    respostasInconsistentes: total(invalidAnswers),
    progressoDeTrilhaInconsistente: total(invalidTrailProgress),
    continuacoesInconsistentes: total(invalidContinuations),
  };
  for (const [name, count] of Object.entries(issues)) assert.equal(count, 0, name);

  await assertIndex(users, 'email_unico', true);
  await assertIndex(trails, 'historico_por_modo', false);
  await assertIndex(trails, 'trilha_em_andamento', false);
  await assertIndex(trails, 'inicio_idempotente', true);
  await assertIndex(trails, 'uma_continuacao_por_trilha', true);
  await assertIndex(classes, 'codigo_da_turma', true);
  await assertIndex(members, 'alunos_da_turma', false);

  return { materiaisPublicados: published, referenciasDeQuestoes: questionIds.length, ...issues };
}

function total(result) {
  return result[0]?.total ?? 0;
}

async function missingReference(collection, from, localField) {
  const rows = await collection.aggregate([
    { $lookup: { from, localField, foreignField: '_id', as: 'referencia' } },
    { $match: { referencia: { $size: 0 } } },
    { $count: 'total' },
  ]).toArray();
  return total(rows);
}

async function assertIndex(collection, name, unique) {
  const index = (await collection.indexes()).find(entry => entry.name === name);
  assert(index && Boolean(index.unique) === unique, `Índice ausente ou incompatível: ${name}`);
}

async function assertValidator(db, name, validator) {
  const collection = await db.listCollections({ name }).next();
  const options = collection?.options;
  assert.deepEqual(options?.validator, validator, `Validação ausente ou diferente: ${name}`);
  assert.equal(options.validationLevel ?? 'strict', 'strict', name);
  assert.equal(options.validationAction ?? 'error', 'error', name);
}
