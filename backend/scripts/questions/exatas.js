// Autoria de Lucas Soares Gonçalves RA 25009467
// Cada referência traz o caderno, o número, a página do PDF, o gabarito e a dificuldade.
// Os níveis 1 a 3 são uma classificação pedagógica do Trilha.
export const exatas = [
  ["MAT", "Matemática", [
    ["POR", "Porcentagens",
      "Escolha a base de cada porcentagem. Em reajustes sucessivos, multiplique os fatores de aumento ou redução, porque a base muda a cada etapa.", [
        ["enem2", 153, 20, "D", 1],
        ["enem2", 179, 31, "C", 2],
        ["unicamp", 49, 17, "B", 2],
        ["puc", 17, 7, "B", 3],
        ["puc", 19, 7, "E", 3],
      ]],
    ["FUN", "Função afim",
      "Separe o valor fixo do valor que varia com a quantidade. Para comparar modelos lineares, calcule onde eles se igualam e confira o intervalo pedido.", [
        ["enem2", 156, 21, "B", 1],
        ["enem2", 157, 22, "C", 2],
        ["enem2", 160, 22, "D", 2],
        ["enem2", 177, 31, "C", 3],
      ]],
    ["PRO", "Probabilidade simples",
      "Comece pelo espaço amostral. Em eventos independentes, multiplique as probabilidades; quando há sobreposição, desconte os casos contados duas vezes.", [
        ["unicamp", 48, 17, "A", 2],
        ["enem2", 165, 25, "B", 2],
        ["unicamp", 51, 18, "A", 2],
      ]],
    ["CON", "Análise combinatória",
      "Decida se a ordem importa e se os elementos podem se repetir. Quando as escolhas são divididas em etapas, use o princípio multiplicativo.", [
        ["enem2", 138, 16, "B", 1],
        ["unesp", 85, 30, "A", 3],
        ["enem2", 180, 31, "E", 3],
      ]],
    ["GEO", "Geometria plana",
      "Desenhe as figuras e procure decomposições, semelhança e relações de área. Mantenha as medidas na mesma unidade.", [
        ["enem2", 145, 18, "D", 1],
        ["puc", 21, 8, "D", 2],
        ["unicamp", 55, 18, "B", 3],
        ["enem2", 171, 28, "A", 3],
      ]],
    ["VOL", "Volumes de sólidos",
      "O volume de um cilindro é a área da base multiplicada pela altura. Desenhe a seção do sólido quando houver rotação ou recortes.", [
        ["enem2", 149, 19, "E", 1],
        ["enem2", 175, 30, "D", 2],
        ["fuvest", 75, 28, "A", 3],
        ["unesp", 88, 31, "B", 3],
      ]],
    ["EST", "Médias e leitura de dados",
      "A média aritmética é a soma dividida pelo número de observações. A média ponderada leva em conta os pesos ou frequências de cada valor.", [
        ["enem2", 137, 16, "B", 1],
        ["fuvest", 45, 19, "E", 2],
        ["enem2", 178, 31, "E", 3],
      ]],
  ]],
  ["FIS", "Física", [
    ["MOV", "Cinemática",
      "Identifique trajetória, velocidades e intervalos de tempo. Em um gráfico de velocidade versus tempo, a área com sinal indica o deslocamento.", [
        ["puc", 24, 9, "B", 1],
        ["enem2", 121, 10, "A", 1],
        ["puc", 25, 9, "A", 2],
        ["unicamp", 9, 6, "B", 2],
        ["unesp", 77, 27, "E", 3],
      ]],
    ["ELE", "Circuitos elétricos",
      "Relacione potência, tensão e corrente por P = U · I. Em série, a corrente é a mesma. Verifique os limites dos componentes antes de calcular.", [
        ["unicamp", 13, 7, "A", 1],
        ["unesp", 82, 29, "C", 2],
        ["enem2", 131, 14, "B", 3],
        ["enem2", 132, 14, "B", 3],
      ]],
    ["OND", "Ondas e acústica",
      "A velocidade da onda relaciona frequência e comprimento de onda. Distinguir eco, efeito Doppler e superposição ajuda a escolher o modelo.", [
        ["enem2", 101, 5, "A", 1],
        ["unesp", 81, 28, "E", 2],
        ["enem2", 99, 4, "D", 3],
      ]],
    ["OTI", "Óptica geométrica",
      "Desenhe raios principais e verifique o tipo de imagem. Espelhos, lentes e interfaces desviam raios de formas diferentes.", [
        ["unesp", 80, 28, "B", 1],
        ["fuvest", 22, 10, "E", 2],
        ["enem2", 100, 4, "C", 3],
      ]],
    ["CAL", "Transferência de calor",
      "Identifique condução, convecção e radiação. Em situações práticas, o isolamento diminui a taxa de transferência de calor.", [
        ["enem2", 122, 11, "A", 1],
        ["enem2", 103, 5, "E", 2],
        ["puc", 26, 9, "C", 3],
      ]],
  ]],
  ["QUI", "Química", [
    ["ATO", "Estrutura atômica",
      "Distinga núcleo, elétrons e níveis de energia. O número atômico conta os prótons; transições eletrônicas explicam a emissão de luz.", [
        ["fuvest", 20, 9, "E", 1],
        ["enem2", 125, 12, "C", 2],
        ["unesp", 74, 26, "B", 3],
      ]],
    ["EST", "Estequiometria",
      "Balanceie a reação e converta as quantidades em mol. Use os coeficientes para relacionar reagentes e produtos.", [
        ["fuvest", 73, 28, "A", 3],
        ["unesp", 75, 26, "C", 2],
        ["puc", 44, 16, "B", 3],
        ["enem2", 135, 15, "D", 3],
      ]],
    ["ORG", "Estrutura de compostos orgânicos",
      "Leia a fórmula estrutural contando os átomos e as ligações. Identifique grupos funcionais, como hidroxila, carbonila e amina.", [
        ["enem2", 93, 2, "E", 1],
        ["puc", 42, 15, "C", 2],
        ["unesp", 72, 26, "D", 3],
      ]],
    ["SOL", "Concentração de soluções",
      "Identifique a quantidade de soluto e a base usada no cálculo. Diferencie mol/L, concentração em massa e porcentagem.", [
        ["unesp", 71, 25, "E", 1],
        ["unicamp", 63, 21, "B", 2],
        ["puc", 43, 15, "B", 3],
      ]],
  ]],
  ["BIO", "Biologia", [
    ["EVO", "Evolução e especiação",
      "Seleção natural muda a frequência de características herdáveis em populações. O isolamento pode reduzir o fluxo gênico e favorecer a especiação.", [
        ["enem2", 110, 7, "D", 1],
        ["fuvest", 30, 13, "B", 2],
        ["puc", 48, 17, "A", 2],
        ["unesp", 68, 24, "C", 3],
        ["unicamp", 70, 23, "B", 3],
      ]],
    ["GEN", "Herança genética",
      "Separe o padrão de herança do cálculo de probabilidades. A posição dos genes e o cromossomo em que estão alteram as proporções esperadas.", [
        ["enem2", 112, 7, "B", 1],
        ["unicamp", 67, 22, "C", 2],
        ["unicamp", 72, 23, "D", 3],
      ]],
    ["ECO", "Relações ecológicas",
      "Classifique a interação pelo efeito sobre os organismos. Em cadeias alimentares, acompanhe a transferência de matéria e energia.", [
        ["fuvest", 31, 14, "B", 1],
        ["unesp", 61, 22, "A", 2],
        ["enem2", 108, 6, "B", 3],
      ]],
    ["SAU", "Vírus, vetores e prevenção",
      "Diferencie o agente infeccioso do vetor. Analise a transmissão para entender por que vacinação e controle de vetores atuam em etapas diferentes.", [
        ["enem2", 104, 5, "D", 1],
        ["enem2", 120, 10, "B", 2],
        ["enem2", 126, 12, "A", 3],
        ["unicamp", 68, 22, "C", 3],
      ]],
  ]],
];
