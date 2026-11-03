import { ObjectId } from 'mongodb';
import { randomInt, createHash } from 'node:crypto';
import { z } from 'zod';

export const SCHOOL_YEARS = [
  '6º ano do Ensino Fundamental', '7º ano do Ensino Fundamental',
  '8º ano do Ensino Fundamental', '9º ano do Ensino Fundamental',
  '1º ano do Ensino Médio', '2º ano do Ensino Médio', '3º ano do Ensino Médio', 'Outro',
];
export const schoolYearSchema = z.preprocess(value => {
  if (typeof value !== 'string') return value;
  const text = value.trim();
  const legacy = text.match(/^([1-3]|[6-9])º ano$/);
  if (!legacy) return text;
  return `${text} do Ensino ${Number(legacy[1]) <= 3 ? 'Médio' : 'Fundamental'}`;
}, z.enum(SCHOOL_YEARS));

const LETTERS = ['A', 'B', 'C', 'D', 'E'];
const WEIGHTS = { PARECIDA_COM: 100, MAIS_FACIL_QUE: 90, MESMO_RACIOCINIO: 80, MESMO_TEMA: 60, MESMO_TEXTO_BASE: 40 };
const EXAMPLE_IDS = ['FIS-ENEM-01', 'MAT-FUVEST-02', 'POR-ENEM-03'];
export class TrailError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
export function answerKey(question) {
  const key = String(question.gabarito ?? question.gabarito_declarado ?? question.respostaCorreta ?? '').trim().toUpperCase();
  return LETTERS.includes(key) && question[`alternativa${key}`] ? key : null;
}

export async function loadCatalog(databases) {
  const result = await databases.query(`MATCH (q:Questao)
    OPTIONAL MATCH (q)-[:ABORDA]->(c:Conteudo)
    OPTIONAL MATCH (c)-[:FAZ_PARTE_DE]->(d:Disciplina)
    RETURN properties(q) AS questao, collect(DISTINCT c.nome) AS conteudos,
      collect(DISTINCT d.nome) AS disciplinas ORDER BY questao.id`);
  const questions = result.records.map(r => ({ ...r.get('questao'),
    conteudos: [...r.get('conteudos')].sort(), disciplina: r.get('disciplinas')[0] ?? 'Outros assuntos' }));
  const edges = await databases.query(`MATCH (a:Questao)-[r]->(b:Questao)
    WHERE type(r) IN $types RETURN a.id AS de, b.id AS para, type(r) AS tipo`, { types: Object.keys(WEIGHTS) });
  return { questions, edges: edges.records.map(r => r.toObject()) };
}

function shuffled(items, random) {
  const out = [...items];
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}
const secureRandom = () => randomInt(0, 0x100000000) / 0x100000000;

// Round-robin across subjects, then prefer topics not already selected.
export function diverseSample(pool, count, random = secureRandom) {
  const groups = new Map();
  for (const q of shuffled(pool, random)) {
    if (!groups.has(q.disciplina)) groups.set(q.disciplina, []);
    groups.get(q.disciplina).push(q);
  }
  const subjects = shuffled([...groups.keys()], random);
  const topics = new Set();
  const out = [];
  while (out.length < count && subjects.some(s => groups.get(s).length)) {
    for (const subject of subjects) {
      const items = groups.get(subject);
      if (!items.length || out.length >= count) continue;
      const topic = q => `${q.disciplina}:${q.conteudos[0] ?? q.id}`;
      const index = Math.max(0, items.findIndex(q => !topics.has(topic(q))));
      const [q] = items.splice(index, 1);
      topics.add(topic(q)); out.push(q);
    }
  }
  return out;
}

const itemFor = (q, motivo) => ({ questaoId: q.id, nome: q.nome ?? q.id,
  disciplina: q.disciplina, conteudos: q.conteudos, motivo });

