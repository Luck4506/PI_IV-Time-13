// Autoria de Lucas Soares Gonçalves RA 25009467
export const examOrigin = 'vestibular';
export const retiredAuthorOrigin = 'trilha-catalogo-v1';

export const ANSWER_LETTERS = ['A', 'B', 'C', 'D', 'E'];

export function answerKey(question) {
  const value = question.gabarito ?? question.gabarito_declarado ?? question.respostaCorreta;
  const key = String(value ?? '').trim().toUpperCase();

  // Um gabarito só serve para correção se a alternativa existir no catálogo.
  return ANSWER_LETTERS.includes(key) && question[`alternativa${key}`] ? key : null;
}

// Usamos os mesmos campos mínimos no catálogo público e nas novas trilhas.
// O histórico busca as questões gravadas pelo ID, incluindo as antigas.
const options = '[q.alternativaA, q.alternativaB, q.alternativaC, q.alternativaD, q.alternativaE]';

export const examQuestionFilter = `
  q.origem = $examOrigin AND coalesce(q.retirada, false) = false
  AND q.provaUrl STARTS WITH 'https://' AND q.gabaritoUrl STARTS WITH 'https://'
  AND q.paginaProva > 1 AND q.numero > 0 AND q.ano > 0
  AND trim(q.banca) <> '' AND trim(q.caderno) <> ''
  AND trim(coalesce(q.questao, q.enunciado, '')) <> ''
  AND size(coalesce(q.imagens, [])) = 0
  AND size([opcao IN ${options} WHERE trim(coalesce(opcao, '')) <> '']) >= 2
  AND none(opcao IN ${options} WHERE coalesce(trim(opcao), '') =~ '(?i)alternativa [a-e]')
`;

export const diagnosticExamples = [
  'VEST-ENEM-2018-D2-AZUL-Q122',
  'VEST-ENEM-2024-D2-AZUL-Q157',
  'VEST-ENEM-2022-D2-AZUL-Q092',
];

export function selectableQuestion(question) {
  return question.origem === examOrigin && question.retirada !== true &&
    isHttps(question.provaUrl) && isHttps(question.gabaritoUrl) &&
    Number(question.paginaProva) > 1 && Number(question.numero) > 0 && Number(question.ano) > 0 &&
    hasText(question.banca) && hasText(question.caderno) &&
    hasInlineText(question);
}

export function hasInlineText(question) {
  const alternatives = ANSWER_LETTERS.map(letter => question[`alternativa${letter}`]).filter(hasText);
  return hasText(question.questao ?? question.enunciado) &&
    !question.imagens?.length && alternatives.length >= 2 &&
    alternatives.every(text => !/^alternativa [a-e]$/i.test(text.trim()));
}

function hasText(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isHttps(value) {
  return typeof value === 'string' && value.startsWith('https://');
}

export async function countExamQuestions(databases) {
  const result = await databases.query(`
    MATCH (q:Questao) WHERE ${examQuestionFilter}
    RETURN count(q) AS catalogoOficial`, { examOrigin });
  return Number(result.records[0].get('catalogoOficial'));
}
