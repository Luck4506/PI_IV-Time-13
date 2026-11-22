// Autoria de Lucas Soares Gonçalves RA 25009467
import assert from 'node:assert/strict';
import { createHash, createHmac } from 'node:crypto';
import { writeFile } from 'node:fs/promises';
import { ObjectId } from 'mongodb';
import { readConfig } from '../src/config.js';
import { createDatabases } from '../src/databases.js';
import { answerKey, selectableQuestion } from '../src/exam-questions.js';
import { hashPassword, verifyPassword } from '../src/security.js';
import { loadStudyMaterials } from '../src/study-materials.js';
import { loadExamQuestions } from '../src/trail-catalog.js';
import { contentStages, itemFor } from '../src/trail-planning.js';

const schools = [
  ['ESCOLA-DEMO-001', 'Escola Horizonte', [
    ['3º A — Matemática', 'Matemática', 'Helena Martins', ['Lívia Rocha', 'Miguel Ferreira', 'Sofia Andrade', 'Pedro Neves', 'Isadora Nunes', 'Enzo Moura']],
    ['2º B — Física', 'Física', 'Rafael Cardoso', ['Laura Ramos', 'Gabriel Melo', 'Beatriz Pinto', 'Davi Freitas', 'Júlia Reis', 'Caio Costa']],
  ]],
  ['ESCOLA-IPES-002', 'Colégio dos Ipês', [
    ['3º C — Biologia', 'Biologia', 'Mariana Duarte', ['Ana Alves', 'João Barros', 'Manuela Moraes', 'Lucas Gomes', 'Clara Luz', 'Arthur Lima']],
    ['2º D — Química', 'Química', 'Eduardo Azevedo', ['Alice Brito', 'Heitor Leal', 'Valentina Dias', 'Bernardo Vieira', 'Elisa Campos', 'Matheus Castro']],
  ]],
  ['ESCOLA-ESTACOES-003', 'Escola Estações', [
    ['3º E — Matemática', 'Matemática', 'Patrícia Ribeiro', ['Letícia Tavares', 'Felipe Sales', 'Olívia Carvalho', 'Daniel Xavier', 'Luísa Teixeira', 'Bruno Cunha']],
    ['2º F — Biologia', 'Biologia', 'André Cavalcante', ['Camila Farias', 'Henrique Lopes', 'Cecília Mendes', 'Gustavo Barbosa', 'Íris Siqueira', 'Diego Moreira']],
  ]],
];

const apply = process.argv.includes('--apply');
const secret = process.env.APRESENTACAO_SEGREDO;
const accessFile = process.env.APRESENTACAO_ACESSOS;
assert(!apply || secret?.length >= 32, 'Defina APRESENTACAO_SEGREDO com pelo menos 32 caracteres.');
assert(!apply || accessFile, 'Defina APRESENTACAO_ACESSOS para salvar os acessos fora do Git.');
const digest = key => createHash('sha256').update('gabariteii-apresentacao-v1:' + key).digest('hex');
const id = key => new ObjectId(digest(key).slice(0, 24));
const reference = Date.now();
const daysAgo = days => new Date(reference - days * 86_400_000);

function account(key, nome, perfil, codigoEscola, anoEscolar) {
  return {
    _id: id('conta:' + key), nome, perfil, codigoEscola,
    email: key + '@gabariteii.example.test',
    ...(anoEscolar ? { anoEscolar } : {}),
    tokenVersion: 0, criadoEm: daysAgo(12), atualizadoEm: daysAgo(12),
    termosAceitosEm: daysAgo(12),
  };
}

function activity(user, key, tipo, questions, correct, date, answered = questions.length) {
  const itens = questions.map((question, index) => {
    const item = itemFor(question, {
      tipo: 'inicial', origens: [], relacoes: [], pontuacao: 0,
      descricao: 'Atividade de estudo de ' + question.disciplina + '.',
    });
    if (index < answered) {
      const gabarito = answerKey(question);
      const certa = (index + correct) % questions.length < correct;
      const errada = [...'ABCDE'].find(letter => letter !== gabarito && question['alternativa' + letter]);
      assert(errada, 'Questão sem alternativa incorreta.');
      item.resposta = {
        alternativa: certa ? gabarito : errada,
        gabarito, correta: certa, corrigida: true,
        respondidaEm: new Date(date.getTime() + (index + 1) * 60_000),
      };
    }
    return item;
  });
  const finished = answered === questions.length;
  const atualizadoEm = itens[answered - 1]?.resposta.respondidaEm ?? date;
  return {
    _id: id('trilha:' + user.email + ':' + key),
    usuarioId: user._id, chave: 'apresentacao-' + key, tipo, modo: 'normal',
    status: finished ? 'concluida' : 'em_andamento', versao: answered + 1,
    criadoEm: date, atualizadoEm, itens,
    ...(finished ? { concluidaEm: atualizadoEm } : {}),
  };
}

function insert(doc) {
  return { updateOne: { filter: { _id: doc._id }, update: { $setOnInsert: doc }, upsert: true } };
}

function legacyName(name) {
  if (name === 'Aluno Educacional Demonstração') return 'Marcelo Batista';
  if (name === 'Estudante de Conquistas (demo)') return 'Marina Souza';
  return name.replace(/\s+\(demo\)$/i, '');
}