export function planQuestionCandidates(source, catalog, count = 6, random = secureRandom) {
  const valid = catalog.questions.filter(answerKey);
  const sourceIds = new Set(source.itens.map(x => x.questaoId));
  const available = valid.filter(q => !sourceIds.has(q.id));
  const wrong = source.itens.filter(x => x.resposta?.corrigida && !x.resposta.correta);
  if (!wrong.length) {
    const pool = available.length ? available : valid;
    return { tipo: 'exploracao', itens: diverseSample(pool, count, random).map(q => itemFor(q, {
      tipo: 'exploracao', origens: [], relacoes: [], pontuacao: 0,
      descricao: 'Novos assuntos sorteados após acertar todas as questões.',
    })) };
  }
  const selected = [];
  const used = new Set();
  const lists = wrong.map(failed => {
    const original = catalog.questions.find(q => q.id === failed.questaoId);
    return shuffled(available, random).map(q => {
      const relations = catalog.edges.filter(e =>
        e.tipo === 'MAIS_FACIL_QUE'
          ? e.de === q.id && e.para === failed.questaoId
          : (e.de === failed.questaoId && e.para === q.id) || (e.para === failed.questaoId && e.de === q.id));
      const sameContent = original?.conteudos.some(c => q.conteudos.includes(c));
      const score = relations.reduce((sum, r) => sum + (WEIGHTS[r.tipo] ?? 0), 0) + (sameContent ? 35 : 0);
      return { q, failed, score, relations: [...new Set(relations.map(r => r.tipo))], sameContent };
    }).filter(x => x.score > 0).sort((a, b) => b.score - a.score);
  });
  // Each missed question gets a turn; one dense subgraph cannot consume the whole trail.
  while (selected.length < count) {
    let added = false;
    for (const list of lists) {
      const candidate = list.find(x => !used.has(x.q.id));
      if (!candidate || selected.length >= count) continue;
      used.add(candidate.q.id); added = true;
      selected.push(itemFor(candidate.q, {
        tipo: 'reforco', origens: [candidate.failed.questaoId],
        relacoes: candidate.relations.length ? candidate.relations : ['MESMO_CONTEUDO'],
        pontuacao: candidate.score,
        descricao: `Reforço por relação com a questão ${candidate.failed.questaoId}, que você errou.`,
      }));
    }
    if (!added) break;
  }
  const complement = diverseSample(available.filter(q => !used.has(q.id)), count - selected.length, random);
  for (const q of complement) selected.push(itemFor(q, {
    tipo: 'complementar', origens: [], relacoes: [], pontuacao: 0,
    descricao: 'Assunto complementar para variar a prática após as questões de reforço.',
  }));
  if (!selected.length) {
    for (const failed of wrong) {
      const q = valid.find(q => q.id === failed.questaoId);
      if (q && selected.length < count) selected.push(itemFor(q, {
        tipo: 'retomada', origens: [q.id], relacoes: [], pontuacao: 0,
        descricao: 'Retomada da questão: ainda não há outra questão corrigível disponível.',
      }));
    }
  }
  return { tipo: 'revisao', itens: selected };
}

export const contentId = (disciplina, nome) => createHash('sha256').update(`${disciplina}\0${nome}`).digest('hex').slice(0, 24);
const primaryContent = q => q.conteudos?.[0] ?? 'Revisão geral';

// The recommended units are contents. Question IDs stay embedded as practice inside each unit.
export function planNextTrail(source, catalog, count = 6, random = secureRandom) {
  const valid = catalog.questions.filter(answerKey);
  const candidates = planQuestionCandidates(source, catalog, Math.max(count * 4, 6), random);
  const sourceIds = new Set(source.itens.map(x => x.questaoId));
  const unseen = valid.filter(q => !sourceIds.has(q.id));
  const practicePool = candidates.tipo === 'exploracao' && unseen.length ? unseen : valid;
  const foundations = source.itens.filter(x => x.resposta?.corrigida && !x.resposta.correta)
    .map(x => valid.find(q => q.id === x.questaoId)).filter(Boolean).map(q => itemFor(q, {
      tipo: 'fundamento', origens: [q.id], relacoes: ['CONTEUDO_DA_DIFICULDADE'], pontuacao: 300,
      descricao: 'Retome este conteúdo para fortalecer o que ainda precisa de atenção.',
    }));
  const selected = [];
  const seen = new Set();
  for (const candidate of [...foundations, ...candidates.itens]) {
    const q = valid.find(q => q.id === candidate.questaoId);
    if (!q) continue;
    const key = contentId(q.disciplina, primaryContent(q));
    if (seen.has(key) || seen.size >= count) continue;
    seen.add(key);
    const questions = [q, ...practicePool.filter(other => other.id !== q.id &&
      contentId(other.disciplina, primaryContent(other)) === key)].slice(0, 3);
    for (const question of questions) selected.push(itemFor(question, candidate.motivo));
  }
  return { tipo: candidates.tipo, itens: selected };
}

