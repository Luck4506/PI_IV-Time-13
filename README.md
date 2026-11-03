# Trilha — Projeto Integrador IV · Time 13

Aplicativo Flutter de aprendizagem adaptativa, com API Node.js, MongoDB Atlas e Neo4j Aura. Este guia permite que os integrantes executem o projeto e acessem os bancos compartilhados do grupo.

## Início rápido para os integrantes

### 1. Instalar os requisitos uma vez

- **Node.js 22 ou mais recente**, com npm disponível no terminal.
- **Flutter compatível com `frontend/pubspec.yaml`**. O projeto exige Dart `^3.13.2`; a versão de referência usada é Flutter **3.47.2 / Dart 3.13.2**.
- Um navegador e conexão à internet.
- Para o iPhone simulado: Mac, Xcode completo e um simulador iOS instalado. Esses requisitos adicionais são necessários somente para executar no iOS.

Confira no terminal:

```sh
node --version
npm --version
flutter --version
```

Não é necessário instalar MongoDB ou Neo4j localmente: os bancos já estão na nuvem. Para conferir apenas as conexões, basta Node.js com npm; Flutter é necessário para executar o aplicativo.

### 2. Configurar o arquivo de ambiente

Baixe ou clone o código do grupo e abra a pasta **PI_IV-Time-13** no VS Code, onde ficam este README e as pastas `backend`, `frontend` e `scripts`.

