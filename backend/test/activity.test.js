import assert from 'node:assert/strict';
import { test } from 'node:test';
import { summarizeActivity } from '../src/student/activity.js';
import { groupByQuartile } from '../src/school/quartiles.js';

test('quartis exigem cinco questões distintas e mantêm empates juntos', () => {
  const student = (id, acertos, respondidas, questoesDistintas = respondidas) => ({
    id, acertos, respondidas, questoesDistintas,
  });
  const students = [
    student('lowest', 0, 5),
    student('first-tie', 2, 6),
    student('second-tie', 3, 9),
    student('higher', 3, 6),
    student('highest', 5, 5),
    student('four-questions', 4, 4),
    student('repeated-questions', 7, 10, 2),
    student('no-data', 0, 0),
  ];

  const { quartis, semRespostas, abaixoDoMinimo, amostraInsuficiente } = groupByQuartile(students);
  assert.deepEqual(quartis.map(q => q.alunos.map(row => row.id)), [
    ['lowest'], ['first-tie', 'second-tie'], ['higher'], ['highest'],
  ]);
  assert.deepEqual(semRespostas.map(row => row.id), ['no-data']);
  assert.deepEqual(abaixoDoMinimo.map(row => row.id), ['four-questions', 'repeated-questions']);
  assert.equal(amostraInsuficiente.length, 0);

  const small = groupByQuartile([...students.slice(0, 3), ...students.slice(5)]);
  assert.equal(small.amostraInsuficiente.length, 3);
  assert.equal(small.abaixoDoMinimo.length, 2);
  assert(small.quartis.every(q => q.alunos.length === 0));

  const enough = groupByQuartile(students.slice(0, 4));
  assert.equal(enough.amostraInsuficiente.length, 0);
  assert.equal(enough.quartis.flatMap(quartile => quartile.alunos).length, 4);
});

test('conquistas vêm do histórico normal e respeitam a virada de dia de São Paulo', () => {
  const answer = (date, correta, disciplina) => ({
    disciplina, conteudos: ['Tópico'],
    resposta: { corrigida: true, correta, respondidaEm: new Date(date) },
  });
  const trails = [
    {
      modo: 'normal', tipo: 'pratica', status: 'concluida',
      concluidaEm: new Date('2026-11-10T03:05:00Z'),
      itens: [
        answer('2026-11-09T02:59:00Z', true, 'Física'),
        answer('2026-11-09T03:01:00Z', false, 'Matemática'),
        answer('2026-11-10T03:04:00Z', true, 'Geografia'),
      ],
    },
    {
      modo: 'exemplo', tipo: 'diagnostico',
      itens: [answer('2026-11-11T03:01:00Z', true, 'História')],
    },
  ];
  const data = summarizeActivity(trails, new Date('2026-11-10T13:00:00Z'));
  assert.equal(data.xp, 50);
  assert.equal(data.trilhas, 1);
  assert.equal(data.sequencia, 3);
  assert.equal(data.respondidas, 3);
  assert.equal(data.semana.at(-1).respondidas, 1);
  assert.equal(data.porDisciplina.find(x => x.nome === 'Matemática').aproveitamento, 0);
  assert.equal(data.conquistas.find(x => x.id === 'em-ritmo').conquistadaEm.toISOString(), '2026-11-10T03:04:00.000Z');
  assert.equal(data.conquistas.find(x => x.id === 'dez-acertos').conquistadaEm, null);
  assert.equal(summarizeActivity(trails, new Date('2026-11-12T13:00:00Z')).sequencia, 0);
});

test('as seis medalhas destravam no histórico normal e a meta de cinquenta tem limite exato', () => {
  const subjects = ['Matemática', 'Física', 'Química'];
  const trails = subjects.map((disciplina, index) => {
    const date = new Date(Date.UTC(2026, 10, 8 + index, 14));
    return {
      modo: 'normal', tipo: 'pratica', status: 'concluida', concluidaEm: date,
      itens: Array.from({ length: index === 2 ? 16 : 17 }, () => ({
        disciplina, conteudos: ['Tema'],
        resposta: { correta: true, corrigida: true, respondidaEm: date },
      })),
    };
  });
  const now = new Date('2026-11-10T18:00:00Z');
  const activity = summarizeActivity(trails, now);
  assert.equal(activity.conquistas.length, 6);
  assert(activity.conquistas.every(medal => medal.conquistadaEm && medal.progresso === medal.meta));
  assert.equal(activity.xp, 575);

  trails[2].itens.pop();
  const beforeThreshold = summarizeActivity(trails, now);
  assert.deepEqual(beforeThreshold.conquistas.filter(medal => !medal.conquistadaEm)
    .map(medal => [medal.id, medal.progresso]), [['pratica-constante', 49]]);
});
