// Cada referência traz o caderno, o número, a página do PDF, o gabarito e a dificuldade.
// Os níveis 1 a 3 são uma classificação pedagógica do Trilha.
export const linguagens = [
  ["POR", "Língua Portuguesa", [
    ["INT", "Interpretação de texto",
      "Localize o trecho que sustenta sua leitura. Diferencie informação explícita, inferência e efeito de sentido produzido pelo gênero.", [
        ["puc", 1, 3, "D", 1],
        ["unesp", 2, 3, "B", 1],
        ["puc", 6, 4, "C", 2],
        ["unicamp", 37, 14, "D", 2],
        ["enem1", 20, 9, "C", 3],
        ["unicamp", 40, 15, "B", 3],
      ]],
    ["COE", "Coesão textual",
      "Identifique o referente dos pronomes e a relação estabelecida pelo conectivo. Releia o trecho anterior para confirmar o sentido.", [
        ["unesp", 20, 9, "E", 1],
        ["fuvest", 11, 6, "D", 2],
        ["puc", 5, 4, "B", 3],
      ]],
    ["LIT", "Literatura brasileira",
      "Relacione narrador, tema e forma ao contexto da obra. Compare o modo como textos de épocas diferentes tratam problemas semelhantes.", [
        ["puc", 9, 4, "A", 1],
        ["unesp", 9, 5, "C", 2],
        ["unicamp", 42, 16, "C", 2],
        ["fuvest", 82, 30, "D", 3],
      ]],
  ]],
  ["ING", "Inglês", [
    ["LEI", "Interpretação de textos em inglês",
      "Leia o comando antes do texto. Localize a evidência e diferencie a ideia principal de exemplos e dados complementares.", [
        ["unesp", 21, 9, "A", 1],
        ["puc", 16, 6, "B", 1],
        ["enem1", 4, 3, "A", 2],
        ["unesp", 23, 9, "D", 2],
        ["unicamp", 17, 8, "C", 3],
        ["unicamp", 21, 9, "D", 3],
      ]],
    ["VOC", "Vocabulário e inferência em inglês",
      "Use as palavras vizinhas, o gênero do texto e a função da frase para deduzir o sentido de expressões desconhecidas.", [
        ["unesp", 26, 10, "E", 1],
        ["puc", 14, 6, "D", 2],
        ["unesp", 30, 11, "C", 2],
        ["unesp", 28, 10, "B", 3],
        ["fuvest", 41, 18, "C", 3],
      ]],
  ]],
];
