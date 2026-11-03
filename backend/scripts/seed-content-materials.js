import { MongoClient } from 'mongodb';
import { contentId } from '../src/trails.js';
const mongo = new MongoClient(process.env.MONGODB_URI);
const samples = [
  { nome: 'Cinemática, com foco em queda livre', titulo: 'Queda livre: o que determina o tempo de queda?', blocos: [
    { titulo: 'A ideia principal', texto: 'Na queda livre, desprezamos a resistência do ar e consideramos apenas a ação da gravidade. Perto da superfície da Terra, a aceleração é aproximadamente 9,8 m/s² para baixo.' },
    { titulo: 'Massa e tempo de queda', texto: 'Dois corpos soltos do repouso, da mesma altura e no mesmo instante, chegam juntos ao chão quando a resistência do ar é desprezada. Nesse modelo, a massa não determina o tempo de queda.' },
    { titulo: 'Como resolver', texto: 'Para um corpo solto do repouso de uma altura h, use h = g·t²/2, ou t = √(2h/g). Confira sempre se a altura inicial, a velocidade inicial e as hipóteses do problema são iguais para os corpos comparados.' },
  ] },
  { nome: 'Cinemática, lançamento vertical e queda livre', titulo: 'Lançamento vertical e altura máxima', blocos: [
    { titulo: 'Subida e descida', texto: 'Um objeto lançado para cima diminui sua velocidade durante a subida. Na altura máxima, a velocidade instantânea é zero, mas a aceleração da gravidade continua apontando para baixo.' },
    { titulo: 'Equações úteis', texto: 'Adotando o sentido positivo para cima: v = v₀ − g·t e y = y₀ + v₀·t − g·t²/2. No ponto mais alto, v = 0. Essas equações pressupõem resistência do ar desprezível e gravidade aproximadamente constante.' },
  ] },
  { nome: 'Dinâmica, com foco nas Leis de Newton e na força de resistência do ar', titulo: 'Forças na queda com resistência do ar', blocos: [
    { titulo: 'Quais forças atuam?', texto: 'Durante a descida, o peso atua para baixo e a resistência do ar atua no sentido oposto ao movimento. A força resultante determina a aceleração por Fresultante = m·a.' },
    { titulo: 'Velocidade terminal', texto: 'Se a resistência do ar igualar o peso, a resultante será zero e a velocidade permanecerá constante. Isso não significa ausência de forças; significa que elas se equilibram.' },
  ] },
];
try {
  const collection = mongo.db(process.env.MONGODB_DATABASE).collection('materiais_conteudo');
  for (const sample of samples) {
    const disciplina = 'Física';
    await collection.updateOne({ _id: contentId(disciplina, sample.nome) }, { $setOnInsert: {
      ...sample, disciplina, versao: 1, publicado: true, origem: 'Material inicial de demonstração', atualizadoEm: new Date(),
    } }, { upsert: true });
  }
  console.log('Três materiais introdutórios preparados. Materiais existentes foram preservados.');
} finally { await mongo.close(); }
