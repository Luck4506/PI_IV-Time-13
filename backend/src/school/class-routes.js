// Autoria de Lucas Soares Gonçalves RA 25009467
import { z } from 'zod';
import { limitarTentativas } from '../tcp-router.js';
import { role } from '../auth/session.js';
import { classCodePattern } from './classes.js';
import { createClassReports } from './class-report.js';

export const codeField = z.string().trim().toUpperCase().regex(classCodePattern);
const codeBody = z.object({ codigo: codeField }).strict();
const subjectBody = z.object({ disciplina: z.string().trim().min(1).max(80) }).strict();
const classBody = z.object({ nome: z.string().trim().min(2).max(80) }).strict();

export function mountClassRoutes(app, auth, databases, classes) {
  const reports = createClassReports(databases, classes);
  const student = role('student');
  const teacher = role('teacher');
  const limitCodes = limitarTentativas('Muitas tentativas. Aguarde e tente novamente.');

  app.get('/api/aluno/turma', auth, student, async (req, res) => {
    res.json({ turma: await classes.studentClass(req.user) });
  });

  app.post('/api/aluno/turma', auth, student, limitCodes, async (req, res) => {
    const { codigo } = codeBody.parse(req.body);
    res.json({ turma: await classes.joinStudent(req.user, codigo) });
  });

  app.delete('/api/aluno/turma/:id', auth, student, async (req, res) => {
    await classes.leaveStudent(req.user, req.params.id);
    res.status(204).end();
  });

  app.get('/api/professor/turmas', auth, teacher, async (req, res) => {
    const [turmas, disciplina] = await Promise.all([
      classes.list(req.user),
      classes.teachingSubject(req.user),
    ]);
    res.json({ turmas, disciplina });
  });

  app.put('/api/professor/disciplina', auth, teacher, async (req, res) => {
    const { disciplina } = subjectBody.parse(req.body);
    res.json({ disciplina: await classes.chooseSubject(req.user, disciplina) });
  });

  app.post('/api/professor/turmas', auth, teacher, async (req, res) => {
    const { nome } = classBody.parse(req.body);
    res.status(201).json({ turma: await classes.create(req.user, nome) });
  });

  app.post('/api/professor/turmas/entrar', auth, teacher, limitCodes, async (req, res) => {
    const { codigo } = codeBody.parse(req.body);
    res.json({ turma: await classes.joinTeacher(req.user, codigo) });
  });

  app.get('/api/professor/turmas/:id', auth, teacher, async (req, res) => {
    res.json(await reports.report(req.params.id, req.user));
  });

  app.get('/api/professor/turmas/:id/alunos/:alunoId', auth, teacher, async (req, res) => {
    res.json(await reports.student(req.params.id, req.params.alunoId, req.user));
  });

  app.post('/api/professor/turmas/:id/codigo', auth, teacher, async (req, res) => {
    res.json({ codigo: await classes.rotateStudentCode(req.user, req.params.id) });
  });

  app.post('/api/professor/turmas/:id/convite', auth, teacher, async (req, res) => {
    res.json(await classes.inviteTeacher(req.user, req.params.id));
  });
}

export { role } from '../auth/session.js';
