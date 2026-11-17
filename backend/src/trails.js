import { ObjectId } from 'mongodb';
import { z } from 'zod';
import { ApiError } from './api-error.js';
import { ANSWER_LETTERS, answerKey, diagnosticExamples, selectableQuestion } from './exam-questions.js';
import { loadCatalog, loadExamQuestions, loadQuestionsById } from './trail-catalog.js';
import { contentStages, diverseSample, itemFor, planNextTrail } from './trail-planning.js';
import { hasMaterial, recordReading, stagesWithProgress } from './trail-progress.js';
import { recentFirst } from './trail-storage.js';

export { answerKey } from './exam-questions.js';
export { contentId, contentStages, diverseSample, planNextTrail, planQuestionCandidates } from './trail-planning.js';
export { loadCatalog } from './trail-catalog.js';
export { SCHOOL_YEAR_CODES, schoolYearSchema } from './auth/account-fields.js';
export { ApiError as TrailError } from './api-error.js';

function summary(trail, stages = contentStages(trail)) {
  const answered = trail.itens.filter(item => item.resposta);
  const correct = answered.filter(item => item.resposta.correta).length;

  return {
    id: trail._id.toString(),
    tipo: trail.tipo,
    modo: trail.modo,
    status: trail.status,
    origemId: trail.origemId?.toString(),
    proximaTrilhaId: trail.proximaTrilhaId?.toString(),
    criadoEm: trail.criadoEm,
    atualizadoEm: trail.atualizadoEm,
    total: trail.itens.length,
    respondidas: answered.length,
    acertos: correct,
    erros: answered.length - correct,
    totalEtapas: stages.length,
    etapasConcluidas: stages.filter(stage => stage.status === 'concluida').length,
  };
}

function createTrail(userId, modo, tipo, itens) {
  const now = new Date();

  return {
    _id: new ObjectId(),
    usuarioId: userId,
    tipo,
    modo,
    status: 'em_andamento',
    versao: 1,
    itens,
    criadoEm: now,
    atualizadoEm: now,
  };
}