export function contentStages(trail) {
  if (trail.tipo === 'diagnostico') return [];
  const groups = new Map();
  for (const item of trail.itens) {
    const nome = primaryContent(item);
    const id = contentId(item.disciplina, nome);
    if (!groups.has(id)) groups.set(id, { id, nome, disciplina: item.disciplina,
      ordem: groups.size + 1, motivo: item.motivo, questaoIds: [], respondidas: 0 });
    const stage = groups.get(id);
    stage.questaoIds.push(item.questaoId);
    if (item.resposta) stage.respondidas++;
  }
  let previousComplete = true;
  return [...groups.values()].map(stage => {
    const done = stage.respondidas === stage.questaoIds.length;
    const status = done ? 'concluida' : previousComplete ? 'disponivel' : 'bloqueada';
    previousComplete = previousComplete && done;
    return { ...stage, total: stage.questaoIds.length, status };
  });
}

export const trailValidator = { $jsonSchema: {
  bsonType: 'object', additionalProperties: false,
  required: ['_id','usuarioId','tipo','modo','status','versao','itens','criadoEm','atualizadoEm'],
  properties: {
    _id: { bsonType: 'objectId' }, usuarioId: { bsonType: 'objectId' },
    tipo: { enum: ['diagnostico','pratica','revisao','exploracao'] },
    modo: { enum: ['normal','exemplo'] }, status: { enum: ['em_andamento','concluida'] },
    versao: { bsonType: 'int', minimum: 1 }, chave: { bsonType: 'string' },
    origemId: { bsonType: 'objectId' }, proximaTrilhaId: { bsonType: 'objectId' },
    criadoEm: { bsonType: 'date' }, atualizadoEm: { bsonType: 'date' }, concluidaEm: { bsonType: 'date' },
    itens: { bsonType: 'array', minItems: 1, maxItems: 20, items: { bsonType: 'object', additionalProperties: false,
      required: ['questaoId','nome','disciplina','conteudos','motivo'], properties: {
        questaoId: { bsonType: 'string' }, nome: { bsonType: 'string' }, disciplina: { bsonType: 'string' },
        conteudos: { bsonType: 'array', items: { bsonType: 'string' } }, motivo: { bsonType: 'object' },
        resposta: { bsonType: 'object', additionalProperties: false,
          required: ['alternativa','gabarito','correta','corrigida','respondidaEm'], properties: {
            alternativa: { enum: LETTERS }, gabarito: { enum: LETTERS },
            correta: { bsonType: 'bool' }, corrigida: { bsonType: 'bool' }, respondidaEm: { bsonType: 'date' },
          } },
      } } },
  },
} };

export async function initializeTrails(databases) {
  if (!await databases.db.listCollections({ name: 'trilhas' }).hasNext()) {
    await databases.db.createCollection('trilhas', { validator: trailValidator });
  }
  await databases.trails.createIndex({ usuarioId: 1, criadoEm: -1 }, { name: 'historico_por_usuario' });
  await databases.trails.createIndex({ usuarioId: 1, chave: 1 }, {
    name: 'inicio_idempotente', unique: true, partialFilterExpression: { chave: { $type: 'string' } },
  });
  await databases.trails.createIndex({ origemId: 1 }, {
    name: 'uma_continuacao_por_trilha', unique: true, partialFilterExpression: { origemId: { $type: 'objectId' } },
  });
  for (const name of ['materiais_conteudo', 'progresso_conteudos']) {
    if (!await databases.db.listCollections({ name }).hasNext()) await databases.db.createCollection(name);
  }
  await databases.db.collection('progresso_conteudos').createIndex(
    { usuarioId: 1, trilhaId: 1, conteudoId: 1 }, { unique: true, name: 'leitura_por_usuario_etapa' });
}

function summary(trail) {
  const answered = trail.itens.filter(x => x.resposta);
  const stages = contentStages(trail);
  return { id: trail._id.toString(), tipo: trail.tipo, modo: trail.modo, status: trail.status,
    origemId: trail.origemId?.toString(), proximaTrilhaId: trail.proximaTrilhaId?.toString(),
    criadoEm: trail.criadoEm, atualizadoEm: trail.atualizadoEm,
    total: trail.itens.length, respondidas: answered.length,
    totalEtapas: stages.length, etapasConcluidas: stages.filter(x => x.status === 'concluida').length,
    acertos: answered.filter(x => x.resposta.correta).length,
    erros: answered.filter(x => !x.resposta.correta).length };
}

