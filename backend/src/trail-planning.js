import { createHash, randomInt } from 'node:crypto';
import { answerKey, selectableQuestion } from './exam-questions.js';
import { compareToMissed, edgesByQuestion } from './question-relations.js';

export { ANSWER_LETTERS, answerKey } from './exam-questions.js';

const secureRandom = () => randomInt(0, 0x100000000) / 0x100000000;
const primaryContent = question => question.conteudos?.[0] ?? 'Revisão geral';

function shuffled(items, random) {
  const result = [...items];

  for (let index = result.length - 1; index > 0; index--) {
    const swapIndex = Math.floor(random() * (index + 1));
    [result[index], result[swapIndex]] = [result[swapIndex], result[index]];
  }

  return result;
}

export function diverseSample(pool, count, random = secureRandom) {
  const groups = new Map();
  for (const question of shuffled(pool, random)) {
    const subject = question.disciplina;
    if (!groups.has(subject)) groups.set(subject, []);
    groups.get(subject).push(question);
  }

  const subjects = shuffled([...groups.keys()], random);
  const usedTopics = new Set();
  const selected = [];
  const topicKey = question => `${question.disciplina}\0${question.conteudos?.[0] ?? question.id}`;

  // Faz uma rodada por disciplina e dá preferência a temas ainda não usados.
  while (selected.length < count && subjects.some(subject => groups.get(subject).length)) {
    for (const subject of subjects) {
      const options = groups.get(subject);
      if (!options.length || selected.length >= count) continue;

      const newTopic = options.findIndex(question => !usedTopics.has(topicKey(question)));
      const [question] = options.splice(Math.max(0, newTopic), 1);
      usedTopics.add(topicKey(question));
      selected.push(question);
    }
  }

  return selected;
}

export function itemFor(question, motivo) {
  return {
    questaoId: question.id,
    nome: question.nome ?? question.id,
    disciplina: question.disciplina,
    conteudos: question.conteudos,
    motivo,
  };
}

function rankedCandidates(available, missed, catalog, random) {
  const questionById = new Map(catalog.questions.map(question => [question.id, question]));
  const edgeIndex = edgesByQuestion(catalog.edges);

  return missed.map(failed => {
    const missedId = failed.questaoId;
    const original = questionById.get(missedId);
    const edges = edgeIndex.get(missedId) ?? [];

    return shuffled(available, random).map(question => {
      const sameSubject = original?.disciplina === question.disciplina;
      const sameContent = sameSubject &&
        original?.conteudos?.some(content => question.conteudos?.includes(content));
      const comparison = compareToMissed(question.id, missedId, edges, sameContent);
      return { question, missedId, ...comparison };
    })
      .filter(candidate => candidate.score > 0)
      .sort((a, b) => a.order - b.order || b.score - a.score);
  });
}

export function planQuestionCandidates(source, catalog, count = 6, random = secureRandom) {
  const valid = catalog.questions.filter(question => selectableQuestion(question) && answerKey(question));
  const sourceIds = new Set(source.itens.map(item => item.questaoId));
  const available = valid.filter(question => !sourceIds.has(question.id));
  const missed = source.itens.filter(item => item.resposta?.corrigida && !item.resposta.correta);

  if (!missed.length) {
    const pool = available.length ? available : valid;
    const itens = diverseSample(pool, count, random).map(question => itemFor(question, {
      tipo: 'exploracao',
      origens: [],
      relacoes: [],
      pontuacao: 0,
      descricao: 'Novos assuntos sorteados após acertar todas as questões.',
    }));
    return { tipo: 'exploracao', itens };
  }

  const selected = [];
  const used = new Set();
  const lists = rankedCandidates(available, missed, catalog, random);

  // Cada erro tem uma vez na rodada. Um tema com muitas relações no grafo
  // não ocupa a trilha inteira enquanto houver sugestões para os outros erros.
  while (selected.length < count) {
    let added = false;

    for (const list of lists) {
      const candidate = list.find(row => !used.has(row.question.id));
      if (!candidate || selected.length >= count) continue;

      used.add(candidate.question.id);
      added = true;
      selected.push(itemFor(candidate.question, {
        tipo: 'reforco',
        origens: [candidate.missedId],
        relacoes: candidate.relations.length ? candidate.relations : ['MESMO_CONTEUDO'],
        pontuacao: candidate.score,
        descricao: `Reforço por relação com a questão ${candidate.missedId}, que você errou.`,
      }));
    }

    if (!added) break;
  }

  const remaining = available.filter(question => !used.has(question.id));
  const complement = diverseSample(remaining, count - selected.length, random);
  for (const question of complement) {
    selected.push(itemFor(question, {
      tipo: 'complementar',
      origens: [],
      relacoes: [],
      pontuacao: 0,
      descricao: 'Assunto complementar para variar a prática após as questões de reforço.',
    }));
  }

  if (!selected.length) {
    for (const failed of missed) {
      const question = valid.find(row => row.id === failed.questaoId);
      if (!question || selected.length >= count) continue;

      selected.push(itemFor(question, {
        tipo: 'retomada',
        origens: [question.id],
        relacoes: [],
        pontuacao: 0,
        descricao: 'Retomada da questão: ainda não há outra questão corrigível disponível.',
      }));
    }
  }

  return { tipo: 'revisao', itens: selected };
}

