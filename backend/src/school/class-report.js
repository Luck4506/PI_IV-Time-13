// Autoria de Lucas Soares Gonçalves RA 25009467
import { ApiError } from '../api-error.js';
import { ObjectId } from 'mongodb';
import { classView } from './classes.js';
import {
  accuracy, groupByQuartile, MIN_QUESTIONS_FOR_QUARTILES, MIN_STUDENTS_FOR_QUARTILES,
} from './quartiles.js';

export function createClassReports(databases, classes) {
  async function roster(turmaId, studentId) {
    const members = databases.db.collection('turmas_alunos');
    return members.aggregate([
      { $match: { turmaId, ...(studentId ? { _id: studentId } : {}) } },
      { $lookup: {
        from: 'usuarios',
        localField: '_id',
        foreignField: '_id',
        pipeline: [
          { $match: { perfil: 'student' } },
          { $project: { nome: 1 } },
        ],
        as: 'aluno',
      } },
      { $unwind: '$aluno' },
      { $project: { nome: '$aluno.nome', ingressouEm: 1 } },
      { $sort: { nome: 1, _id: 1 } },
    ]).toArray();
  }

  async function results(turmaId, members, disciplina) {
    if (!members.length) return [];

    // O primeiro filtro escolhe as trilhas dos alunos da turma. Depois da
    // matrícula, o filtro dos itens guarda só as respostas da matéria no período.
    return databases.trails.aggregate([
      { $match: {
        usuarioId: { $in: members.map(row => row._id) },
        modo: 'normal',
        itens: { $elemMatch: { disciplina, 'resposta.corrigida': true } },
      } },
      { $lookup: { from: 'turmas_alunos', localField: 'usuarioId', foreignField: '_id', as: 'matricula' } },
      { $unwind: '$matricula' },
      { $match: { 'matricula.turmaId': turmaId } },
      { $project: {
        usuarioId: 1,
        itens: {
          $filter: {
            input: '$itens',
            as: 'item',
            cond: { $and: [
              { $eq: ['$$item.disciplina', disciplina] },
              { $eq: ['$$item.resposta.corrigida', true] },
              { $gte: ['$$item.resposta.respondidaEm', '$matricula.ingressouEm'] },
            ] },
          },
        },
      } },
      { $unwind: '$itens' },
      { $group: {
        _id: {
          aluno: '$usuarioId',
          conteudo: { $ifNull: [{ $arrayElemAt: ['$itens.conteudos', 0] }, 'Revisão geral'] },
        },
        questoes: { $addToSet: '$itens.questaoId' },
        respondidas: { $sum: 1 },
        acertos: { $sum: { $cond: ['$itens.resposta.correta', 1, 0] } },
        ultimaRespostaEm: { $max: '$itens.resposta.respondidaEm' },
      } },
    ]).toArray();
  }

  function studentSummaries(members, rows) {
    const summaries = new Map(members.map(({ _id, nome }) => {
      const id = _id.toString();
      return [id, {
        id,
        nome,
        respondidas: 0,
        acertos: 0,
        ultimaRespostaEm: null,
        topicos: [],
        questoes: new Set(),
      }];
    }));

    for (const row of rows) {
      const student = summaries.get(row._id.aluno.toString());
      student.respondidas += row.respondidas;
      student.acertos += row.acertos;
      // A mesma questão pode reaparecer em outra trilha. Para o mínimo,
      // ela conta só uma vez, mesmo se aparecer em dois conteúdos.
      for (const id of row.questoes) student.questoes.add(id);

      if (!student.ultimaRespostaEm || row.ultimaRespostaEm > student.ultimaRespostaEm) {
        student.ultimaRespostaEm = row.ultimaRespostaEm;
      }
      student.topicos.push({
        nome: row._id.conteudo,
        respondidas: row.respondidas,
        acertos: row.acertos,
        aproveitamento: accuracy(row.acertos, row.respondidas),
      });
    }

    return [...summaries.values()].map(({ questoes, ...student }) => ({
      ...student,
      questoesDistintas: questoes.size,
      aproveitamento: accuracy(student.acertos, student.respondidas),
      topicos: student.topicos.sort((a, b) => a.aproveitamento - b.aproveitamento),
    }));
  }

  return {
    async report(id, teacher) {
      const turma = await classes.getTeachingClass(id, teacher);
      const view = classView(turma, teacher._id);
      const members = await roster(turma._id);
      const rows = await results(turma._id, members, view.disciplina);
      const students = studentSummaries(members, rows);
      const groups = groupByQuartile(students.map(({ topicos, ...student }) => student));
      const respondidas = students.reduce((total, student) => total + student.respondidas, 0);
      const acertos = students.reduce((total, student) => total + student.acertos, 0);

      return {
        turma: view,
        ...groups,
        totalAlunos: members.length,
        minimoQuestoesPorAluno: MIN_QUESTIONS_FOR_QUARTILES,
        minimoAlunosParaQuartis: MIN_STUDENTS_FOR_QUARTILES,
        respondidas,
        acertos,
        aproveitamento: accuracy(acertos, respondidas),
      };
    },

    async student(id, studentId, teacher) {
      const turma = await classes.getTeachingClass(id, teacher);
      if (!ObjectId.isValid(studentId)) throw new ApiError(404, 'Aluno não encontrado nesta turma.');
      const members = await roster(turma._id, new ObjectId(studentId));
      if (!members.length) throw new ApiError(404, 'Aluno não encontrado nesta turma.');

      const { disciplina } = classView(turma, teacher._id);
      const rows = await results(turma._id, members, disciplina);
      const [aluno] = studentSummaries(members, rows);
      return { disciplina, aluno };
    },
  };
}
