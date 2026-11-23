// Autoria de Lucas Soares Gonçalves RA 25009467
const similarityWeights = {
  PARECIDA_COM: 100,
  MESMO_RACIOCINIO: 80,
  MESMO_TEMA: 60,
  MESMO_TEXTO_BASE: 40,
};

export const relationTypes = [...Object.keys(similarityWeights), 'MAIS_FACIL_QUE', 'MAIS_DIFICIL_QUE'];

export function edgesByQuestion(edges) {
  const index = new Map();
  for (const edge of edges) {
    for (const id of new Set([edge.de, edge.para])) {
      if (!index.has(id)) index.set(id, []);
      index.get(id).push(edge);
    }
  }
  return index;
}

export function compareToMissed(candidateId, missedId, edges, sameContent) {
  const relations = new Set();
  let harder = false;

  for (const edge of edges) {
    const direct = edge.de === candidateId && edge.para === missedId;
    const inverse = edge.para === candidateId && edge.de === missedId;
    if (!direct && !inverse) continue;

    if (Object.hasOwn(similarityWeights, edge.tipo)) {
      relations.add(edge.tipo);
    } else if ((edge.tipo === 'MAIS_FACIL_QUE' && direct) ||
               (edge.tipo === 'MAIS_DIFICIL_QUE' && inverse)) {
      // As duas setas descrevem o mesmo par. Conta só uma vez.
      relations.add('MAIS_FACIL_QUE');
    } else if (edge.tipo === 'MAIS_FACIL_QUE' || edge.tipo === 'MAIS_DIFICIL_QUE') {
      harder = true;
    }
  }

  const easier = relations.has('MAIS_FACIL_QUE');
  const score = [...relations].reduce((total, type) =>
    total + (similarityWeights[type] ?? 90), sameContent ? 35 : 0);

  return { relations: [...relations], score, order: easier ? 0 : harder ? 2 : 1 };
}
