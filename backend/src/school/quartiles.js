const labels = [
  'Q1 · Menor desempenho',
  'Q2 · Faixa intermediária inferior',
  'Q3 · Faixa intermediária superior',
  'Q4 · Maior desempenho',
];

export const MIN_QUESTIONS_FOR_QUARTILES = 5;
export const MIN_STUDENTS_FOR_QUARTILES = 4;

export function groupByQuartile(students) {
  const quartis = labels.map((nome, index) => ({ numero: index + 1, nome, alunos: [] }));
  const semRespostas = [];
  const abaixoDoMinimo = [];
  const ranked = [];

  for (const student of students) {
    if (student.respondidas === 0) {
      semRespostas.push(student);
    } else if (student.questoesDistintas >= MIN_QUESTIONS_FOR_QUARTILES) {
      ranked.push(student);
    } else {
      abaixoDoMinimo.push(student);
    }
  }

  // A turma precisa ter quatro alunos que já atingiram o mínimo individual.
  if (ranked.length < MIN_STUDENTS_FOR_QUARTILES) {
    return { quartis, semRespostas, abaixoDoMinimo, amostraInsuficiente: ranked };
  }

  ranked.sort(compareScore);
  let start = 0;
  while (start < ranked.length) {
    let end = start + 1;
    while (end < ranked.length && compareScore(ranked[start], ranked[end]) === 0) {
      end++;
    }

    // Alunos empatados ficam juntos no quartil da posição média do grupo.
    const percentile = (start + end) / (2 * ranked.length);
    const index = Math.min(3, Math.floor(percentile * 4));
    quartis[index].alunos.push(...ranked.slice(start, end));
    start = end;
  }

  return { quartis, semRespostas, abaixoDoMinimo, amostraInsuficiente: [] };
}

function compareScore(a, b) {
  return a.acertos * b.respondidas - b.acertos * a.respondidas;
}

export function accuracy(acertos, respondidas) {
  return respondidas ? Math.round(100 * acertos / respondidas) : null;
}