export function createTrailService(databases, questionView) {
  const collection = databases.trails;
  const findOwned = async (id, userId) => {
    if (!ObjectId.isValid(id)) throw new TrailError(404, 'Trilha não encontrada.');
    const trail = await collection.findOne({ _id: new ObjectId(id), usuarioId: userId });
    if (!trail) throw new TrailError(404, 'Trilha não encontrada.');
    return trail;
  };
  const hydrate = async (trail, catalog) => {
    if (!trail) return null;
    const view = { ...summary(trail), itens: trail.itens.map(item => {
      const q = catalog.questions.find(q => q.id === item.questaoId);
      return { ...item, questao: q ? questionView(q) : null };
    }) };
    const stages = contentStages(trail);
    if (stages.length) {
      const [materials, progress] = await Promise.all([
        databases.db.collection('materiais_conteudo').find({ _id: { $in: stages.map(x => x.id) }, publicado: true }).toArray(),
        databases.db.collection('progresso_conteudos').find({ usuarioId: trail.usuarioId, trilhaId: trail._id }).toArray(),
      ]);
      view.etapas = stages.map(stage => {
        const material = materials.find(m => m._id === stage.id);
        const read = progress.find(p => p.conteudoId === stage.id);
        const published = !!material?.blocos?.length;
        const readDone = stage.status === 'concluida' || (!!read && read.materialVersao === material?.versao);
        return { ...stage, materialPublicado: published, leituraConcluida: readDone,
          materialTitulo: published ? material.titulo : 'Material em preparação',
          praticaDisponivel: stage.status !== 'bloqueada' && (!published || readDone) };
      });
      view.totalEtapas = stages.length;
      view.etapasConcluidas = stages.filter(x => x.status === 'concluida').length;
      view.etapaAtualId = stages.find(x => x.status === 'disponivel')?.id ?? null;
    } else { view.etapas = []; view.totalEtapas = 0; view.etapasConcluidas = 0; }
    if (trail.modo === 'exemplo' && trail.tipo === 'diagnostico') {
      view.roteiro = trail.itens.map(item => {
        const q = catalog.questions.find(q => q.id === item.questaoId);
        const correta = q ? answerKey(q) : null;
        return { questaoId: item.questaoId, nome: item.nome, correta,
          incorreta: correta ? LETTERS.find(x => x !== correta && q[`alternativa${x}`]) : null };
      });
    }
    return view;
  };
  const nextFor = (trail, userId) => collection.findOne({ origemId: trail._id, usuarioId: userId });
  const ensureNext = async (source, userId, catalog) => {
    if (source.status !== 'concluida') throw new TrailError(409, 'Responda todas as questões antes de gerar a próxima trilha.');
    let next = await nextFor(source, userId);
    if (!next) {
      const plan = planNextTrail(source, catalog);
      if (!plan.itens.length) throw new TrailError(503, 'Ainda não há questões corrigíveis para a próxima trilha. Suas respostas estão salvas.');
      const now = new Date();
      const candidate = { _id: new ObjectId(), usuarioId: userId, origemId: source._id,
        modo: source.modo, tipo: plan.tipo, status: 'em_andamento', versao: 1,
        itens: plan.itens, criadoEm: now, atualizadoEm: now };
      try { await collection.insertOne(candidate); next = candidate; }
      catch (error) {
        if (error.code !== 11000) throw error;
        next = await nextFor(source, userId);
        if (!next) throw error;
      }
    }
    await collection.updateOne({ _id: source._id, usuarioId: userId }, { $set: { proximaTrilhaId: next._id } });
    source.proximaTrilhaId = next._id;
    return next;
  };
  return {
    async start(userId, { modo, tipo, chave }) {
      const catalog = await loadCatalog(databases);
      const previous = await collection.findOne({ usuarioId: userId, chave });
      if (previous) return { trilha: await hydrate(previous, catalog) };
      const valid = catalog.questions.filter(answerKey);
      const questions = modo === 'exemplo'
        ? EXAMPLE_IDS.map(id => valid.find(q => q.id === id)).filter(Boolean)
        : diverseSample(valid, tipo === 'diagnostico' ? 3 : 6);
      if (!questions.length || (modo === 'exemplo' && questions.length !== EXAMPLE_IDS.length)) {
        throw new TrailError(503, 'As questões corrigíveis necessárias ainda não estão disponíveis.');
      }
      const now = new Date();
      const trail = { _id: new ObjectId(), usuarioId: userId, chave,
        tipo: modo === 'exemplo' ? 'diagnostico' : tipo, modo, status: 'em_andamento', versao: 1,
        itens: questions.map(q => itemFor(q, { tipo: 'inicial', origens: [], relacoes: [], pontuacao: 0,
          descricao: modo === 'exemplo' ? 'Questão do diagnóstico de exemplo.' : 'Questão inicial de um assunto variado.' })),
        criadoEm: now, atualizadoEm: now };
      try { await collection.insertOne(trail); }
      catch (error) {
        if (error.code !== 11000) throw error;
        return { trilha: await hydrate(await collection.findOne({ usuarioId: userId, chave }), catalog) };
      }
      return { trilha: await hydrate(trail, catalog) };
    },
    async list(userId, modo) {
      const rows = await collection.find({ usuarioId: userId, modo }).sort({ criadoEm: -1, _id: -1 }).limit(30).toArray();
      return { trilhas: rows.map(summary) };
    },
    async current(userId, modo) {
      const trail = await collection.findOne({ usuarioId: userId, modo, status: 'em_andamento' }, { sort: { criadoEm: -1, _id: -1 } });
      return { trilha: trail ? await hydrate(trail, await loadCatalog(databases)) : null };
    },
    async get(id, userId) {
      const trail = await findOwned(id, userId);
      const catalog = await loadCatalog(databases);
      return { trilha: await hydrate(trail, catalog), proximaTrilha: await hydrate(await nextFor(trail, userId), catalog) };
    },
    async generate(id, userId) {
      const source = await findOwned(id, userId);
      const catalog = await loadCatalog(databases);
      const next = await ensureNext(source, userId, catalog);
      return { trilha: await hydrate(source, catalog), proximaTrilha: await hydrate(next, catalog) };
    },
    async stage(id, stageId, userId, markRead = false) {
      const trail = await findOwned(id, userId);
      const catalog = await loadCatalog(databases);
      let view = await hydrate(trail, catalog);
      const stage = view.etapas.find(x => x.id === stageId);
      if (!stage) throw new TrailError(404, 'Conteúdo não encontrado nesta trilha.');
      if (stage.status === 'bloqueada') throw new TrailError(403, 'Conclua o conteúdo anterior para liberar esta etapa.');
      const material = await databases.db.collection('materiais_conteudo').findOne({ _id: stageId, publicado: true });
      if (markRead) {
        if (!material?.blocos?.length) throw new TrailError(409, 'Este conteúdo ainda não possui material publicado. A prática já está disponível.');
        const progress = databases.db.collection('progresso_conteudos');
        const filter = { usuarioId: userId, trilhaId: trail._id, conteudoId: stageId };
        const update = { $set: { materialVersao: material.versao, leituraConcluidaEm: new Date() },
          $setOnInsert: { criadoEm: new Date() } };
        try { await progress.updateOne(filter, update, { upsert: true }); }
        catch (error) {
          if (error.code !== 11000) throw error;
          // Two tabs can confirm the same first reading at the same time.
          await progress.updateOne(filter, update);
        }
        view = await hydrate(trail, catalog);
      }
      return { trilha: view, etapa: { ...view.etapas.find(x => x.id === stageId),
        material: material?.blocos?.length ? { titulo: material.titulo, versao: material.versao, blocos: material.blocos } : null } };
    },
    async answer(id, questionId, alternative, userId) {
      const catalog = await loadCatalog(databases);
      let trail;
      let answer;
      for (let attempt = 0; attempt < 3; attempt++) {
        trail = await findOwned(id, userId);
        const index = trail.itens.findIndex(x => x.questaoId === questionId);
        if (index < 0) throw new TrailError(404, 'Esta questão não pertence à sua trilha.');
        const item = trail.itens[index];
        if (item.resposta) {
          if (item.resposta.alternativa !== alternative) throw new TrailError(409, 'A resposta desta questão já foi registrada.');
          answer = item.resposta; break;
        }
        if (trail.tipo === 'diagnostico') {
          if (trail.itens.findIndex(x => !x.resposta) !== index) throw new TrailError(409, 'Responda primeiro a questão atual da trilha.');
        } else {
          const view = await hydrate(trail, catalog);
          const stage = view.etapas.find(x => x.questaoIds.includes(questionId));
          if (!stage || stage.status === 'bloqueada') throw new TrailError(403, 'Conclua o conteúdo anterior para liberar esta etapa.');
          if (!stage.praticaDisponivel) throw new TrailError(409, 'Conclua a leitura do material antes de iniciar a prática.');
          const nextQuestion = stage.questaoIds.find(qid => !trail.itens.find(x => x.questaoId === qid).resposta);
          if (nextQuestion !== questionId) throw new TrailError(409, 'Responda primeiro a questão atual deste conteúdo.');
        }
        const q = catalog.questions.find(q => q.id === questionId);
        if (!q || !answerKey(q)) throw new TrailError(409, 'Esta questão ficou indisponível para correção. Nenhuma resposta foi registrada.');
        if (!q[`alternativa${alternative}`]) throw new TrailError(400, 'Alternativa não disponível nesta questão.');
        answer = { alternativa: alternative, gabarito: answerKey(q), correta: alternative === answerKey(q), corrigida: true, respondidaEm: new Date() };
        const items = trail.itens.map((x, i) => i === index ? { ...x, resposta: answer } : x);
        const done = items.every(x => x.resposta);
        const updated = await collection.findOneAndUpdate({ _id: trail._id, usuarioId: userId, versao: trail.versao }, {
          $set: { itens: items, status: done ? 'concluida' : 'em_andamento', atualizadoEm: answer.respondidaEm,
            ...(done ? { concluidaEm: answer.respondidaEm } : {}) }, $inc: { versao: 1 },
        }, { returnDocument: 'after' });
        if (updated) { trail = updated; break; }
        answer = null;
      }
      if (!answer) throw new TrailError(409, 'A trilha foi atualizada. Recarregue e tente novamente.');
      let next = null;
      let pending = false;
      if (trail.status === 'concluida') {
        try { next = await ensureNext(trail, userId, catalog); }
        catch (error) {
          // Never lose a saved answer because continuation creation failed. /gerar can retry safely.
          console.error('Continuação pendente:', error.name, error.code ?? error.status ?? 'sem_codigo');
          pending = true;
        }
      }
      return { resposta: answer, trilha: await hydrate(trail, catalog), proximaTrilha: await hydrate(next, catalog), proximaPendente: pending };
    },
  };
}

