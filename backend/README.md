# Backend Trilha

API Node.js 22+ / Express para o Flutter. As credenciais ficam em `.env`, ignorado pelo Git.

## Separação dos dados

- **MongoDB Atlas M0:** banco `trilha`, coleção `usuarios`. Nome, e-mail normalizado e único, senha protegida com scrypt, perfil, ano escolar ou código da escola e datas. A validação bloqueia campos não previstos. Não recebe questões, alternativas, gabaritos ou respostas de atividades.
- **Neo4j AuraDB Free:** grafo importado do `Projeto_integrador`, preservando rótulos, propriedades, relacionamentos, índices e restrições do dump. Questões são consultadas somente no grafo.
- A sessão da aplicação usa token de 12 horas, mantido apenas em memória no Flutter. Sair invalida os tokens da conta. Reabrir o app exige novo login.

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
flutter run -d chrome --web-port=5173 --dart-define=API_BASE_URL=http://127.0.0.1:3000
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
| POST | `/api/questoes/:id/responder` | Conferir alternativa com gabarito do grafo, quando disponível |

As rotas de dados exigem `Authorization: Bearer <token>`. Não há endpoint de Cypher livre nem listagem pública de usuários. Cadastro e login possuem limite de tentativas. Dados inválidos retornam 400; autenticação inválida, 401; e-mail repetido, 409.

Cadastro de estudante:

```json
{
  "nome": "Estudante Teste",
  "email": "estudante@example.com",
  "senha": "EscolhaUmaSenhaDeTeste123!",
  "perfil": "student",
  "anoEscolar": "3º ano",
  "termosAceitos": true
}
```

Login: `email`, `senha`, `perfil` (`student` ou `teacher`). Neste ambiente local, o cadastro de professor está habilitado para testes. Em novas instalações ele fica desativado por padrão; `ALLOW_TEACHER_REGISTRATION=true` permite experimentá-lo no protótipo. Isso não equivale à verificação de vínculo escolar e não deve ser habilitado em um serviço público sem esse fluxo.

Resposta de questão: `{"alternativa":"A"}`. Se o grafo não tiver gabarito válido, a API retorna `corrigida:false`; não inventa gabaritos. Esta etapa não persiste tentativas nem calcula progresso, XP ou trilhas adaptativas. As imagens referenciadas por caminhos locais no grafo ainda precisam de hospedagem própria.

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

Caso seu IP público mude, adicione o novo endereço específico na lista de acesso do Atlas. Não é necessário liberar a internet inteira.
