// Autoria de Lucas Soares Gonçalves RA 25009467
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { ObjectId } from 'mongodb';
import neo4j from 'neo4j-driver';
import { diagnosticExamples, selectableQuestion } from '../src/exam-questions.js';
import { recordReading } from '../src/trail-progress.js';
import { planNextTrail, planQuestionCandidates, contentStages, diverseSample, schoolYearSchema, createTrailService } from '../src/trails.js';

const q = (id, disciplina, topic, key = 'A') => ({ id, nome: id, disciplina,
  conteudos: [topic], origem: 'vestibular', banca: 'Prova de teste', caderno: 'Modelo A',
  ano: 2025, numero: 1, paginaProva: 2, provaUrl: 'https://example.test/prova.pdf',
  gabaritoUrl: 'https://example.test/gabarito.pdf', questao: 'Enunciado de teste.',
  gabarito: key, alternativaA: 'A', alternativaB: 'B', alternativaC: 'C', alternativaD: 'D' });
const source = entries => ({ itens: entries.map(([questaoId, correta]) => ({ questaoId, resposta: { corrigida: true, correta } })) });
const random = () => 0.35;

test('novas trilhas aceitam somente questões que podem ser respondidas no app', () => {
  const question = q('INTEGRAL', 'Física', 'Cinemática');
  assert.equal(selectableQuestion(question), true);
  assert.equal(selectableQuestion({ ...question, questao: undefined }), false);
  assert.equal(selectableQuestion({ ...question, alternativaA: 'Alternativa A' }), false);
  assert.equal(selectableQuestion({ ...question, imagens: ['figura.png'] }), false);
  assert.equal(selectableQuestion({ ...question, retirada: true }), false);
});

test('erros priorizam relações reais, cobrem erros distintos e excluem questões já respondidas', () => {
  const catalog = { questions: [q('ERRO1','Matemática','A'),q('ERRO2','Física','B'),
    q('P1','Matemática','C'),q('P2','Física','D'),q('P3','Matemática','E'),q('SEM','Física','X',null)],
    edges: [{de:'ERRO1',para:'P1',tipo:'PARECIDA_COM'}, {de:'P3',para:'ERRO1',tipo:'MESMO_TEMA'},
      {de:'ERRO2',para:'P2',tipo:'MESMO_RACIOCINIO'}] };
  const result = planQuestionCandidates(source([['ERRO1',false],['ERRO2',false]]),catalog,6,random);
  assert.equal(result.tipo,'revisao');
  assert.deepEqual(result.itens.slice(0,2).map(x=>x.questaoId),['P1','P2']);
  assert.equal(new Set(result.itens.map(x=>x.questaoId)).size,result.itens.length);
  assert.ok(result.itens.every(x=>!['ERRO1','ERRO2','SEM'].includes(x.questaoId)));
  assert.deepEqual(result.itens[0].motivo.origens,['ERRO1']);
  assert.deepEqual(result.itens[0].motivo.relacoes,['PARECIDA_COM']);
});
test('100% de acerto gera exploração com disciplinas variadas sem repetir a atividade de origem', () => {
  const questions=[q('ANTIGA','A','0'),...Array.from({length:12},(_,i)=>q(`Q${i}`,['A','B','C'][i%3],`tema${i}`))];
  const result=planNextTrail(source([['ANTIGA',true]]),{questions,edges:[]},6,random);
  assert.equal(result.tipo,'exploracao'); assert.equal(result.itens.length,6);
  assert.equal(new Set(result.itens.map(x=>x.disciplina)).size,3);
  assert.ok(result.itens.every(x=>x.questaoId!=='ANTIGA'&&x.motivo.tipo==='exploracao'));
});
test('não apresenta preenchimento aleatório como relação de reforço e só considera MAIS_FACIL_QUE na direção certa', () => {
  const catalog={questions:[q('ERRO','A','1'),q('FACIL','A','2'),q('DIFICIL','A','3'),q('OUTRA','B','4')],edges:[
    {de:'FACIL',para:'ERRO',tipo:'MAIS_FACIL_QUE'},{de:'ERRO',para:'DIFICIL',tipo:'MAIS_FACIL_QUE'}]};
  const result=planQuestionCandidates(source([['ERRO',false]]),catalog,3,random);
  assert.equal(result.itens[0].questaoId,'FACIL');
  assert.ok(result.itens.slice(1).every(x=>x.motivo.tipo==='complementar'&&x.motivo.origens.length===0));
});
test('amostragem varia com o sorteio e preserva diversidade de temas', () => {
  const pool=Array.from({length:15},(_,i)=>q(`Q${i}`,['A','B','C'][i%3],`tema${i}`));
  const a=diverseSample(pool,6,()=>0.1),b=diverseSample(pool,6,()=>0.8);
  assert.notDeepEqual(a.map(x=>x.id),b.map(x=>x.id));
  assert.equal(new Set(a.map(x=>x.disciplina)).size,3);
});
test('ano escolar aceita os três anos do Ensino Médio e a opção Outro', () => {
  for (const year of [1, 2, 3]) {
    const fullYear = `${year}º ano do Ensino Médio`;
    assert.equal(schoolYearSchema.parse(fullYear), fullYear);
    assert.equal(schoolYearSchema.parse(`${year}º ano`), fullYear);
  }

  assert.equal(schoolYearSchema.parse('Outro'), 'Outro');

  for (const invalid of ['6º ano', '6º ano do Ensino Fundamental', 0, 'qualquer texto']) {
    assert.throws(() => schoolYearSchema.parse(invalid));
  }
});
test('a trilha recomenda conteúdos distintos e mantém a prática dentro de cada conteúdo', () => {
  const catalog={questions:[q('ERRO','Física','Queda livre'),q('OUTRA-QUEDA','Física','Queda livre'),
    q('LANCAMENTO','Física','Lançamento vertical'),q('POR','Português','Interpretação')],
    edges:[{de:'ERRO',para:'LANCAMENTO',tipo:'PARECIDA_COM'}]};
  const plan=planNextTrail(source([['ERRO',false]]),catalog,3,random);
  const stages=contentStages(plan);
  assert.equal(stages[0].nome,'Queda livre');
  assert.deepEqual(stages[0].questaoIds,['ERRO','OUTRA-QUEDA']);
  assert.equal(stages[1].nome,'Lançamento vertical');
  assert.equal(new Set(stages.map(x=>x.id)).size,stages.length);
  assert.deepEqual(stages.map(x=>x.status),['disponivel','bloqueada','bloqueada']);
});
test('etapa só libera a seguinte depois de concluir todas as suas questões, preservando respostas antigas', () => {
  const trail={tipo:'revisao',itens:[
    {questaoId:'A1',disciplina:'Física',conteudos:['Queda'],motivo:{}},
    {questaoId:'B1',disciplina:'Física',conteudos:['Energia'],motivo:{}},
    {questaoId:'A2',disciplina:'Física',conteudos:['Queda'],motivo:{}},
  ]};
  trail.itens[0].resposta={correta:false};
  assert.equal(contentStages(trail)[1].status,'bloqueada');
  trail.itens[2].resposta={correta:true};
  assert.deepEqual(contentStages(trail).map(x=>x.status),['concluida','disponivel']);
  assert.equal(contentStages({...trail,tipo:'diagnostico'}).length,0);
});

