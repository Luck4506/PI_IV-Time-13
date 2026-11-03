# Testar a trilha adaptativa

Abra http://127.0.0.1:5173 e entre como estudante. Você pode usar sua conta ou os acessos fictícios de `.local/ACESSOS_DE_TESTE.md`.

1. Abra **Trilha** na barra inferior.
2. Toque em **Novo diagnóstico de exemplo**.
3. Responda às três questões e avance após cada confirmação.
4. Ao terminar, abra **Ver resultado e trilha**, depois **Abrir minha trilha**.

O painel **Roteiro para testar acertos e erros** também mostra as alternativas abaixo dentro do aplicativo.

| Questão | Assunto | Para acertar | Para errar |
|---|---|---|---|
| `FIS-ENEM-01` — Queda das frutas | Queda livre | A | B |
| `MAT-FUVEST-02` — Vagas de estacionamento | Geometria | C | A |
| `POR-ENEM-03` — Ideologia e internet | Interpretação de texto | D | A |

## Cenário 1: testar reforço após erro

Responda **B, C, D**, nessa ordem. Isso produz um erro na primeira questão e dois acertos.

A próxima trilha terá até seis **conteúdos** em um caminho que alterna os lados. O primeiro retoma **Cinemática, com foco em queda livre**. Os conteúdos relacionados vêm em seguida, usando as relações do grafo; depois entram assuntos complementares. Cada etapa contém material teórico e até três questões de prática.

Abra o primeiro conteúdo, leia o material e toque em **Concluir leitura e liberar prática**. Responda à prática e toque em **Concluir conteúdo → Voltar à trilha**. A etapa fica verde se todas as respostas estiverem corretas; se houver erros, recebe um marcador âmbar **Revisar**, com a quantidade de erros. A próxima etapa é liberada em ambos os casos. As etapas seguintes permanecem bloqueadas; esse bloqueio também é aplicado pela API. Concluir a prática libera o próximo conteúdo mesmo quando há erro: os erros influenciam a próxima trilha.

Ao errar uma questão, sua alternativa fica vermelha com um ícone de erro, e a correta fica verde com um ícone de confirmação. Um painel mostra a resposta marcada, a correta e uma orientação para reler o conteúdo. O destaque só aparece depois que a resposta foi salva. O marcador no mapa usa as respostas persistidas e reaparece ao reabrir a trilha.

Há materiais teóricos de exemplo para queda livre, lançamento vertical e resistência do ar. Os demais conteúdos mostram **Material em preparação**, com espaço para adicionar a teoria depois; a prática já pode ser usada nesses casos.

Para testar erros em mais assuntos, inicie outro diagnóstico de exemplo e use **B, A, A**. A seleção começa pelos conteúdos das dificuldades e inclui conteúdos relacionados, sem repetir uma etapa para o mesmo assunto.

## Cenário 2: testar todos os acertos

Inicie **Novo diagnóstico de exemplo** outra vez e responda **A, C, D**.

A próxima trilha será de exploração, com até seis conteúdos sorteados entre assuntos e disciplinas diferentes. Ela não repete as três questões acabadas de responder. Os exemplos conferidos no teste real incluíram Física, Matemática e Língua Portuguesa. A lista muda a cada geração; reenviar a mesma solicitação retorna a trilha já salva.

## Conferir no MongoDB

Abra o Data Explorer do Atlas, banco `trilha`, coleção **`trilhas`**.

Cada documento contém:

- `usuarioId`: dono da trilha, vinculado a `_id` em `usuarios`.
- `modo`: `normal` ou `exemplo`; os exemplos ficam separados da trilha normal.
- `tipo`: `diagnostico`, `pratica`, `revisao` ou `exploracao`.
- `status`: `em_andamento` ou `concluida`.
- `itens`: IDs das questões, ordem, assunto, motivo da recomendação e resposta salva.
- `itens[].resposta`: alternativa escolhida, gabarito usado na correção, acerto/erro e horário.
- `origemId` e `proximaTrilhaId`: ligação entre a atividade concluída e a trilha gerada.

Uma atividade concluída e sua continuação são documentos separados. As respostas não são sobrescritas, e reenviar a confirmação não duplica a resposta nem gera outra continuação.

A coleção **`progresso_conteudos`** registra a leitura por usuário, trilha e conteúdo. A coleção **`materiais_conteudo`** guarda os materiais publicados. O estado disponível/bloqueado é calculado a partir das respostas em `trilhas`, preservando também o progresso das trilhas antigas.

É possível sair, entrar novamente e continuar da etapa e da prática ainda não concluídas. A aba **Histórico salvo** mostra as atividades anteriores. Na conta fictícia do estudante, os dois primeiros cenários já foram executados e persistidos para inspeção.

O catálogo, os enunciados e as relações ficam no Neo4j, consultado apenas para leitura. Não foram criados ou modificados nós no grafo. As trilhas, referências às questões, respostas e histórico ficam no MongoDB. As cinco questões de Matemática que ainda não possuem gabarito foram preservadas e não entram no sorteio corrigível.

## Ano escolar

O cadastro agora oferece uma seleção única, sem digitação: 6º, 7º, 8º e 9º anos do Ensino Fundamental; 1º, 2º e 3º anos do Ensino Médio; e **Outro**.

## Cadastro educacional de demonstração

No cadastro do aluno, ative **Cadastro educacional** e selecione **Escola Horizonte — Demonstração**. Se desativar, a escola deixa de ser solicitada. Para professor, o cadastro é sempre educacional e o seletor de escola permanece visível.

A opção é preparada no frontend em `lib/src/school_options.dart`, e o documento correspondente está no Atlas, banco `trilha`, coleção `escolas`, código `ESCOLA-DEMO-001`. O campo `usuarios.codigoEscola` registra a escolha; a API informa `cadastroEducacional` a partir do perfil e da presença desse código. Essa declaração não verifica vínculo nem concede acesso a dados de outros usuários.

## Verificação técnica

- `cd backend && npm test`: testes da API, recomendação de conteúdos e desbloqueio sequencial.
- `node --env-file=.env scripts/verify-trails-live.js`, dentro de `backend/`: cenários completos nos bancos reais, com isolamento entre usuários, leitura antes da prática, bloqueios, desbloqueio, retomada, reenvios e conferência de que o catálogo não mudou. Esse comando acrescenta exemplos ao histórico do estudante fictício.
- `.local/VERIFICACAO_TRILHAS.json`: resultado dos cenários já verificados.

Os painéis gerais de XP, conquistas, turmas e relatórios ainda usam os exemplos anteriores. As referências de imagens do catálogo foram mantidas; a hospedagem das imagens continua pendente.
