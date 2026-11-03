# Backend Trilha

API Node.js 22+ / Express para o Flutter. As credenciais ficam em `.env`, ignorado pelo Git.

**Integrantes do grupo:** sigam primeiro o [README da raiz](../README.md). Basta colocar o arquivo privado recebido em `backend/.env` e executar `node scripts/iniciar.mjs` na raiz. O iniciador instala as dependências e confere os bancos; o `.env.example` é apenas um modelo sem credenciais reais.

## Separação dos dados

- **MongoDB Atlas M0:** banco `trilha`, coleções `usuarios`, `trilhas`, `materiais_conteudo`, `progresso_conteudos` e `escolas`. A coleção `usuarios` armazena o cadastro: Nome, e-mail normalizado e único, senha protegida com scrypt, perfil, ano escolar ou código da escola e datas. A validação bloqueia campos não previstos. A coleção `trilhas` armazena o usuário, os IDs e a ordem das questões, os motivos da recomendação, as respostas e o histórico. A coleção `escolas` contém a instituição fictícia usada no seletor do cadastro. O catálogo de enunciados e alternativas permanece no Neo4j.
- **Neo4j AuraDB Free:** grafo importado do `Projeto_integrador`, preservando rótulos, propriedades, relacionamentos, índices e restrições do dump. Questões são consultadas somente no grafo.
- No navegador, a sessão dura até 12 horas e usa cookie HttpOnly com SameSite=Strict. Recarregar ou reabrir restaura a mesma conta após confirmação na API, sem armazenar senha ou token no localStorage. Sair revoga as sessões da conta e remove o cookie. O cliente nativo continua usando Bearer em memória e exige login ao reabrir.

## Executar

```sh
cd backend
npm ci
# Na primeira instalação, copie .env.example para .env e configure as duas conexões.
npm run db:init
npm start
```

Não substitua o `.env` já configurado. A API usa `http://127.0.0.1:3000` por padrão. Os bancos estão na nuvem; a API roda neste computador e precisa permanecer aberta durante os testes. Os planos gratuitos podem pausar por inatividade.

Em outro terminal:

```sh
cd frontend
flutter pub get
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5173 --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

O CORS permite somente `localhost:5173` e `127.0.0.1:5173`, conforme `.env`. No Android emulador, use `http://10.0.2.2:3000`; para um aparelho físico, configure o endereço do computador, a escuta de rede e HTTPS de acordo com o ambiente. Não inclua senhas dos bancos no Flutter.

## Rotas

| Método | Rota | Uso |
|---|---|---|
| GET | `/health/live` | API em execução |
| GET | `/health/ready` | Conectividade real com os dois bancos; 503 quando indisponível |
| POST | `/api/auth/cadastro` | Criar conta e iniciar sessão |
| POST | `/api/auth/login` | Autenticar conta existente |
| GET | `/api/usuarios/me` | Ler o próprio cadastro |
| PATCH | `/api/usuarios/me` | Atualizar nome e campo escolar do próprio perfil |
| POST | `/api/auth/logout` | Invalidar sessões da conta |
| GET | `/api/disciplinas` | Disciplinas do grafo |
| GET | `/api/questoes?limit=20&offset=0` | Questões do grafo, sem gabarito; limite máximo 100 |
| GET | `/api/questoes/:id` | Questão pelo ID existente no grafo |
| POST | `/api/questoes/:id/responder` | Conferência avulsa; não registra atividade. Para salvar, use as rotas de trilhas |
| POST | `/api/trilhas` | Iniciar diagnóstico/prática com chave idempotente |
| GET | `/api/trilhas?modo=normal` | Histórico do próprio usuário (30 mais recentes) |
| GET | `/api/trilhas/atual?modo=normal` | Retomar a trilha em andamento |
| GET | `/api/trilhas/:id` | Questões, respostas salvas e continuação de uma trilha própria |
| POST | `/api/trilhas/:id/respostas` | Salvar alternativa e gerar continuação ao concluir |
| GET | `/api/trilhas/:id/etapas/:etapaId` | Conteúdo liberado, material e estado de leitura/prática |
| POST | `/api/trilhas/:id/etapas/:etapaId/leitura` | Confirmar leitura do material publicado; corpo `{}` |
| POST | `/api/trilhas/:id/gerar` | Repetir com segurança a geração de uma atividade concluída |

As rotas de dados exigem cookie de sessão ou `Authorization: Bearer <token>`. O Flutter Web envia cookies com credenciais e o cabeçalho `X-Trilha-Client: app`. Alterações com cookie exigem esse cabeçalho; origens fora da lista são bloqueadas. Respostas da API usam Cache-Control: no-store. Não há endpoint de Cypher livre nem listagem pública de usuários. Cadastro e login possuem limite de tentativas. Dados inválidos retornam 400; autenticação inválida, 401; e-mail repetido, 409.