test('exploração não reinsere questões já acertadas ao agrupar a prática do mesmo conteúdo', () => {
  const catalog = { questions: [q('FEITA','Física','Queda'), q('NOVA','Física','Queda'), q('ENERGIA','Física','Energia')], edges: [] };
  const plan = planNextTrail(source([['FEITA', true]]), catalog, 2, random);
  assert.ok(plan.itens.every(x => x.questaoId !== 'FEITA'));
  assert.deepEqual(new Set(plan.itens.map(x => x.questaoId)), new Set(['NOVA', 'ENERGIA']));
});

test('a seta MAIS_DIFICIL_QUE também prioriza uma alternativa mais fácil no reforço', () => {
  const missed = { ...q('ERRO', 'Física', 'Circuitos'), dificuldade: 2 };
  const easier = { ...q('FACIL', 'Física', 'Circuitos'), dificuldade: 1 };
  const harder = { ...q('DIFICIL', 'Física', 'Circuitos'), dificuldade: 3 };
  const catalog = {
    questions: [missed, easier, harder],
    edges: [
      { de: 'ERRO', para: 'FACIL', tipo: 'MAIS_DIFICIL_QUE' },
      { de: 'FACIL', para: 'ERRO', tipo: 'MAIS_FACIL_QUE' },
      { de: 'DIFICIL', para: 'ERRO', tipo: 'MAIS_DIFICIL_QUE' },
      { de: 'DIFICIL', para: 'ERRO', tipo: 'PARECIDA_COM' },
    ],
  };

  const activity = source([['ERRO', false]]);
  const candidates = planQuestionCandidates(activity, catalog, 2, random);
  const [first] = candidates.itens;
  assert.equal(first.questaoId, 'FACIL');
  assert.equal(first.motivo.pontuacao, 125);
  assert.deepEqual(first.motivo.relacoes, ['MAIS_FACIL_QUE']);
  const onlyInverse = { ...catalog, edges: catalog.edges.filter(edge => edge.tipo !== 'MAIS_FACIL_QUE') };
  assert.equal(planNextTrail(activity, onlyInverse, 2, random).itens[0].questaoId, 'FACIL');
});

