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
export const examQuestionFilter = `
  q.origem = $examOrigin AND coalesce(q.retirada, false) = false
  AND q.provaUrl STARTS WITH 'https://' AND q.gabaritoUrl STARTS WITH 'https://'
  AND q.paginaProva > 1 AND q.numero > 0 AND q.ano > 0
  AND trim(q.banca) <> '' AND trim(q.caderno) <> ''
`;

export const diagnosticExamples = [
  'VEST-PUCCAMP-2025-GERAL-Q025',
  'VEST-ENEM-2024-D2-AZUL-Q177',
  'VEST-UNICAMP-2025-F1-QZ-Q037',
];

export function selectableQuestion(question) {
  return question.origem === examOrigin && question.retirada !== true &&
    isHttps(question.provaUrl) && isHttps(question.gabaritoUrl) &&
    Number(question.paginaProva) > 1 && Number(question.numero) > 0 && Number(question.ano) > 0 &&
    hasText(question.banca) && hasText(question.caderno);
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
