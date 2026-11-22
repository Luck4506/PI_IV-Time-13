# Backend do Gabariteii

A API em Node.js autentica a conta e consulta os bancos. Cadastro e login chegam por HTTP do Java. As demais operações chegam por TCP do Flutter. Para iniciar a API e abrir o aplicativo, siga o [README principal](../README.md).

## Protocolo TCP

A API escuta em `127.0.0.1:3002` por padrão. O aplicativo abre uma conexão TCP por pedido. O pedido e a resposta são objetos JSON em UTF-8, cada um terminado por uma quebra de linha. O Node recebe mensagens de até 64 KiB e envia respostas de até 8 MiB.

| Campo do pedido | Uso |
| --- | --- |
| `metodo` | Método da rota, como `GET` ou `POST` |
| `caminho` | Caminho da rota, incluindo seus parâmetros de consulta |
| `dados` | Objeto com os campos do pedido, quando a rota usa corpo |
| `token` | Token de sessão nas rotas privadas |

A resposta usa `status` numérico e `corpo` como objeto. O logout retorna status `204` com `corpo` vazio.

## Autenticação HTTP

O Node recebe `POST /api/auth/cadastro` e `POST /api/auth/login` em `127.0.0.1:3001`. Use `AUTH_HTTP_PORT` no Node e `-Dnode.url` no Java para trocar a porta. O Java envia `perfil` e `anoEscolar` numéricos. O Node converte os valores para os formatos usados nas contas já existentes.

Uma sessão é devolvida com `201` no cadastro ou `200` no login. O Java repassa o campo `erro` das recusas `409` e `401`. Quando a conta precisa confirmar o e-mail, a mensagem inclui um código que permite ao Flutter abrir a tela de confirmação sem receber token de sessão. [Contrato do Java](../docs/CONTRATO_SERVIDOR.md)

## Rotas da API

### Conta e disponibilidade

| Método | Rota | Uso |
| --- | --- | --- |
| GET | `/health/live` | Verificar se o processo Node está em execução |
| GET | `/health/ready` | Conferir os bancos e a presença do catálogo oficial |
| GET | `/api/escolas` | Listar as escolas ativas disponíveis no cadastro |
| POST | `/api/auth/cadastro` | Criar a conta e retornar sessão ou confirmação pendente via HTTP do Java |
| POST | `/api/auth/login` | Entrar usando e-mail e senha via HTTP do Java |
| POST | `/api/auth/reenviar-confirmacao` | Solicitar outro código de confirmação |
| POST | `/api/auth/confirmar-email` | Validar o código de confirmação para liberar o próximo login |
| GET, PATCH | `/api/usuarios/me` | Consultar a própria conta ou atualizar os campos permitidos |
| POST | `/api/auth/logout` | Invalidar os tokens da conta |

O cadastro inclui `nome`, `email`, `senha`, `perfil`, `dataNascimento`, `cadastroEducacional` e `termosAceitos`. Para aluno, o ano vai como `0` a `3`. O código da escola acompanha o vínculo educacional. O aluno pode informar `codigoTurma`, e o professor envia `codProfessor`. Se houver código de turma, conta e matrícula são gravadas na mesma transação. [Fluxo de autenticação](../AUTENTICACAO.md)

### Questões e trilhas

| Método | Rota | Uso |
| --- | --- | --- |
| GET | `/api/disciplinas` | Listar disciplinas do catálogo |
| GET | `/api/questoes?limit=20&offset=0` | Listar questões sem gabarito, com limite máximo de 100 por página |
| GET | `/api/questoes/:id` | Abrir uma questão pelo ID |
| POST | `/api/questoes/:id/responder` | Conferir uma alternativa sem gravar a tentativa |
| POST | `/api/trilhas` | Começar diagnóstico ou prática |
| GET | `/api/trilhas` | Consultar as 30 trilhas mais recentes da conta |
| GET | `/api/trilhas/atual` | Retomar a trilha em andamento |
| GET | `/api/trilhas/:id` | Consultar a trilha e as respostas salvas |
| POST | `/api/trilhas/:id/respostas` | Registrar uma resposta e gerar a continuação ao concluir |
| GET | `/api/trilhas/:id/etapas/:etapaId` | Consultar teoria, prática e estado da etapa |
| POST | `/api/trilhas/:id/etapas/:etapaId/leitura` | Registrar a leitura do material publicado |
| POST | `/api/trilhas/:id/gerar` | Retomar a geração da continuação de uma atividade concluída |

Para iniciar uma trilha, envie `tipo` (`diagnostico` ou `pratica`) e uma `chave` de 16 a 100 caracteres. Reutilize a chave se precisar repetir o mesmo pedido. A prática aceita `disciplina` para limitar a seleção ao assunto escolhido. Para gravar uma resposta, envie `questaoId` e `alternativa` pelo endpoint da trilha.

Após um erro, o gerador dá prioridade a conteúdos relacionados e procura questões mais fáceis para começar a revisão. Com todos os acertos, ele procura outros conteúdos e varia as disciplinas. As questões oficiais são abertas na página do caderno indicado pelo catálogo.

### Turmas, atividade e notificações

| Método | Rota | Uso |
| --- | --- | --- |
| GET, POST | `/api/aluno/turma` | Consultar a turma ou entrar com o código de matrícula |
| DELETE | `/api/aluno/turma/:id` | Sair da turma |
| GET | `/api/aluno/atividade` | Consultar XP, medalhas, sequência e desempenho |
| GET | `/api/aluno/notificacoes` | Consultar notificações de conquistas |
| PUT | `/api/aluno/notificacoes/lidas` | Registrar a leitura das notificações |
| PUT | `/api/professor/disciplina` | Definir a disciplina lecionada |
| GET, POST | `/api/professor/turmas` | Listar as próprias turmas ou criar uma turma |
| POST | `/api/professor/turmas/entrar` | Aceitar convite de professor |
| GET | `/api/professor/turmas/:id` | Consultar quartis da disciplina na turma |
| GET | `/api/professor/turmas/:id/alunos/:alunoId` | Consultar os resultados do aluno por conteúdo |
| POST | `/api/professor/turmas/:id/convite` | Gerar convite para outro professor |
| POST | `/api/professor/turmas/:id/codigo` | Renovar o código de matrícula |

As rotas privadas usam o token e conferem a conta ou o perfil nas operações que exigem acesso. Os relatórios do professor consideram as respostas corrigidas na disciplina dele desde a matrícula do aluno.

## Verificação e manutenção

Rode os comandos na pasta `backend/`.

| Comando | O que verifica |
| --- | --- |
| `npm test` | Regras do backend, rotas TCP e contrato HTTP de autenticação |
| `npm run db:check` | Conexão com os bancos e presença do catálogo |
| `npm run db:inventory` | Estrutura dos bancos configurados |
| `npm run db:audit` | Catálogo, relações, materiais e referências gravadas |

Os três comandos de banco só consultam dados. Para publicar o catálogo ou configurar um Neo4j local, veja o [guia dos bancos](../CONFIGURACAO_DOS_BANCOS.md).