Cadastro de estudante:

```json
{
  "nome": "Estudante Teste",
  "email": "estudante@example.com",
  "senha": "EscolhaUmaSenhaDeTeste123!",
  "perfil": "student",
  "anoEscolar": "3º ano do Ensino Médio",
  "termosAceitos": true
}
```

Login: `email`, `senha`, `perfil` (`student` ou `teacher`). Neste ambiente local, o cadastro de professor está habilitado para testes. Em novas instalações ele fica desativado por padrão; `ALLOW_TEACHER_REGISTRATION=true` permite experimentá-lo no protótipo. Isso não equivale à verificação de vínculo escolar e não deve ser habilitado em um serviço público sem esse fluxo.

O cadastro também aceita `cadastroEducacional` (booleano) e `codigoEscola`. Quando o indicador é `true`, é necessário escolher uma escola. Para professores, o indicador nunca pode ser `false`. O frontend oferece a escola fictícia `ESCOLA-DEMO-001` como demonstração. A escolha é persistida no campo `usuarios.codigoEscola`; o indicador retornado pela API é derivado desse campo ou do perfil de professor. Não há validação institucional ou novas permissões associadas à escolha. Contas anteriores continuam compatíveis.

Para criar o documento fictício correspondente no Atlas, sem substituir dados existentes:

```sh
node --env-file=.env scripts/seed-school.js
```

O documento fica na coleção `escolas`, com nome **Escola Horizonte — Demonstração** e `demonstracao: true`. As opções do seletor ainda são definidas no frontend, sem um serviço de cadastro de instituições.

Resposta de questão: `{"alternativa":"A"}`. Se o grafo não tiver gabarito válido, a API retorna `corrigida:false`; não inventa gabaritos. A conferência avulsa é mantida por compatibilidade. O aplicativo usa `/api/trilhas/:id/respostas`, com `questaoId` e `alternativa`, para persistir cada resposta antes de exibir o resultado. O painel geral de XP ainda não é calculado. As imagens referenciadas por caminhos locais no grafo ainda precisam de hospedagem própria.

## Testes e verificação

```sh
npm test
npm run db:check
npm run db:inventory
```

Os testes automatizados usam repositórios simulados; `db:check` e `db:inventory` consultam os serviços reais. O primeiro verifica conectividade e o segundo lista rótulos, relacionamentos, restrições e índices.

## Backup e migração

`backups/projeto-integrador/neo4j.dump` contém a cópia do banco local e fica fora do Git. O manifesto `migracao.json` registra origem, destino, checksum SHA-256 e resultado do envio oficial. Guarde uma cópia em local seguro. O banco do Desktop não é removido.

`scripts/migrate-aura.js` exige destino Aura vazio e usa `neo4j-admin database upload`. Ele recusa importar se encontrar nós no destino. Para reutilizá-lo, configure `NEO4J_ADMIN_PATH`, `JAVA_HOME` e as credenciais no `.env`. A senha é passada por variável de ambiente, sem aparecer na linha de comando.

Neste ambiente de testes, o usuário solicitou e confirmou em 28/10/2026 a regra `0.0.0.0/0` no Atlas. Mudanças do IP público não exigem atualizar a lista enquanto essa regra estiver ativa. Autenticação e TLS continuam obrigatórios.

## Trilhas adaptativas

O início recebe `{"tipo":"diagnostico","modo":"normal","chave":"uma-chave-exclusiva-de-pelo-menos-16-caracteres"}`. A chave deve ser reaproveitada ao reenviar a mesma criação. Diagnóstico tem três questões e prática tem até seis, sempre com gabarito válido. `modo: "exemplo"` disponibiliza o roteiro de teste e separa o histórico de exemplos.

Ao concluir uma atividade, a API cria uma única continuação de até seis conteúdos, com até três questões corrigíveis por conteúdo. O conteúdo da dificuldade vem primeiro. Os demais conteúdos são escolhidos a partir das questões relacionadas: Após erros, alterna os candidatos de cada questão errada e pontua relações do grafo: PARECIDA_COM (100), MAIS_FACIL_QUE na direção da questão mais fácil (90), MESMO_RACIOCINIO (80), MESMO_TEMA (60) e MESMO_TEXTO_BASE (40). Conteúdo compartilhado soma 35. Questões complementares são sorteadas quando faltam candidatos relacionados e ficam identificadas como complementares.

Com todos os acertos, sorteia conteúdos a partir de questões com rotação entre disciplinas e preferência por assuntos distintos. Evita repetir as questões da atividade de origem e não duplica IDs dentro da trilha. O Neo4j é consultado exclusivamente em transações de leitura; não há comandos de escrita no grafo.

