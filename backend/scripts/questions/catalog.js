// Autoria de Lucas Soares Gonçalves RA 25009467
import assert from 'node:assert/strict';
import { examOrigin } from '../../src/exam-questions.js';
import { cadernos } from './cadernos.js';
import { exatas } from './exatas.js';
import { humanas } from './humanas.js';
import { linguagens } from './linguagens.js';

export const edition = 'trilha-vestibulares-v1';
const letters = ['A', 'B', 'C', 'D', 'E'];

export function makeCatalog() {
  const topics = [];
  const ids = new Set();

  for (const [prefix, subject, topicRows] of [...exatas, ...humanas, ...linguagens]) {
    for (const [code, name, theory, questions] of topicRows) {
      const id = `VEST-TOPICO-${prefix}-${code}`;
      assert(theory && questions.length >= 3, `Conteúdo incompleto: ${id}`);
      const rows = questions.map(reference => {
        const row = questionFromReference(subject, name, reference);
        assert(!ids.has(row.id), `Questão repetida: ${row.id}`);
        ids.add(row.id);
        return row;
      });
      topics.push({ id, subject, name, theory, rows });
    }
  }

  return topics;
}

function questionFromReference(subject, name, [booklet, number, page, answer, difficulty]) {
  const book = cadernos[booklet];
  assert(book, `Caderno desconhecido: ${booklet}`);
  const id = questionId(book, number);
  assert(Number.isInteger(number) && number >= book.min && number <= book.max, id);
  assert(Number.isInteger(page) && page > 1 && page <= book.pages, id);
  assert(Number.isInteger(difficulty) && difficulty >= 1 && difficulty <= 3, id);
  const alternatives = letters.slice(0, book.options);
  assert(alternatives.includes(answer), `Gabarito inválido: ${id}`);
  assert(new URL(book.paper).protocol === 'https:' && new URL(book.key).protocol === 'https:', id);

  // O PDF original traz texto, figuras e opções. Guardamos a referência
  // e as letras para corrigir a resposta sem copiar o caderno inteiro.
  const options = Object.fromEntries(alternatives.map(letter => [`alternativa${letter}`, `Alternativa ${letter}`]));
  return {
    id,
    nome: name,
    disciplina: subject,
    banca: book.board,
    ano: book.year,
    caderno: booklet === 'enem1' && number <= 5 ? book.name + ' · Inglês' : book.name,
    numero: number,
    provaUrl: book.paper,
    paginaProva: page,
    gabaritoUrl: book.key,
    gabarito: answer,
    dificuldade: difficulty,
    dificuldadeOrigem: 'curadoria-trilha',
    origem: examOrigin,
    lote: edition,
    ...options,
  };
}

function questionId(book, number) {
  return `VEST-${book.code}-${book.year}-${book.version}-Q${String(number).padStart(3, '0')}`;
}

export function catalogRelations(topics) {
  const sameTopic = [];
  const difficulty = [];

  for (const { rows } of topics) {
    for (const [index, first] of rows.entries()) {
      for (const second of rows.slice(index + 1)) {
        sameTopic.push([first.id, second.id].sort());
        if (first.dificuldade === second.dificuldade) continue;
        const [easy, hard] = first.dificuldade < second.dificuldade ? [first, second] : [second, first];
        difficulty.push({ easy: easy.id, hard: hard.id });
      }
    }
  }

  // Nestes pares a habilidade é mais próxima do que o nome do conteúdo sugere.
  const closePairs = [
    [['enem2', 157], ['enem2', 177]],
    [['unicamp', 49], ['puc', 19]],
    [['enem2', 131], ['enem2', 132]],
    [['puc', 42], ['unesp', 72]],
    [['fuvest', 30], ['puc', 48]],
    [['unesp', 33], ['unesp', 34]],
    [['enem1', 53], ['unicamp', 6]],
    [['fuvest', 7], ['unesp', 59]],
    [['unesp', 21], ['puc', 16]],
  ];
  const similar = closePairs.map(pair => pair.map(([book, number]) => questionId(cadernos[book], number)).sort());
  const pairs = new Set(sameTopic.map(pair => pair.join('|')));
  assert(similar.every(pair => pairs.has(pair.join('|'))), 'Par de similaridade fora do tema');

  // São pares revisados pelo tipo de raciocínio, inclusive entre conteúdos.
  const reasoning = [
    [['puc', 24], ['unicamp', 9], 'Relacionar distância percorrida e duração para obter a velocidade.'],
    [['unesp', 82], ['unicamp', 13], 'Obter corrente a partir de potência e tensão.'],
    [['unicamp', 48], ['unicamp', 51], 'Contar resultados favoráveis lidando com interseções de conjuntos.'],
    [['unicamp', 51], ['enem2', 180], 'Separar resultados em casos conforme o número de elementos de cada tipo.'],
    [['enem2', 137], ['fuvest', 45], 'Relacionar soma, quantidade de observações e média aritmética.'],
    [['puc', 1], ['unesp', 2], 'Inferir uma informação a partir das pistas do narrador.'],
    [['puc', 31], ['unesp', 40], 'Interpretar fontes sobre as disputas políticas brasileiras de 1964.'],
  ].map(([first, second, reason]) => {
    const [from, to] = [first, second].map(([book, number]) => questionId(cadernos[book], number)).sort();
    return { from, to, reason };
  });
  const ids = new Set(topics.flatMap(topic => topic.rows.map(row => row.id)));
  assert(reasoning.every(pair => ids.has(pair.from) && ids.has(pair.to)), 'Par sem questão publicada');

  return { sameTopic, difficulty, similar, reasoning };
}
