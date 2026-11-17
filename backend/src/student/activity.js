import { accuracy } from '../school/quartiles.js';

const dayFormat = new Intl.DateTimeFormat('pt-BR', {
  timeZone: 'America/Sao_Paulo',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});
const dayLength = 24 * 60 * 60 * 1000;
const dateKey = value => new Date(value).toISOString().slice(0, 10);

function day(date) {
  // Montamos a chave AAAA-MM-DD com a data de São Paulo, mesmo perto da meia-noite.
  const parts = dayFormat.formatToParts(date);
  const value = type => parts.find(part => part.type === type).value;
  return `${value('year')}-${value('month')}-${value('day')}`;
}

const medals = [
  { id: 'primeiro-passo', nome: 'Primeiro passo', descricao: 'Responda sua primeira questão.', campo: 'respondidas', meta: 1 },
  { id: 'dez-acertos', nome: 'Dez acertos', descricao: 'Acerte dez questões.', campo: 'acertos', meta: 10 },
  { id: 'primeira-trilha', nome: 'Trilha concluída', descricao: 'Conclua uma trilha de conteúdos.', campo: 'trilhas', meta: 1 },
  { id: 'explorador', nome: 'Explorador', descricao: 'Estude três disciplinas diferentes.', campo: 'disciplinas', meta: 3 },
  { id: 'em-ritmo', nome: 'Em ritmo', descricao: 'Estude em três dias seguidos.', campo: 'maiorSequencia', meta: 3 },
  { id: 'pratica-constante', nome: 'Prática constante', descricao: 'Responda cinquenta questões.', campo: 'respondidas', meta: 50 },
];

function collectEvents(trails) {
  const events = [];
  for (const trail of trails) {
    if (trail.modo !== 'normal') continue;

    for (const item of trail.itens) {
      if (item.resposta?.corrigida) events.push({ date: item.resposta.respondidaEm, item });
    }

    if (trail.status === 'concluida' && trail.tipo !== 'diagnostico' && trail.concluidaEm) {
      events.push({ date: trail.concluidaEm });
    }
  }

  return events.sort((a, b) => a.date - b.date);
}

export function summarizeActivity(trails, now = new Date()) {
  const totals = { respondidas: 0, acertos: 0, trilhas: 0, disciplinas: 0, maiorSequencia: 0 };
  const earned = new Map();
  const days = new Map();
  const subjects = new Map();
  let sequence = 0;
  let lastDay = null;

  for (const event of collectEvents(trails)) {
    if (event.item) {
      const key = day(event.date);
      if (!days.has(key)) {
        const difference = lastDay ? Date.parse(key) - Date.parse(lastDay) : 0;
        sequence = difference === dayLength ? sequence + 1 : 1;
        totals.maiorSequencia = Math.max(totals.maiorSequencia, sequence);
        lastDay = key;
      }

      const correct = event.item.resposta.correta;
      count(totals, correct);
      count(bucket(days, key), correct);
      countSubject(subjects, event.item);
      totals.disciplinas = subjects.size;
    } else {
      totals.trilhas++;
    }

    // A medalha usa a data em que a meta foi atingida no histórico. Recalcular
    // a tela ou repetir uma requisição nunca dá XP ou uma medalha a mais.
    for (const medal of medals) {
      if (!earned.has(medal.id) && totals[medal.campo] >= medal.meta) {
        earned.set(medal.id, event.date);
      }
    }
  }

  const today = Date.parse(day(now));
  const week = Array.from({ length: 7 }, (_, index) => {
    const data = dateKey(today - (6 - index) * dayLength);
    return { data, ...(days.get(data) ?? { respondidas: 0, acertos: 0 }) };
  });
  const porDisciplina = [...subjects.entries()]
    .sort(([a], [b]) => a.localeCompare(b, 'pt-BR'))
    .map(([nome, { topicos, ...values }]) => {
      const topics = [...topicos.entries()].map(([topic, counters]) => ({
        nome: topic,
        ...withAccuracy(counters),
      }));
      return { nome, ...withAccuracy(values), topicos: topics };
    });
  const conquistas = medals.map(({ campo, ...medal }) => ({
    ...medal,
    progresso: Math.min(medal.meta, totals[campo]),
    conquistadaEm: earned.get(medal.id) ?? null,
  }));

  return {
    ...totals,
    xp: totals.respondidas * 5 + totals.acertos * 5 + totals.trilhas * 25,
    sequencia: lastDay && today - Date.parse(lastDay) <= dayLength ? sequence : 0,
    semana: week,
    porDisciplina,
    conquistas,
  };
}

function bucket(map, key) {
  if (!map.has(key)) map.set(key, { respondidas: 0, acertos: 0 });
  return map.get(key);
}

function count(counters, correct) {
  counters.respondidas++;
  if (correct) counters.acertos++;
}

function countSubject(subjects, item) {
  const subject = bucket(subjects, item.disciplina);
  subject.topicos ??= new Map();

  count(subject, item.resposta.correta);
  const topic = item.conteudos?.[0] ?? 'Revisão geral';
  count(bucket(subject.topicos, topic), item.resposta.correta);
}

function withAccuracy(counters) {
  return { ...counters, aproveitamento: accuracy(counters.acertos, counters.respondidas) };
}
