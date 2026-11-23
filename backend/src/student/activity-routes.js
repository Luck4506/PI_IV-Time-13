// Autoria de Lucas Soares Gonçalves RA 25009467
import { role } from '../auth/session.js';
import { summarizeActivity } from './activity.js';

export function mountActivityRoutes(app, auth, databases) {
  const student = role('student');
  const notices = databases.db.collection('notificacoes_usuario');

  async function loadActivity(usuarioId) {
    const trails = await databases.trails.find(
      { usuarioId, modo: 'normal' },
      {
        projection: {
          modo: 1,
          tipo: 1,
          status: 1,
          concluidaEm: 1,
          'itens.disciplina': 1,
          'itens.conteudos': 1,
          'itens.resposta.corrigida': 1,
          'itens.resposta.correta': 1,
          'itens.resposta.respondidaEm': 1,
        },
      },
    ).toArray();
    return summarizeActivity(trails);
  }

  app.get('/api/aluno/atividade', auth, student, async (req, res) => {
    res.json(await loadActivity(req.user._id));
  });

  app.get('/api/aluno/notificacoes', auth, student, async (req, res) => {
    const [activity, readState] = await Promise.all([
      loadActivity(req.user._id),
      notices.findOne({ _id: req.user._id }),
    ]);

    const notificacoes = activity.conquistas
      .filter(medal => medal.conquistadaEm)
      .sort((a, b) => b.conquistadaEm - a.conquistadaEm)
      .map(medal => ({
        id: medal.id,
        titulo: 'Nova conquista: ' + medal.nome,
        data: medal.conquistadaEm,
        lida: Boolean(readState && medal.conquistadaEm <= readState.lidasAte),
      }));
    res.json({ notificacoes });
  });

  app.put('/api/aluno/notificacoes/lidas', auth, student, async (req, res) => {
    await notices.updateOne(
      { _id: req.user._id },
      { $max: { lidasAte: new Date() } },
      { upsert: true },
    );
    res.status(204).end();
  });
}