export function createTrailService(databases, questionView) {
  const collection = databases.trails;

  async function findOwned(id, userId) {
    if (!ObjectId.isValid(id)) throw new ApiError(404, 'Trilha não encontrada.');

    const trail = await collection.findOne({ _id: new ObjectId(id), usuarioId: userId });
    if (!trail) throw new ApiError(404, 'Trilha não encontrada.');

    return trail;
  }

  function trailQuestions(...trails) {
    const ids = trails.filter(Boolean).flatMap(trail => trail.itens.map(item => item.questaoId));
    return loadQuestionsById(databases, ids);
  }

  async function hydrate(trail, questions) {
    if (!trail) return null;

    const byId = new Map(questions.map(question => [question.id, question]));
    const etapas = await stagesWithProgress(databases, trail);
    const view = {
      ...summary(trail, etapas),
      itens: trail.itens.map(item => {
        const question = byId.get(item.questaoId);
        return { ...item, questao: question ? questionView(question) : null };
      }),
      etapas,
    };

    if (etapas.length) {
      view.etapaAtualId = etapas.find(stage => stage.status === 'disponivel')?.id ?? null;
    }

    if (trail.modo === 'exemplo' && trail.tipo === 'diagnostico') {
      view.roteiro = trail.itens.map(item => {
        const question = byId.get(item.questaoId);
        const correta = question ? answerKey(question) : null;
        const incorreta = correta
          ? ANSWER_LETTERS.find(letter => letter !== correta && question[`alternativa${letter}`])
          : null;

        return { questaoId: item.questaoId, nome: item.nome, correta, incorreta };
      });
    }

    return view;
  }

  async function trailWithContinuation(trail, next, questions) {
    const savedQuestions = questions ?? await trailQuestions(trail, next);
    const [trilha, proximaTrilha] = await Promise.all([
      hydrate(trail, savedQuestions),
      hydrate(next, savedQuestions),
    ]);

    return { trilha, proximaTrilha };
  }

  function nextFor(trail, userId) {
    // O tipo explícito permite que o Mongo use o índice parcial de continuação.
    return collection.findOne({
      origemId: { $eq: trail._id, $type: 'objectId' },
      usuarioId: userId,
    });
  }

  async function createContinuation(source, userId) {
    const missedIds = source.itens
      .filter(item => item.resposta?.corrigida && !item.resposta.correta)
      .map(item => item.questaoId);
    const catalog = await loadCatalog(databases, { relationQuestionIds: missedIds });

    // Uma prática que começou focada em uma disciplina continua nessa matéria.
    const subjects = new Set(source.itens.map(item => item.disciplina));
    if (source.tipo !== 'diagnostico' && subjects.size === 1) {
      catalog.questions = catalog.questions.filter(question => subjects.has(question.disciplina));
    }

    const plan = planNextTrail(source, catalog);
    if (!plan.itens.length) {
      throw new ApiError(503, 'Ainda não há questões corrigíveis para a próxima trilha. Suas respostas estão salvas.');
    }

    const candidate = createTrail(userId, source.modo, plan.tipo, plan.itens);
    candidate.origemId = source._id;

    try {
      await collection.insertOne(candidate);
      return candidate;
    } catch (error) {
      if (error.code !== 11000) throw error;

      // Se outro pedido já salvou a continuação, devolvemos aquela trilha.
      const saved = await nextFor(source, userId);
      if (!saved) throw error;
      return saved;
    }
  }

  async function ensureNext(source, userId) {
    if (source.status !== 'concluida') {
      throw new ApiError(409, 'Responda todas as questões antes de gerar a próxima trilha.');
    }

    const existing = await nextFor(source, userId);
    const next = existing ?? await createContinuation(source, userId);

    if (!next._id.equals(source.proximaTrilhaId)) {
      await collection.updateOne(
        { _id: source._id, usuarioId: userId },
        { $set: { proximaTrilhaId: next._id } },
      );
      source.proximaTrilhaId = next._id;
    }

    return next;
  }

  async function start(userId, { modo, tipo, chave, disciplina }) {
    const request = { usuarioId: userId, chave: { $eq: chave, $type: 'string' } };
    const previous = await collection.findOne(request);
    if (previous) {
      return { trilha: await hydrate(previous, await trailQuestions(previous)) };
    }

    const example = modo === 'exemplo';
    const available = example
      ? await loadQuestionsById(databases, diagnosticExamples)
      : await loadExamQuestions(databases, disciplina);
    const valid = available.filter(question => selectableQuestion(question) && answerKey(question));
    const questions = example
      ? diagnosticExamples.map(id => valid.find(question => question.id === id)).filter(Boolean)
      : diverseSample(valid, tipo === 'diagnostico' ? 3 : 6);

    if (!questions.length || (example && questions.length !== diagnosticExamples.length)) {
      throw new ApiError(503, 'As questões corrigíveis necessárias ainda não estão disponíveis.');
    }

    const itens = questions.map(question => itemFor(question, {
      tipo: 'inicial',
      origens: [],
      relacoes: [],
      pontuacao: 0,
      descricao: example
        ? 'Questão do diagnóstico de exemplo.'
        : 'Questão inicial de um assunto variado.',
    }));
    const trail = createTrail(userId, modo, example ? 'diagnostico' : tipo, itens);
    trail.chave = chave;

    try {
      await collection.insertOne(trail);
    } catch (error) {
      if (error.code !== 11000) throw error;

      const saved = await collection.findOne(request);
      if (!saved) throw error;
      return { trilha: await hydrate(saved, await trailQuestions(saved)) };
    }

    return { trilha: await hydrate(trail, questions) };
  }

  async function stage(id, stageId, userId, markRead = false) {
    const trail = await findOwned(id, userId);
    const stage = contentStages(trail).find(row => row.id === stageId);
    if (!stage) throw new ApiError(404, 'Conteúdo não encontrado nesta trilha.');
    if (stage.status === 'bloqueada') {
      throw new ApiError(403, 'Conclua o conteúdo anterior para liberar esta etapa.');
    }

    const material = await databases.db.collection('materiais_conteudo').findOne({
      _id: stageId,
      publicado: true,
    });
    if (markRead) await recordReading(databases, trail, material);

    const view = await hydrate(trail, await trailQuestions(trail));
    const currentStage = view.etapas.find(row => row.id === stageId);

    return {
      trilha: view,
      etapa: {
        ...currentStage,
        material: hasMaterial(material)
          ? { titulo: material.titulo, versao: material.versao, blocos: material.blocos }
          : null,
      },
    };
  }

  async function checkAnswerOrder(trail, index) {
    if (trail.tipo === 'diagnostico') {
      const nextIndex = trail.itens.findIndex(item => !item.resposta);
      if (nextIndex !== index) {
        throw new ApiError(409, 'Responda primeiro a questão atual da trilha.');
      }
      return;
    }

    const questionId = trail.itens[index].questaoId;
    const stages = await stagesWithProgress(databases, trail);
    const stage = stages.find(row => row.questaoIds.includes(questionId));

    if (!stage || stage.status === 'bloqueada') {
      throw new ApiError(403, 'Conclua o conteúdo anterior para liberar esta etapa.');
    }
    if (!stage.praticaDisponivel) {
      throw new ApiError(409, 'Conclua a leitura do material antes de iniciar a prática.');
    }

    const nextQuestion = trail.itens.find(item => !item.resposta && stage.questaoIds.includes(item.questaoId));
    if (nextQuestion?.questaoId !== questionId) {
      throw new ApiError(409, 'Responda primeiro a questão atual deste conteúdo.');
    }
  }

  async function saveAnswer(id, questionId, alternative, userId) {
    let questions;

    // A versão impede que dois pedidos gravem sobre a mesma cópia da trilha.
    // Se outro pedido gravou antes, relemos a trilha antes de tentar de novo.
    for (let attempt = 0; attempt < 3; attempt++) {
      const trail = await findOwned(id, userId);
      const index = trail.itens.findIndex(item => item.questaoId === questionId);
      if (index < 0) throw new ApiError(404, 'Esta questão não pertence à sua trilha.');

      const previous = trail.itens[index].resposta;
      if (previous) {
        if (previous.alternativa !== alternative) {
          throw new ApiError(409, 'A resposta desta questão já foi registrada.');
        }
        return { trail, answer: previous, questions };
      }

      await checkAnswerOrder(trail, index);
      questions ??= await trailQuestions(trail);
      const question = questions.find(row => row.id === questionId);
      const key = question ? answerKey(question) : null;
      if (!key) {
        throw new ApiError(409, 'Esta questão ficou indisponível para correção. Nenhuma resposta foi registrada.');
      }
      if (!question[`alternativa${alternative}`]) {
        throw new ApiError(400, 'Alternativa não disponível nesta questão.');
      }

      const answer = {
        alternativa: alternative,
        gabarito: key,
        correta: alternative === key,
        corrigida: true,
        respondidaEm: new Date(),
      };
      const itens = [...trail.itens];
      itens[index] = { ...itens[index], resposta: answer };
      const done = itens.every(item => item.resposta);
      const fields = {
        itens,
        status: done ? 'concluida' : 'em_andamento',
        atualizadoEm: answer.respondidaEm,
      };
      if (done) fields.concluidaEm = answer.respondidaEm;

      const updated = await collection.findOneAndUpdate(
        { _id: trail._id, usuarioId: userId, versao: trail.versao },
        { $set: fields, $inc: { versao: 1 } },
        { returnDocument: 'after' },
      );

      if (updated) return { trail: updated, answer, questions };
    }

    throw new ApiError(409, 'A trilha foi atualizada. Recarregue e tente novamente.');
  }

  async function answer(id, questionId, alternative, userId) {
    const saved = await saveAnswer(id, questionId, alternative, userId);
    const { trail } = saved;
    const questions = saved.questions ?? await trailQuestions(trail);
    let next = null;
    let pending = false;

    if (trail.status === 'concluida') {
      try {
        const continuation = await ensureNext(trail, userId);
        questions.push(...await trailQuestions(continuation));
        next = continuation;
      } catch (error) {
        // A resposta já está salva. A rota /gerar permite pedir a continuação de novo.
        console.error('Continuação pendente:', error.name, error.code ?? error.status ?? 'sem_codigo');
        pending = true;
      }
    }

    return {
      resposta: saved.answer,
      ...await trailWithContinuation(trail, next, questions),
      proximaPendente: pending,
    };
  }

  return {
    start,
    stage,
    answer,

    async list(userId, modo) {
      const rows = await collection.find({ usuarioId: userId, modo }).sort(recentFirst).limit(30).toArray();
      return { trilhas: rows.map(trail => summary(trail)) };
    },

    async current(userId, modo) {
      const trail = await collection.findOne(
        { usuarioId: userId, modo, status: 'em_andamento' },
        { sort: recentFirst },
      );

      if (!trail) return { trilha: null };
      return { trilha: await hydrate(trail, await trailQuestions(trail)) };
    },

    async get(id, userId) {
      const trail = await findOwned(id, userId);
      return trailWithContinuation(trail, await nextFor(trail, userId));
    },

    async generate(id, userId) {
      const trail = await findOwned(id, userId);
      return trailWithContinuation(trail, await ensureNext(trail, userId));
    },
  };
}

