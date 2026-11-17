import { createHash, randomBytes } from 'node:crypto';
import { ObjectId } from 'mongodb';
import { ApiError } from '../api-error.js';
import { examOrigin, examQuestionFilter } from '../exam-questions.js';

export const classCodePattern = /^[A-F0-9]{12}$/;
const newCode = () => randomBytes(6).toString('hex').toUpperCase();
const hashCode = code => createHash('sha256').update(code).digest('hex');

export function classView(turma, teacherId) {
  const teaching = turma.docentes.find(row => row.professorId.equals(teacherId));

  return {
    id: turma._id.toString(),
    nome: turma.nome,
    codigo: turma.codigo,
    disciplina: teaching.disciplina,
    podeConvidarProfessor: turma.criadoPor.equals(teacherId),
  };
}

export function createClassService(databases) {
  const classes = databases.db.collection('turmas');
  const members = databases.db.collection('turmas_alunos');
  const subjects = databases.db.collection('professores_disciplinas');
  const schools = databases.db.collection('escolas');

  async function getTeachingClass(id, teacher) {
    if (!ObjectId.isValid(id)) throw new ApiError(404, 'Turma não encontrada.');
    const turma = await classes.findOne({
      _id: new ObjectId(id),
      codigoEscola: teacher.codigoEscola ?? null,
      'docentes.professorId': teacher._id,
    });

    if (!turma) throw new ApiError(404, 'Turma não encontrada.');
    return turma;
  }

  async function teachingSubject(teacher) {
    const saved = await subjects.findOne({ _id: teacher._id });
    return saved?.disciplina ?? null;
  }

  async function checkTeacherSchool(teacher) {
    const school = teacher.codigoEscola
      ? await schools.findOne({ _id: teacher.codigoEscola, ativa: true })
      : null;

    if (!school) throw new ApiError(403, 'Sua conta precisa estar vinculada a uma escola ativa.');
  }

  async function requireSubject(teacher) {
    await checkTeacherSchool(teacher);
    const subject = await teachingSubject(teacher);
    if (!subject) throw new ApiError(409, 'Defina sua disciplina antes de acessar uma turma.');
    return subject;
  }

  async function enrollmentTarget(code, schoolCode) {
    const turma = await classes.findOne({ codigo: code });
    if (!turma || (schoolCode && turma.codigoEscola !== schoolCode)) {
      throw new ApiError(404, 'Código de turma inválido para sua escola.');
    }
    return turma;
  }

  async function enroll(turma, student, session) {
    const filter = { _id: student._id, turmaId: turma._id };
    const update = { $setOnInsert: { ingressouEm: new Date() } };

    // A matrícula usa o ID do aluno como chave, então só há uma turma por aluno.
    try {
      await members.updateOne(filter, update, { upsert: true, session });
    } catch (error) {
      if (error.code !== 11000) throw error;

      // No cadastro, o conflito precisa interromper a transação inteira.
      if (session) throw new ApiError(409, 'Este aluno já está em outra turma.');

      // Um reenvio para a turma em que o aluno já entrou pode ser confirmado.
      const current = await members.findOne({ _id: student._id });
      if (!turma._id.equals(current?.turmaId)) {
        throw new ApiError(409, 'Este aluno já está em outra turma.');
      }
    }
  }

  async function studentClass(student) {
    const enrollment = await members.findOne({ _id: student._id });
    if (!enrollment) return null;

    const turma = await classes.findOne({ _id: enrollment.turmaId });
    if (!turma) return null;

    return {
      id: turma._id.toString(),
      nome: turma.nome,
      codigoEscola: turma.codigoEscola,
      disciplinas: [...new Set(turma.docentes.map(row => row.disciplina))].sort(),
      ingressouEm: enrollment.ingressouEm,
    };
  }

  return {
    getTeachingClass,
    teachingSubject,
    enrollmentTarget,
    enroll,
    studentClass,

    async list(teacher) {
      const turmas = await classes.find({
        codigoEscola: teacher.codigoEscola ?? null,
        'docentes.professorId': teacher._id,
      }).sort({ nome: 1, _id: 1 }).toArray();
      return turmas.map(turma => classView(turma, teacher._id));
    },

    async chooseSubject(teacher, disciplina) {
      await checkTeacherSchool(teacher);
      const result = await databases.query(
        `MATCH (q:Questao)-[:ABORDA]->(:Conteudo)-[:FAZ_PARTE_DE]->(d:Disciplina {nome: $disciplina})
          WHERE ${examQuestionFilter} RETURN d.nome AS nome LIMIT 1`,
        { disciplina, examOrigin },
      );
      if (!result.records.length) throw new ApiError(400, 'Escolha uma disciplina do catálogo.');

      // O vínculo é usado nas consultas do professor. A escolha acontece uma vez,
      // porque trocar o nome da matéria no formulário não pode abrir outro relatório.
      try {
        await subjects.updateOne(
          { _id: teacher._id },
          { $setOnInsert: { disciplina, criadoEm: new Date() } },
          { upsert: true },
        );
      } catch (error) {
        if (error.code !== 11000) throw error;
        // Outra escolha pode ter sido gravada enquanto o catálogo era consultado.
      }

      const saved = await teachingSubject(teacher);
      if (saved !== disciplina) throw new ApiError(409, 'Sua disciplina já foi definida.');
      return saved;
    },

    async create(teacher, nome) {
      const disciplina = await requireSubject(teacher);
      const turma = {
        _id: new ObjectId(),
        nome,
        codigoEscola: teacher.codigoEscola,
        codigo: newCode(),
        criadoPor: teacher._id,
        criadoEm: new Date(),
        docentes: [{ professorId: teacher._id, disciplina }],
      };
      await classes.insertOne(turma);
      return classView(turma, teacher._id);
    },

    async joinStudent(student, code) {
      const turma = await enrollmentTarget(code, student.codigoEscola);
      await enroll(turma, student);
      return studentClass(student);
    },

    async leaveStudent(student, id) {
      if (!ObjectId.isValid(id)) throw new ApiError(404, 'Turma não encontrada.');
      await members.deleteOne({ _id: student._id, turmaId: new ObjectId(id) });
    },

    async rotateStudentCode(teacher, id) {
      const turma = await getTeachingClass(id, teacher);
      if (!turma.criadoPor.equals(teacher._id)) {
        throw new ApiError(403, 'Somente quem criou a turma pode renovar seu código.');
      }
      const codigo = newCode();
      await classes.updateOne({ _id: turma._id }, { $set: { codigo } });
      return codigo;
    },

    async inviteTeacher(teacher, id) {
      const turma = await getTeachingClass(id, teacher);
      if (!turma.criadoPor.equals(teacher._id)) {
        throw new ApiError(403, 'Somente quem criou a turma pode convidar professores.');
      }
      const codigo = newCode();
      const expiraEm = new Date(Date.now() + 24 * 60 * 60 * 1000);
      await classes.updateOne({ _id: turma._id }, {
        $set: { conviteProfessor: { hash: hashCode(codigo), expiraEm } },
      });
      return { codigo, expiraEm };
    },

    async joinTeacher(teacher, code) {
      const disciplina = await requireSubject(teacher);

      const invitation = {
        codigoEscola: teacher.codigoEscola,
        'conviteProfessor.hash': hashCode(code),
        'conviteProfessor.expiraEm': { $gt: new Date() },
        'docentes.professorId': { $ne: teacher._id },
      };
      const changes = {
        $push: { docentes: { professorId: teacher._id, disciplina } },
        $unset: { conviteProfessor: '' },
      };

      // Inserir o professor e consumir o convite faz parte da mesma atualização.
      const turma = await classes.findOneAndUpdate(invitation, changes, { returnDocument: 'after' });

      if (!turma) throw new ApiError(404, 'Convite inválido, vencido ou já utilizado.');
      return classView(turma, teacher._id);
    },
  };
}

export async function initializeClasses(databases) {
  const classes = databases.db.collection('turmas');
  const members = databases.db.collection('turmas_alunos');

  await classes.createIndex({ codigo: 1 }, { unique: true, name: 'codigo_da_turma' });
  await classes.createIndex(
    { codigoEscola: 1, 'docentes.professorId': 1 }, { name: 'turmas_do_professor' },
  );
  await classes.createIndex({ 'conviteProfessor.hash': 1 }, { sparse: true, name: 'convite_docente' });
  await members.createIndex({ turmaId: 1 }, { name: 'alunos_da_turma' });
}
