# Bancos e catálogo

As credenciais ficam em `backend/.env`. Use o arquivo privado da equipe ou preencha o [modelo de ambiente](backend/.env.example). Para consultar os bancos diretamente, use a URI configurada no MongoDB Compass ou no Neo4j Browser. A administração dos serviços usa as contas e permissões dos painéis do Atlas e do Aura.

| Serviço | O que armazena |
| --- | --- |
| MongoDB Atlas | Usuários, confirmação de e-mail, escolas, turmas, matrículas, trilhas, respostas, materiais, leituras e notificações |
| Neo4j Aura | Disciplinas, conteúdos, questões, gabaritos e relações entre questões |

Em um MongoDB novo, a API prepara os índices ao iniciar. Para disponibilizar uma escola no cadastro educacional, registre na coleção `escolas` um documento com o código da escola em `_id` (texto), o `nome` e `ativa: true`.

## Conferir as conexões

Rode `node scripts/iniciar.mjs --check` na raiz. O comando verifica o MongoDB e o Neo4j e informa quantas questões oficiais encontrou. Caso o Aura esteja pausado, reative a instância pelo painel antes de repetir a checagem.

Com a API ligada, a rota TCP `GET /health/ready` retorna status `200` quando os dois bancos respondem e o catálogo oficial está disponível. Dentro de `backend/`:

```sh
node --env-file=.env --input-type=module -e 'import { consultarApiTcp } from "./src/tcp-client.js"; console.log(await consultarApiTcp("GET", "/health/ready"));'
```

## Usar Neo4j local

O Neo4j local é opcional. Crie `backend/.env.neo4j-local` com `NEO4J_URI` no formato `neo4j://127.0.0.1:7687` e preencha `NEO4J_USERNAME`, `NEO4J_PASSWORD` e `NEO4J_DATABASE`. O MongoDB continua usando `backend/.env`.

Inicie a instância pelo Neo4j Desktop ou Docker, se for o caso. Em uma instalação por terminal, `TRILHA_NEO4J_HOME` pode apontar para a pasta da instalação e `TRILHA_JAVA_HOME` para o Java usado pelo Neo4j.

```sh
node scripts/iniciar.mjs --check --neo4j-local
node scripts/iniciar.mjs --neo4j-local
```

## Publicar o catálogo

O lote versionado reúne questões do ENEM, FUVEST, Unicamp, Unesp e PUC-Campinas. Cada entrada traz a referência ao caderno, a página e o gabarito. O lote pode ser conferido sem conectar aos bancos. Na pasta `backend/`:

```sh
node scripts/seed-questions.js --dry-run
```

Para publicar em uma instância nova ou depois de atualizar o catálogo, rode `npm run db:seed:questions` em `backend/`. O comando grava as questões e as relações no Neo4j e publica no MongoDB os materiais que ainda não existem. As questões antigas usadas em históricos são preservadas.

Para publicar no grafo local, use `node --env-file=.env --env-file=.env.neo4j-local scripts/seed-questions.js` a partir de `backend/`. Depois, confira o catálogo e as referências com `npm run db:audit` para o ambiente padrão ou com `node --env-file=.env --env-file=.env.neo4j-local scripts/audit-data.js` para o ambiente local.

Backups e credenciais continuam fora do Git. A migração do banco e a publicação do catálogo são operações de manutenção. Para usar um ambiente compartilhado já configurado, basta conferir a conexão.