Renomeie o arquivo **trilha-grupo.env** para **.env** e coloque-o dentro de **backend/**:

```text
PI_IV-Time-13/
├── README.md
├── scripts/
│   └── iniciar.mjs
├── backend/
│   ├── .env                 ← arquivo de configuração
│   ├── .env.example         ← modelo sem credenciais reais
│   ├── package.json
│   └── src/
└── frontend/
    └── pubspec.yaml
```

O nome final deve ser exatamente `backend/.env`, sem a extensão `.txt`. Não coloque esse arquivo em `frontend/` nem copie as senhas para o código Flutter. Se já tiver uma configuração própria, preserve uma cópia antes de substituir seu `.env`.

O arquivo já contém as duas conexões, o banco de destino e a configuração local da API. Não é necessário trocar senhas, criar outro cluster ou refazer a migração.

### 3. Executar um comando

No terminal do VS Code, dentro da pasta `PI_IV-Time-13`:

```sh
node scripts/iniciar.mjs
```

O iniciador confere o `.env` e as ferramentas, instala as dependências da API na primeira execução ou após alterações no arquivo de dependências, obtém as dependências Flutter, inicia ou reutiliza a API e aguarda os dois bancos responderem. Depois executa o aplicativo Web na porta 5173.

Quando o Flutter informar que o aplicativo está disponível, abra **[http://127.0.0.1:5173](http://127.0.0.1:5173)**. Mantenha o terminal aberto. Use `q` ou `Ctrl+C` para encerrar; o iniciador encerra os processos que ele próprio abriu e preserva uma API que já estava em execução.

No Mac, **Iniciar Trilha.command** executa o mesmo iniciador. O comando Node acima é a opção principal para o grupo. A conferência de execução foi feita no macOS; a execução manual está descrita abaixo para os demais ambientes.

### 4. Criar uma conta no aplicativo

Use **Ainda não tenho uma conta** e crie sua própria conta de teste. A senha do banco presente no `.env` é diferente da senha da sua conta no aplicativo.

Cada integrante deve usar um e-mail de teste diferente para não compartilhar a sessão e o histórico de uma mesma conta. Os bancos são compartilhados: use dados fictícios durante os testes.

O aluno pode ativar **Cadastro educacional** e selecionar **Escola Horizonte — Demonstração**. Professor sempre usa cadastro educacional. O exemplo permite testar a interface e a gravação da escolha; o vínculo institucional ainda não é verificado. Neste protótipo, o cadastro de professor depende de `ALLOW_TEACHER_REGISTRATION=true` no arquivo `.env`.

## Conferir as conexões sem abrir o aplicativo

Na raiz:

```sh
node scripts/iniciar.mjs --check
```

Esse comando instala as dependências da API se necessário e consulta os dois bancos sem exigir Flutter, sem iniciar o aplicativo e sem criar novos usuários ou trilhas. O resultado esperado informa `mongodb: "ok"` e `neo4j: "ok"`; a quantidade de nós corresponde ao conteúdo atual do grafo.

Com a API em execução, abra também [http://127.0.0.1:3000/health/ready](http://127.0.0.1:3000/health/ready). Quando os bancos estão disponíveis, a resposta é:

```json
{"status":"ok","mongodb":true,"neo4j":true}
```

## Acessar os bancos diretamente

O arquivo `.env` configura as conexões dos bancos. Ele não é um login no painel administrativo do Atlas ou do Aura; o acesso a esses painéis exige convite às contas pessoais dos integrantes.

| Serviço | Como conectar | Dados usados do arquivo |
| --- | --- | --- |
| MongoDB Atlas | Cole a conexão completa no MongoDB Compass ou use o driver MongoDB | `MONGODB_URI`; banco em `MONGODB_DATABASE` |
| Neo4j Aura | Use o Neo4j Browser ou um driver Neo4j com a conexão segura do Aura | `NEO4J_URI`, `NEO4J_USERNAME`, `NEO4J_PASSWORD` e `NEO4J_DATABASE` |

Mantenha a conexão MongoDB conforme o arquivo `.env`, inclusive os três servidores e a opção TLS. Essa configuração atende redes nas quais a consulta DNS SRV falha. Use os valores de usuário e banco do Aura definidos no mesmo arquivo.

Os serviços são **MongoDB Atlas Free/M0** e **Neo4j AuraDB Free**. O Atlas aceita conexões de todos os IPv4 (`0.0.0.0/0`), mantendo usuário, senha e TLS. Não é necessário cadastrar cada novo IP enquanto essa regra estiver ativa. Redes que bloqueiam as portas dos bancos ou serviços pausados ainda podem impedir a conexão.

Os bancos são os mesmos para todo o grupo. Alterações feitas diretamente neles aparecem para os demais integrantes.

Se o Aura mostrar **PAUSED**, abra a instância **Trilha-Projeto-Integrador** no painel, selecione **More instance actions → Resume Instance** e aguarde o estado ativo antes de repetir a conferência. Enquanto a instância está pausada, o endereço pode não resolver no DNS. O arquivo de conexão continua sendo o mesmo; não é necessário recriar o banco ou importar os dados novamente.

## Onde os dados ficam

| Banco/coleção | Responsabilidade |
| --- | --- |
| MongoDB · `usuarios` | Cadastro, senha protegida, perfil, ano e escola declarada |
| MongoDB · `trilhas` | Trilhas do aluno, referências às questões, respostas e histórico |
| MongoDB · `materiais_conteudo` | Teoria e materiais publicados por conteúdo |
| MongoDB · `progresso_conteudos` | Leitura dos conteúdos por usuário e trilha |
| MongoDB · `escolas` | Escola fictícia `ESCOLA-DEMO-001`, usada no cadastro |
| Neo4j Aura | Catálogo de questões, conteúdos, disciplinas e relações entre eles |

A aplicação consulta o Neo4j para selecionar questões e conteúdos. Respostas, trilhas e progresso dos usuários ficam no MongoDB. A migração do banco Desktop já foi feita; não execute novamente os scripts de migração para configurar outro computador.

## Executar manualmente em dois terminais

Configure primeiro o arquivo `backend/.env`.

**Terminal 1 — API**, partindo da raiz:

```sh
cd backend
npm ci
npm start
```

**Terminal 2 — aplicativo**, partindo da raiz:

```sh
cd frontend
flutter pub get
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5173 --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

Abra o aplicativo quando a compilação terminar. Para conferir apenas os bancos após instalar as dependências, execute `npm run db:check` dentro de `backend/`.

Os bancos compartilhados já estão preparados. Não é necessário recriar coleções, importar exemplos ou executar scripts de migração em cada instalação.

## Executar no iPhone simulado

No Mac, com Flutter, Xcode e um iPhone simulado disponíveis, use o mesmo `backend/.env`. Na raiz:

```sh
node scripts/iniciar.mjs --check
bash scripts/rodar-iphone.sh
```

Outra opção, após o preparo inicial das dependências, é abrir **Executar e Depurar** no VS Code, selecionar **Trilha — iPhone no Device Hub** e pressionar **F5**. Consulte [o guia de iPhone e Device Hub](IPHONE_DEVICE_HUB.md).

O endereço `127.0.0.1:3000` acessa a API deste Mac pelo simulador. Um iPhone físico exige outra configuração de rede; este roteiro é para o iPhone simulado.

## Testar a trilha e o cadastro

1. Entre como estudante e abra **Trilha → Novo diagnóstico de exemplo**.
2. Use **B, C, D** para errar a primeira questão e gerar reforço por conteúdos.
3. Use **A, C, D** em outro exemplo para acertar todas e gerar uma trilha de exploração.
4. Ao errar, confira a alternativa marcada em vermelho e a correta em verde. No mapa, conteúdos praticados com erros mostram **Revisar**.
5. Abra o conteúdo disponível, conclua a leitura e a prática para liberar a etapa seguinte.

O [roteiro completo de testes](TESTAR_TRILHAS.md) explica os exemplos e a conferência dos registros no Atlas.

Cadastro, login, questões, leituras, respostas e trilhas usam a API e os bancos reais. Os painéis gerais de XP, conquistas, turmas e relatórios ainda contêm demonstrações. Verificação de e-mail, recuperação de senha e validação do vínculo escolar ficam para etapas futuras. No cliente nativo, entre novamente ao reiniciar o app; o histórico continua salvo.

## Problemas comuns

| Situação | Como resolver |
| --- | --- |
| `.env` não encontrado | Confira `backend/.env` e se o sistema acrescentou `.txt` ao nome |
| `node`, `npm` ou `flutter` não encontrado | Instale a ferramenta, adicione-a ao PATH e reabra o terminal |
| Dart incompatível | Confira `flutter --version`; o projeto exige Dart `^3.13.2` |
| Porta 3000 ou 5173 ocupada | Encerre a execução anterior e tente novamente; não execute os dois modos de inicialização ao mesmo tempo |
| API ou banco indisponível | Execute `node scripts/iniciar.mjs --check`; confira internet, eventual pausa dos serviços e validade das credenciais |
| Funciona em uma rede e falha em outra | Teste outra conexão; algumas redes bloqueiam conexões diretas aos bancos |
| Erro após mudar dependências do backend | Execute `npm ci` dentro de `backend/`; o iniciador também detecta mudanças no arquivo de dependências |
| Falha no OneDrive/iOS | Use o roteiro de iPhone; o preparo mantém o cache de compilação fora da pasta sincronizada |

## Arquivo de configuração e credenciais

O arquivo de credenciais **`trilha-grupo.env`** deve ser renomeado para **`.env`** e salvo em **`backend/`**. O compartilhamento desse arquivo deve ocorrer por um canal privado.

O arquivo contém a configuração da API e das conexões atuais, com um segredo de sessão próprio. As credenciais da instância Desktop usada na migração não fazem parte dessa configuração.

As regras de `.gitignore` excluem `.env`, arquivos `*.env` e `.local/`. O arquivo `backend/.env.example` é o modelo público sem segredos. Não use `git add -f` para incluir arquivos de credenciais. Se as senhas dos bancos forem alteradas, atualize os valores correspondentes no arquivo `.env`.

## Organização e documentação

- [`frontend/`](frontend/README.md): aplicativo Flutter e telas.
- [`backend/`](backend/README.md): API, rotas e detalhes dos bancos.
- [`scripts/iniciar.mjs`](scripts/iniciar.mjs): inicialização e conferência para o grupo.
- [`CONFIGURACAO_DOS_BANCOS.md`](CONFIGURACAO_DOS_BANCOS.md): serviços configurados e separação dos dados.
- [`AUTENTICACAO.md`](AUTENTICACAO.md): autenticação e sessão.
- [`REVISAO.md`](REVISAO.md): verificações anteriores e limites do protótipo.
- [`IPHONE_DEVICE_HUB.md`](IPHONE_DEVICE_HUB.md): iPhone simulado e VS Code.

## Verificação do código

Dentro de `backend/`:

```sh
npm test
npm run db:check
```

Dentro de `frontend/`:

```sh
flutter test
dart analyze
```

Os testes e a análise verificam o código. `db:check` consulta os bancos reais sem criar novos usuários ou trilhas.
