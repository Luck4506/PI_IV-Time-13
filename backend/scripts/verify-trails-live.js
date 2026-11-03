import assert from 'node:assert/strict';
import { randomUUID, createHash } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { createDatabases } from '../src/databases.js';
import { readConfig } from '../src/config.js';
import { loadCatalog, answerKey } from '../src/trails.js';
const db=createDatabases(readConfig());
const base='http://127.0.0.1:3000';
const accounts=JSON.parse(await readFile('../.local/test-accounts.json','utf8'));
const report={checkedAt:new Date().toISOString(),checks:{}};
async function call(path,method='GET',body,token){
  const r=await fetch(base+path,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},...(body?{body:JSON.stringify(body)}:{})});
  return {status:r.status,data:await r.json()};
}
async function login(account){const r=await call('/api/auth/login','POST',{email:account.email,senha:account.senha,perfil:account.perfil});assert.equal(r.status,200);return r.data.token;}
const fingerprint=c=>createHash('sha256').update(JSON.stringify({questions:c.questions.map(q=>JSON.stringify(q)).sort(),edges:c.edges.map(x=>JSON.stringify(x)).sort()})).digest('hex');
try{
  const before=await loadCatalog(db);
  const token=await login(accounts[0]);
  const other=await login(accounts[1]);
  const scenarios=[];
  for(const mistakes of [true,false]){
    const key=randomUUID();
    const starts=await Promise.all([1,2].map(()=>call('/api/trilhas','POST',{modo:'exemplo',tipo:'diagnostico',chave:key},token)));
    const start=starts[0]; assert.equal(starts[1].status,201);assert.equal(starts[1].data.trilha.id,start.data.trilha.id);
    assert.equal(start.status,201);const original=start.data.trilha;
    assert.equal(original.itens.length,3);assert.equal(original.roteiro.length,3);
    assert.ok(original.itens.every(x=>!x.questao.gabarito));
    const replay=await call('/api/trilhas','POST',{modo:'exemplo',tipo:'diagnostico',chave:key},token);
    assert.equal(replay.data.trilha.id,original.id);
    assert.equal((await call(`/api/trilhas/${original.id}`,'GET',undefined,other)).status,404);
    assert.equal((await call(`/api/trilhas/${original.id}/gerar`,'POST',{},token)).status,409);
    assert.equal((await call(`/api/trilhas/${original.id}/respostas`,'POST',{
      questaoId:original.itens[1].questaoId,alternativa:'A'},token)).status,409);
    let last;
    for(let i=0;i<3;i++){
      const step=original.roteiro[i];
      const alternativa=mistakes&&i===0?step.incorreta:step.correta;
      const body={questaoId:step.questaoId,alternativa};
      assert.equal((await call(`/api/trilhas/${original.id}/respostas`,'POST',{...body,correta:true},token)).status,400);
      const concurrent=await Promise.all(Array.from({length:i===2?2:1},()=>call(`/api/trilhas/${original.id}/respostas`,'POST',body,token)));
      const response=concurrent[0];
      if(i===2){assert.equal(concurrent[1].status,200);assert.equal(concurrent[1].data.proximaTrilha.id,response.data.proximaTrilha.id);}
      assert.equal(response.status,200);last=response.data;
      const duplicate=await call(`/api/trilhas/${original.id}/respostas`,'POST',body,token);
      assert.equal(duplicate.status,200);assert.equal(duplicate.data.trilha.respondidas,i+1);
      const different=step.correta===alternativa?step.incorreta:step.correta;
      assert.equal((await call(`/api/trilhas/${original.id}/respostas`,'POST',{questaoId:step.questaoId,alternativa:different},token)).status,409);
      if(i===0){
        const fresh=await login(accounts[0]);
        const resumed=await call(`/api/trilhas/${original.id}`,'GET',undefined,fresh);
        assert.equal(resumed.data.trilha.respondidas,1);
      }
    }
    assert.equal(last.trilha.status,'concluida');assert.equal(last.trilha.acertos,mistakes?2:3);
    const next=last.proximaTrilha;assert.ok(next);assert.equal(next.tipo,mistakes?'revisao':'exploracao');
    assert.equal(next.etapas.length,6);assert.equal(new Set(next.itens.map(x=>x.questaoId)).size,next.itens.length);
    if(mistakes){assert.equal(next.etapas[0].nome,'Cinemática, com foco em queda livre');assert.equal(next.itens[0].motivo.tipo,'fundamento');}
    else {
      assert.ok(next.itens.every(x=>!original.itens.some(y=>y.questaoId===x.questaoId)));
      assert.equal(new Set(next.itens.map(x=>x.disciplina)).size,3);
    }
    if(mistakes){
      const [first,second]=next.etapas;
      const stagePath=`/api/trilhas/${next.id}/etapas/${first.id}`;
      assert.equal(first.status,'disponivel');assert.equal(first.materialPublicado,true);
      assert.equal(first.leituraConcluida,false);assert.equal(first.praticaDisponivel,false);
      assert.ok(next.etapas.slice(1).every(x=>x.status==='bloqueada'));
      assert.equal((await call(`/api/trilhas/${next.id}/etapas/${second.id}`,'GET',undefined,token)).status,403);
      assert.equal((await call(`/api/trilhas/${next.id}/etapas/${second.id}/leitura`,'POST',{},token)).status,403);
      assert.equal((await call(`/api/trilhas/${next.id}/respostas`,'POST',{questaoId:second.questaoIds[0],alternativa:'A'},token)).status,403);
      const practice={questaoId:first.questaoIds[0],alternativa:'A'};
      assert.equal((await call(`/api/trilhas/${next.id}/respostas`,'POST',practice,token)).status,409);
      assert.equal((await call(stagePath,'GET',undefined,other)).status,404);
      assert.equal((await call(stagePath+'/leitura','POST',{},other)).status,404);
      const reads=await Promise.all([1,2].map(()=>call(stagePath+'/leitura','POST',{},token)));
      const read=reads[0];assert.equal(reads[1].status,200);
      assert.equal(read.status,200);assert.equal(read.data.etapa.praticaDisponivel,true);
      const fresh=await login(accounts[0]);
      assert.equal((await call(stagePath,'GET',undefined,fresh)).data.etapa.leituraConcluida,true);
      assert.equal(await db.db.collection('progresso_conteudos').countDocuments({trilhaId:new (await import('mongodb')).ObjectId(next.id),conteudoId:first.id}),1);
      let completed;
      for(const id of first.questaoIds){
        const q=before.questions.find(q=>q.id===id);
        completed=await call(`/api/trilhas/${next.id}/respostas`,'POST',{questaoId:id,alternativa:answerKey(q)},token);
        assert.equal(completed.status,200);
      }
      assert.equal(completed.data.trilha.etapas[0].status,'concluida');
      assert.equal(completed.data.trilha.etapas[1].status,'disponivel');
      assert.ok(completed.data.trilha.etapas.slice(2).every(x=>x.status==='bloqueada'));
      assert.equal((await call(`/api/trilhas/${next.id}/etapas/${second.id}`,'GET',undefined,fresh)).status,200);
    }
    // Finish every content, exercising both theory and honest no-material placeholders.
    let finished;
    for(let i=0;i<next.etapas.length;i++){
      const item=next.etapas[i];
      const path=`/api/trilhas/${next.id}/etapas/${item.id}`;
      let opened=await call(path,'GET',undefined,token);assert.equal(opened.status,200);
      if(opened.data.etapa.status==='concluida')continue;
      assert.equal(opened.data.etapa.status,'disponivel');
      if(opened.data.etapa.materialPublicado){
        opened=await call(path+'/leitura','POST',{},token);assert.equal(opened.status,200);
      }else{
        assert.equal(opened.data.etapa.material,null);
        assert.equal(opened.data.etapa.praticaDisponivel,true);
        assert.equal((await call(path+'/leitura','POST',{},token)).status,409);
      }
      for(const id of item.questaoIds){
        const q=before.questions.find(q=>q.id===id);
        const key=answerKey(q);
        const wrong=['A','B','C','D','E'].find(x=>x!==key&&q[`alternativa${x}`]);
        finished=await call(`/api/trilhas/${next.id}/respostas`,'POST',{
          questaoId:id,alternativa:mistakes&&i===1?wrong:key},token);
        assert.equal(finished.status,200);
      }
      assert.equal(finished.data.trilha.etapas[i].status,'concluida');
      assert.ok(finished.data.trilha.etapas.slice(i+2).every(x=>x.status==='bloqueada'));
    }
    assert.equal(finished.data.trilha.status,'concluida');
    assert.equal(finished.data.trilha.etapasConcluidas,next.etapas.length);
    assert.equal(finished.data.proximaTrilha.tipo,mistakes?'revisao':'exploracao');
    if(mistakes)assert.equal(finished.data.proximaTrilha.etapas[0].id,next.etapas[1].id);
    const regenerated=await Promise.all([call(`/api/trilhas/${original.id}/gerar`,'POST',{},token),call(`/api/trilhas/${original.id}/gerar`,'POST',{},token)]);
    assert.ok(regenerated.every(x=>x.data.proximaTrilha.id===next.id));
    assert.equal(await db.trails.countDocuments({origemId:new (await import('mongodb')).ObjectId(original.id)}),1);
    const stored=await db.trails.findOne({_id:new (await import('mongodb')).ObjectId(original.id)});
    assert.equal(stored.itens.filter(x=>x.resposta).length,3);
    assert.ok(stored.itens.every(x=>!x.questao));
    scenarios.push({scenario:mistakes?'um_erro':'todos_acertos',sourceId:original.id,nextId:next.id,tipo:next.tipo,
      respostas:original.roteiro.map((x,i)=>({questaoId:x.questaoId,correta:x.correta,respondida:mistakes&&i===0?x.incorreta:x.correta})),
      conteudosGerados:next.etapas.map(x=>({id:x.id,nome:x.nome,disciplina:x.disciplina,status:x.status,motivo:x.motivo}))});
  }
  report.checks={twoScenarios:true,serverGrades:true,mongoPersistence:true,resumeAfterLogin:true,ownerIsolation:true,
    cannotOverwriteAnswer:true,idempotentStartAndContinuation:true,diverseSubjectsOnAllCorrect:true,
    contentStages:true,completeContentTrail:true,concurrentStartAnswerAndReading:true,noMaterialPlaceholder:true,theoryBeforePractice:true,sequentialLocksEnforcedByServer:true,readingPersisted:true,
    graphUnchanged:fingerprint(before)===fingerprint(await loadCatalog(db))};
  assert.equal(report.checks.graphUnchanged,true);report.scenarios=scenarios;report.status='ok';
  await writeFile('../.local/VERIFICACAO_TRILHAS.json',JSON.stringify(report,null,2));
  console.log(JSON.stringify(report,null,2));
}finally{await db.close()}