const modeSchema = z.enum(['normal', 'exemplo']).default('normal');
const startSchema = z.object({
  modo: modeSchema,
  tipo: z.enum(['diagnostico', 'pratica']).default('diagnostico'),
  chave: z.string().min(16).max(100),
  disciplina: z.string().trim().min(1).max(80).optional(),
}).strict().refine(data => !data.disciplina || (data.modo === 'normal' && data.tipo === 'pratica'), {
  message: 'O filtro de disciplina vale para a prática normal.',
  path: ['disciplina'],
});
const answerSchema = z.object({
  questaoId: z.string().min(1).max(160),
  alternativa: z.enum(ANSWER_LETTERS),
}).strict();
const emptyBody = z.object({}).strict();

export function mountTrailRoutes(app, auth, databases, questionView) {
  const service = createTrailService(databases, questionView);

  app.get('/api/trilhas', auth, async (req, res) => {
    const mode = modeSchema.parse(req.query.modo);
    res.json(await service.list(req.user._id, mode));
  });

  app.get('/api/trilhas/atual', auth, async (req, res) => {
    const mode = modeSchema.parse(req.query.modo);
    res.json(await service.current(req.user._id, mode));
  });

  app.post('/api/trilhas', auth, async (req, res) => {
    const input = startSchema.parse(req.body);
    res.status(201).json(await service.start(req.user._id, input));
  });

  app.get('/api/trilhas/:id', auth, async (req, res) => {
    res.json(await service.get(req.params.id, req.user._id));
  });

  app.get('/api/trilhas/:id/etapas/:etapaId', auth, async (req, res) => {
    res.json(await service.stage(req.params.id, req.params.etapaId, req.user._id));
  });

  app.post('/api/trilhas/:id/etapas/:etapaId/leitura', auth, async (req, res) => {
    emptyBody.parse(req.body ?? {});
    res.json(await service.stage(req.params.id, req.params.etapaId, req.user._id, true));
  });

  app.post('/api/trilhas/:id/gerar', auth, async (req, res) => {
    emptyBody.parse(req.body ?? {});
    res.json(await service.generate(req.params.id, req.user._id));
  });

  app.post('/api/trilhas/:id/respostas', auth, async (req, res) => {
    const { questaoId, alternativa } = answerSchema.parse(req.body);
    res.json(await service.answer(req.params.id, questaoId, alternativa, req.user._id));
  });
}