export function contentId(disciplina, nome) {
  return createHash('sha256').update(`${disciplina}\0${nome}`).digest('hex').slice(0, 24);
}

function missedContent(missed, candidates, valid) {
  // Uma questão mais fácil do mesmo conteúdo pode abrir a revisão.
  const related = candidates.find(item =>
    item.motivo.origens.includes(missed.id) &&
    item.motivo.relacoes.includes('MAIS_FACIL_QUE') &&
    item.disciplina === missed.disciplina &&
    primaryContent(item) === primaryContent(missed));

  if (related) return related;

  const replacement = valid.get(missed.id) ??
    [...valid.values()].find(question =>
      question.disciplina === missed.disciplina && primaryContent(question) === primaryContent(missed));

  if (!replacement) return null;

  return itemFor(replacement, {
    tipo: 'fundamento',
    origens: [missed.id],
    relacoes: ['CONTEUDO_DA_DIFICULDADE'],
    pontuacao: 300,
    descricao: 'Retome este conteúdo para fortalecer o que ainda precisa de atenção.',
  });
}

export function planNextTrail(source, catalog, count = 6, random = secureRandom) {
  const allById = new Map(catalog.questions.map(question => [question.id, question]));
  const valid = catalog.questions.filter(question => selectableQuestion(question) && answerKey(question));
  const validById = new Map(valid.map(question => [question.id, question]));
  const candidates = planQuestionCandidates(source, catalog, Math.max(count * 4, 6), random);
  const sourceIds = new Set(source.itens.map(item => item.questaoId));
  const unseen = valid.filter(question => !sourceIds.has(question.id));
  const practicePool = candidates.tipo === 'exploracao' && unseen.length ? unseen : valid;

  const foundations = source.itens
    .filter(item => item.resposta?.corrigida && !item.resposta.correta)
    .map(item => allById.get(item.questaoId))
    .filter(Boolean)
    .map(missed => missedContent(missed, candidates.itens, validById))
    .filter(Boolean);

  // Separamos as questões de prática por conteúdo antes de montar as etapas.
  const practiceByContent = new Map();
  for (const question of practicePool) {
    const key = contentId(question.disciplina, primaryContent(question));
    if (!practiceByContent.has(key)) practiceByContent.set(key, []);
    practiceByContent.get(key).push(question);
  }

  const selected = [];
  const seen = new Set();
  for (const candidate of [...foundations, ...candidates.itens]) {
    if (seen.size >= count) break;

    const question = validById.get(candidate.questaoId);
    if (!question) continue;

    const key = contentId(question.disciplina, primaryContent(question));
    if (seen.has(key)) continue;

    seen.add(key);
    const practice = (practiceByContent.get(key) ?? []).filter(other => other.id !== question.id);
    practice.sort((a, b) => Number(a.dificuldade ?? 2) - Number(b.dificuldade ?? 2));

    for (const item of [question, ...practice.slice(0, 2)]) {
      selected.push(itemFor(item, candidate.motivo));
    }
  }

  return { tipo: candidates.tipo, itens: selected };
}

export function contentStages(trail) {
  if (trail.tipo === 'diagnostico') return [];

  const groups = new Map();
  for (const item of trail.itens) {
    const nome = primaryContent(item);
    const id = contentId(item.disciplina, nome);

    if (!groups.has(id)) {
      groups.set(id, {
        id,
        nome,
        disciplina: item.disciplina,
        ordem: groups.size + 1,
        motivo: item.motivo,
        questaoIds: [],
        respondidas: 0,
      });
    }

    const stage = groups.get(id);
    stage.questaoIds.push(item.questaoId);
    if (item.resposta) stage.respondidas++;
  }

  let previousComplete = true;
  return [...groups.values()].map(stage => {
    const total = stage.questaoIds.length;
    const done = stage.respondidas === total;
    let status = 'bloqueada';

    if (done) {
      status = 'concluida';
    } else if (previousComplete) {
      status = 'disponivel';
    }

    previousComplete = previousComplete && done;
    return { ...stage, total, status };
  });
}