const databases = createDatabases(readConfig());
const { db, users, trails } = databases;
try {
  const questions = (await loadExamQuestions(databases)).filter(q => selectableQuestion(q) && answerKey(q));
  const bySubject = Object.groupBy(questions, q => q.disciplina);
  const diagnostic = Object.values(bySubject).slice(0, 3).map(questions => questions[0]);
  const classes = [], teachers = [], students = [], memberships = [], activities = [], accounts = [];

  for (const [schoolIndex, [schoolCode, schoolName, groups]] of schools.entries()) {
    for (const [classIndex, [name, subject, teacherName, studentNames]] of groups.entries()) {
      const key = `${schoolIndex + 1}${classIndex + 1}`;
      const year = (classIndex === 0 ? '3º' : '2º') + ' ano do Ensino Médio';
      const teacher = account('professor.' + key, teacherName, 'teacher', schoolCode);
      const classId = id('turma:' + key);
      const code = digest('matricula:' + key).slice(0, 12).toUpperCase();
      const pool = bySubject[subject].filter(question => !diagnostic.includes(question));
      const practice = pool.slice(classIndex, classIndex + 6);
      assert.equal(practice.length, 6, subject);
      const next = pool.filter(question => !practice.includes(question)).slice(0, 2);
      assert.equal(next.length, 2, subject);

      teachers.push({ _id: teacher._id, disciplina: subject, criadoEm: daysAgo(11) });
      classes.push({
        _id: classId, nome: name, codigo: code, codigoEscola: schoolCode,
        criadoPor: teacher._id, criadoEm: daysAgo(11),
        docentes: [{ professorId: teacher._id, disciplina: subject }],
      });
      accounts.push({ user: teacher, schoolName, className: name, code });

      for (const [index, studentName] of studentNames.entries()) {
        const student = account(`aluno.${key}.${index + 1}`, studentName, 'student', schoolCode, year);
        students.push(student);
        accounts.push({ user: student, schoolName, className: name });
        memberships.push({ _id: student._id, turmaId: classId, ingressouEm: daysAgo(10) });
        activities.push(activity(student, 'diagnostico', 'diagnostico', diagnostic, index % 3 + 1, daysAgo(8)));
        activities.push(activity(student, 'pratica', 'pratica', practice, index + 1, daysAgo(5)));
        if (index === 0) activities.push(activity(student, 'em-andamento', 'pratica', next, 1, daysAgo(1), 0));
      }
    }
  }

  // O material e sua versão vêm do mesmo catálogo usado na tela do aluno.
  const itemsWithStages = activities.filter(trail => trail.tipo === 'pratica').map(trail => [trail, contentStages(trail)]);
  const contentIds = [...new Set(itemsWithStages.flatMap(([, stages]) => stages.map(stage => stage.id)))];
  const materials = await loadStudyMaterials(databases, contentIds);
  assert.equal(materials.size, contentIds.length, 'Subtema sem material publicado.');
  const readings = itemsWithStages.flatMap(([trail, stages]) => stages
    .filter(stage => trail.status === 'concluida' || stage.status === 'disponivel')
    .map(stage => ({
      _id: id(`leitura:${trail._id}:${stage.id}`), usuarioId: trail.usuarioId, trilhaId: trail._id,
      conteudoId: stage.id, materialVersao: materials.get(stage.id).versao,
      criadoEm: trail.criadoEm, leituraConcluidaEm: trail.criadoEm,
    })));
  const oldAccounts = await users.find({
    perfil: 'student', codigoEscola: schools[0][0],
    nome: /\s+\(demo\)$|^Aluno Educacional Demonstração$/i,
  }, { projection: { nome: 1 } }).toArray();

  if (apply) {
    const existing = await users.find({ _id: { $in: accounts.map(({ user }) => user._id) } }).toArray();
    const byId = new Map(existing.map(user => [user._id.toString(), user]));
    const registration = [];
    const access = ['# Acessos da apresentação', '', 'Contas fictícias para entrar pela tela normal do aplicativo.', ''];
    for (const row of accounts) {
      const { user, schoolName, className, code } = row;
      const password = 'Trilha27!' + createHmac('sha256', secret).update(user.email).digest('base64url').slice(0, 16);
      const found = byId.get(user._id.toString());
      if (found) {
        assert.equal(found.email, user.email, 'Identificador de conta em uso.');
        assert(await verifyPassword(password, found.senhaHash), 'Use o mesmo APRESENTACAO_SEGREDO da publicação inicial.');
      } else {
        registration.push(insert({ ...user, senhaHash: await hashPassword(password) }));
      }
      if (code) access.push(`## ${schoolName} · ${className}`, '', `Código da turma: \`${code}\``, '');
      access.push(`- ${user.nome} · \`${user.email}\` · senha \`${password}\``);
    }

    await databases.mongo.withSession(session => session.withTransaction(async () => {
      const write = (collection, rows) => collection.bulkWrite(rows, { session });
      if (registration.length) await write(users, registration);
      if (oldAccounts.length) await write(users, oldAccounts.map(row => ({
        updateOne: {
          filter: { _id: row._id, nome: row.nome },
          update: { $set: { nome: legacyName(row.nome), atualizadoEm: new Date() } },
        },
      })));
      await write(db.collection('escolas'), schools.map(([_id, nome]) => ({
        updateOne: {
          filter: { _id }, update: { $set: { nome, ativa: true }, $unset: { demonstracao: '' } }, upsert: true,
        },
      })));
      for (const [collection, docs] of [
        [db.collection('professores_disciplinas'), teachers],
        [db.collection('turmas'), classes],
        [db.collection('turmas_alunos'), memberships],
        [trails, activities],
        [db.collection('progresso_conteudos'), readings],
      ]) await write(collection, docs.map(insert));
    }));
    await writeFile(accessFile, access.join('\n') + '\n', { mode: 0o600 });
  }

  console.log(JSON.stringify({
    aplicado: apply, escolas: schools.length, turmas: classes.length, professores: teachers.length,
    alunos: students.length, historicos: activities.length, leituras: readings.length, nomesParaAjustar: oldAccounts.length,
  }));
} finally {
  await databases.close();
}