export function mountTrailRoutes(app, auth, databases, questionView) {
  const service = createTrailService(databases, questionView);
  const mode = z.enum(['normal','exemplo']).default('normal');
  const modeQuery = req => mode.parse(req.query.modo);
  app.get('/api/trilhas', auth, async (req, res) => res.json(await service.list(req.user._id, modeQuery(req))));
  app.get('/api/trilhas/atual', auth, async (req, res) => res.json(await service.current(req.user._id, modeQuery(req))));
  app.post('/api/trilhas', auth, async (req, res) => {
    const input = z.object({ modo: mode, tipo: z.enum(['diagnostico','pratica']).default('diagnostico'),
      chave: z.string().min(16).max(100) }).strict().parse(req.body);
    res.status(201).json(await service.start(req.user._id, input));
  });
  app.get('/api/trilhas/:id', auth, async (req, res) => res.json(await service.get(req.params.id, req.user._id)));
  app.get('/api/trilhas/:id/etapas/:etapaId', auth, async (req, res) =>
    res.json(await service.stage(req.params.id, req.params.etapaId, req.user._id)));
  app.post('/api/trilhas/:id/etapas/:etapaId/leitura', auth, async (req, res) => {
    z.object({}).strict().parse(req.body ?? {});
    res.json(await service.stage(req.params.id, req.params.etapaId, req.user._id, true));
  });
  app.post('/api/trilhas/:id/gerar', auth, async (req, res) => {
    z.object({}).strict().parse(req.body ?? {});
    res.json(await service.generate(req.params.id, req.user._id));
  });
  app.post('/api/trilhas/:id/respostas', auth, async (req, res) => {
    const input = z.object({ questaoId: z.string().min(1).max(160), alternativa: z.enum(LETTERS) }).strict().parse(req.body);
    res.json(await service.answer(req.params.id, input.questaoId, input.alternativa, req.user._id));
  });
}