As respostas são imutáveis após a primeira confirmação, corrigidas no servidor e salvas atomicamente no documento da trilha com controle de versão. Reenvios com a mesma alternativa devolvem o resultado já salvo; outra alternativa retorna 409. Um índice único de origem impede duas continuações para a mesma atividade. Se a geração falhar após salvar a última resposta, `/gerar` permite concluir sem perder os dados. As consultas de trilhas sempre filtram pelo usuário autenticado.

O ano escolar usa opções fechadas do 6º ano ao 3º ano do Ensino Médio, mais Outro. Os formatos antigos de ano são normalizados pela API.

Veja `../TESTAR_TRILHAS.md` para o roteiro B/C/D versus A/C/D. `node --env-file=.env scripts/verify-trails-live.js` verifica os cenários nos bancos reais e salva o relatório em `.local/VERIFICACAO_TRILHAS.json`.

### Material e desbloqueio de conteúdos

`etapas` na resposta da API agrupa os itens por disciplina e conteúdo. Os estados são `disponivel`, `bloqueada` e `concluida`. Somente o primeiro conteúdo incompleto pode ser iniciado. Materiais publicados exigem confirmação de leitura antes da prática. Todas as questões da etapa precisam ser respondidas para liberar a seguinte, independentemente de acertar ou errar. A API valida esses bloqueios, além da interface. Trilhas antigas são agrupadas preservando as respostas.

Os materiais ficam em `materiais_conteudo`, com `_id = contentId(disciplina, nome)` (função exportada em `src/trails.js`), `titulo`, `versao` inteira, `publicado: true` e `blocos: [{titulo, texto}]`. Os nomes devem corresponder aos conteúdos do catálogo. A leitura fica em `progresso_conteudos`, identificada por usuário, trilha e conteúdo, com a versão lida. Ao atualizar um material, incremente a versão.

`node --env-file=.env scripts/seed-content-materials.js` insere três materiais de Física para o exemplo sem sobrescrever os já existentes. Conteúdos sem material publicado exibem um espaço em preparação e mantêm a prática disponível. O Neo4j continua apenas para leitura.

### Autenticação no navegador

Ao iniciar, o aplicativo consulta `/api/usuarios/me`. Sessão ausente ou expirada abre o login; falha de rede oferece nova tentativa. Uma resposta 401 durante o uso remove as telas privadas da navegação. As telas conferem o perfil retornado pela API. Alterar a URL não concede acesso à área do professor, e o servidor impede alterar o próprio perfil ou consultar trilhas de outro usuário. Os dados escolares do professor ainda são demonstrativos e não representam autorização para acessar estudantes reais.

No ambiente publicado, use HTTPS e `COOKIE_SECURE=true`, com frontend e API no mesmo site (preferencialmente a mesma origem com `/api` encaminhado ao backend). Mantenha CORS_ORIGINS explícito. No desenvolvimento, use 127.0.0.1 nos dois serviços; misturar localhost e 127.0.0.1 impede o uso do cookie SameSite. Logout precisa de conectividade: em caso de falha, o app informa e permite tentar novamente. Sair revoga todas as sessões da conta.

`node --env-file=.env scripts/verify-auth-live.js` verifica as duas contas fictícias já existentes, restauração por cookie, perfil, bloqueios, logout e preservação de contas/trilhas. O resultado sem credenciais fica em `.local/VERIFICACAO_AUTENTICACAO.json`.

Verificação de e-mail, recuperação por e-mail e Google continuam pendentes. A recomendação de verificação, sem implementação ou envio, está em `../AUTENTICACAO.md`.

A API inicia mesmo quando a rede está indisponível. Enquanto o MongoDB não conecta e os índices não estão prontos, as rotas `/api` retornam 503 e não aceitam operações. A reconexão inicial é tentada a cada 15 segundos. Uma falha temporária no Neo4j não impede o login pelo MongoDB; `/health/ready` informa o estado dos dois bancos.

Neste computador, a conexão do Atlas usa o formato padrão `mongodb://` com TLS explícito e os três hosts do mesmo cluster. Isso evita a falha `querySrv ECONNREFUSED` apresentada pelo DNS da rede atual. A solução mantém autenticação, replica set e criptografia, conforme [a orientação oficial do Atlas](https://www.mongodb.com/docs/atlas/troubleshoot-connection/). Para recriar a configuração, use Connect → Drivers e desative SRV Connection String; não copie credenciais para a documentação.

Execute os testes reais de autenticação e de trilhas em sequência: o teste de logout revoga as sessões da conta fictícia de professor usada no teste de isolamento das trilhas.