test('questões autorais antigas podem estar no histórico mas saem das novas atividades', () => {
  const old = { ...q('ANTIGA', 'A', 'Tópico'), origem: 'trilha-catalogo-v1', retirada: true };
  const active = q('VESTIBULAR', 'A', 'Tópico');
  const catalog = { questions: [old, active], edges: [] };

  const retry = planNextTrail(source([['ANTIGA', false]]), catalog, 2, random);
  assert.deepEqual(retry.itens.map(item => item.questaoId), ['VESTIBULAR']);
  assert.equal(retry.itens[0].motivo.tipo, 'fundamento');
});

test('uma questão sem caderno e gabarito verificáveis não entra numa trilha nova', () => {
  const catalog = {
    questions: [
      q('FEITA', 'A', 'Tema'),
      { ...q('SEM_FONTE', 'A', 'Tema'), gabaritoUrl: undefined },
      q('OFICIAL', 'A', 'Tema'),
    ],
    edges: [],
  };
  const trail = planNextTrail(source([['FEITA', true]]), catalog, 6, random);
  assert.deepEqual(trail.itens.map(item => item.questaoId), ['OFICIAL']);
});


test('o diagnóstico de exemplo grava referências oficiais com a sequência A C D', async () => {
  const keys = ['A', 'C', 'D'];
  const questions = diagnosticExamples.map((id, index) => q(id, 'A', 'Tema', keys[index]));
  const rows = [];
  const graphCalls = [];
  const databases = {
    trails: {
      async findOne() { return null; },
      async insertOne(trail) { rows.push(trail); },
    },
    async query(cypher, parameters) {
      graphCalls.push({ cypher, parameters });
      if (cypher.includes('AS questao')) {
        return { records: questions.map(question => ({ get: key => ({
          questao: question, conteudos: question.conteudos, disciplinas: [question.disciplina],
        })[key] })) };
      }
      return { records: [] };
    },
  };
  const service = createTrailService(databases, ({ id }) => ({ id }));
  const { trilha } = await service.start(new ObjectId(), {
    modo: 'exemplo', tipo: 'diagnostico', chave: 'diagnostico-de-teste',
  });
  assert.deepEqual(trilha.itens.map(item => item.questaoId), diagnosticExamples);
  assert.deepEqual(trilha.roteiro.map(item => item.correta), keys);
  assert.equal(rows.length, 1);
  assert(rows[0].itens.every(item => !item.questao));
  assert.equal(graphCalls.length, 1);
  assert.match(graphCalls[0].cypher, /UNWIND \$ids/);
  assert.deepEqual(graphCalls[0].parameters.ids, diagnosticExamples);
});

test('abrir uma trilha consulta só os IDs salvos, inclusive os do histórico', async () => {
  const saved = q('ANTIGA', 'Física', 'Cinemática');
  const graphCalls = [];
  const userId = new ObjectId();
  const trail = {
    _id: new ObjectId(),
    usuarioId: userId,
    tipo: 'diagnostico',
    modo: 'normal',
    status: 'em_andamento',
    itens: [
      { questaoId: saved.id, disciplina: saved.disciplina, conteudos: saved.conteudos },
      { questaoId: 'INDISPONIVEL', disciplina: 'Física', conteudos: ['Óptica'] },
    ],
  };
  const databases = {
    trails: {
      async findOne(filter) {
        return filter._id?.equals(trail._id) && filter.usuarioId.equals(userId) ? trail : null;
      },
    },
    async query(cypher, parameters) {
      graphCalls.push({ cypher, parameters });
      const fields = { questao: { ...saved, retirada: true }, conteudos: saved.conteudos, disciplinas: [saved.disciplina] };
      return { records: [{ get: field => fields[field] }] };
    },
  };
  const service = createTrailService(databases, ({ id }) => ({ id }));

  await assert.rejects(service.get(trail._id.toString(), new ObjectId()), { status: 404 });
  assert.equal(graphCalls.length, 0);

  const { trilha, proximaTrilha } = await service.get(trail._id.toString(), userId);
  assert.equal(proximaTrilha, null);
  assert.deepEqual(trilha.itens.map(item => item.questao?.id ?? null), ['ANTIGA', null]);
  assert.equal(graphCalls.length, 1);
  assert.match(graphCalls[0].cypher, /UNWIND \$ids/);
  assert.deepEqual(graphCalls[0].parameters.ids, ['ANTIGA', 'INDISPONIVEL']);
});

