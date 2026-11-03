import { test } from 'node:test';
import assert from 'node:assert/strict';
import { planNextTrail, planQuestionCandidates, contentStages, diverseSample, schoolYearSchema } from '../src/trails.js';

const q = (id, disciplina, topic, key = 'A') => ({ id, nome: id, disciplina,
  conteudos: [topic], gabarito: key, alternativaA: 'A', alternativaB: 'B', alternativaC: 'C' });
const source = entries => ({ itens: entries.map(([questaoId, correta]) => ({ questaoId, resposta: { corrigida: true, correta } })) });
const random = () => 0.35;

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
test('ano escolar tem opções fechadas e normaliza o formato legado', () => {
  assert.equal(schoolYearSchema.parse('3º ano'),'3º ano do Ensino Médio');
  assert.equal(schoolYearSchema.parse('6º ano do Ensino Fundamental'),'6º ano do Ensino Fundamental');
  assert.equal(schoolYearSchema.parse('Outro'),'Outro');
  assert.throws(()=>schoolYearSchema.parse('qualquer texto'));
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