test('respostas concorrentes atualizam a mesma questão só uma vez', async () => {
  const userId = new ObjectId();
  const question = q('Q1', 'Física', 'Cinemática');
  let trail = {
    _id: new ObjectId(),
    usuarioId: userId,
    tipo: 'diagnostico',
    modo: 'normal',
    status: 'em_andamento',
    versao: 1,
    itens: [question, q('Q2', 'Física', 'Cinemática')].map(row => ({
      questaoId: row.id,
      disciplina: row.disciplina,
      conteudos: row.conteudos,
    })),
  };
  const gate = Promise.withResolvers();
  let writes = 0;

  const databases = {
    trails: {
      async findOne() { return { ...trail }; },
      async findOneAndUpdate(filter, update) {
        if (++writes === 2) gate.resolve();
        await gate.promise;
        if (filter.versao !== trail.versao) return null;

        trail = { ...trail, ...update.$set, versao: trail.versao + update.$inc.versao };
        return trail;
      },
    },
    async query() {
      const fields = {
        questao: question,
        conteudos: question.conteudos,
        disciplinas: [question.disciplina],
      };
      return { records: [{ get: field => fields[field] }] };
    },
  };

  const service = createTrailService(databases, ({ id }) => ({ id }));
  const answer = () => service.answer(trail._id.toString(), question.id, 'A', userId);
  const [first, second] = await Promise.all([answer(), answer()]);

  assert.equal(trail.versao, 2);
  assert.equal(first.trilha.respondidas, 1);
  assert.deepEqual(second.resposta, first.resposta);
  await assert.rejects(service.answer(trail._id.toString(), question.id, 'B', userId), { status: 409 });
});

test('material do Neo4j aparece em blocos e usa o progresso de leitura já salvo', async () => {
  const question = q('Q1', 'Física', 'Cinemática');
  const trail = {
    _id: new ObjectId(),
    usuarioId: new ObjectId(),
    tipo: 'revisao',
    itens: [{ questaoId: question.id, disciplina: question.disciplina, conteudos: question.conteudos }],
  };
  const [{ id: stageId }] = contentStages(trail);
  let savedReading = { conteudoId: stageId, materialVersao: 1 };
  const graphMaterial = {
    id: stageId,
    titulo: 'Cinemática',
    versao: neo4j.int(1),
    titulosBlocos: ['Conceito', 'Antes da prática'],
    textosBlocos: ['Descreva o movimento.', 'Escolha um referencial.'],
  };
  const databases = {
    trails: { async findOne() { return trail; } },
    async query(cypher, { ids }) {
      if (cypher.includes('AS material')) {
        assert.deepEqual(ids, [stageId]);
        return { records: [{ get: () => graphMaterial }] };
      }

      const fields = { questao: question, conteudos: question.conteudos, disciplinas: [question.disciplina] };
      return { records: [{ get: field => fields[field] }] };
    },
    db: {
      collection(name) {
        assert.equal(name, 'progresso_conteudos');
        return {
          find() { return { async toArray() { return [savedReading]; } }; },
          async updateOne(filter, update) {
            savedReading = { conteudoId: filter.conteudoId, materialVersao: update.$max.materialVersao };
          },
        };
      },
    },
  };
  const service = createTrailService(databases, ({ id }) => ({ id }));
  const openStage = markRead => service.stage(trail._id.toString(), stageId, trail.usuarioId, markRead);

  const { etapa } = await openStage();
  assert.equal(etapa.praticaDisponivel, true);
  assert.deepEqual(etapa.material, {
    titulo: 'Cinemática', versao: 1,
    blocos: [
      { titulo: 'Conceito', texto: 'Descreva o movimento.' },
      { titulo: 'Antes da prática', texto: 'Escolha um referencial.' },
    ],
  });

  graphMaterial.versao = neo4j.int(2);
  assert.equal((await openStage()).etapa.praticaDisponivel, false);
  assert.equal((await openStage(true)).etapa.praticaDisponivel, true);
  assert.deepEqual(savedReading, { conteudoId: stageId, materialVersao: 2 });
});

test('uma confirmação de leitura atrasada preserva a versão mais recente', async () => {
  let savedVersion = 0;
  const trail = { _id: new ObjectId(), usuarioId: new ObjectId() };
  const updates = [];
  const databases = {
    db: {
      collection(name) {
        assert.equal(name, 'progresso_conteudos');
        return {
          async updateOne(filter, update) {
            updates.push(filter);
            savedVersion = Math.max(savedVersion, update.$max.materialVersao);
          },
        };
      },
    },
  };
  const material = { _id: 'conteudo', blocos: [{ texto: 'Teoria' }] };

  await recordReading(databases, trail, { ...material, versao: 2 });
  await recordReading(databases, trail, { ...material, versao: 1 });

  assert.deepEqual(updates[0], updates[1]);
  assert.equal(savedVersion, 2);
});
