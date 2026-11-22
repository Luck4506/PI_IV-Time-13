# Gabariteii

Projeto Integrador IV · Time 13

O Gabariteii é um aplicativo de estudo para alunos do Ensino Médio. A trilha muda de acordo com as respostas do aluno. O professor acompanha o desempenho da turma na própria disciplina.

## Integração do servidor Java

O cadastro e o login seguem o fluxo Flutter → Java → Node → MongoDB. O Java recebe JSON por TCP e encaminha os pedidos válidos ao Node por HTTP. Consulte o [contrato do servidor](docs/CONTRATO_SERVIDOR.md) e o [guia de execução do Java](docs/EXECUCAO_SERVIDOR.md).

## Rodar no iPhone simulado

Você vai precisar de Node.js 22 ou superior e Flutter com Dart 3.13.2 ou superior dentro da série 3. Para rodar no iPhone, use um Mac com Xcode e um simulador iOS instalado.

Coloque o arquivo de configuração do grupo em `backend/.env`. Para configurar um ambiente próprio, copie [`backend/.env.example`](backend/.env.example) e preencha os dados do MongoDB, do Neo4j e do remetente de e-mail. Gere o `JWT_SECRET` do ambiente com `openssl rand -hex 32`. As credenciais ficam no backend.

Inicie o servidor Java com JDK 25 conforme o guia. Use a porta TCP `3000` e a opção de JVM `-Dnode.url=http://127.0.0.1:3001`. Se você ainda estiver com o validador antigo na porta `3001`, encerre essa execução para liberar a porta HTTP do Node.

Na raiz do projeto, rode:

```sh
node scripts/iniciar.mjs
```

O comando instala as dependências da API quando necessário, inicia o Node e abre o Flutter no simulador. No Mac também dá para abrir **Iniciar Gabariteii.command**. No VS Code, com um simulador disponível, selecione **Gabariteii — iPhone no Device Hub** em **Executar e Depurar**.

Pressione `q` no terminal para fechar a execução do Flutter. A API continua em segundo plano e grava os registros em `.local/api-ios.log`.

## Rodar os serviços manualmente

Com o arquivo `backend/.env` configurado, inicie o Java e use terminais separados para o Node e o Flutter. Os comandos usam as portas padrão.

**API Node**

```sh
cd backend
npm ci
npm start
```

**Aplicativo Flutter**

```sh
cd frontend
flutter pub get
flutter devices
flutter run -d ID_DO_DISPOSITIVO \
  --dart-define=API_TCP_HOST=127.0.0.1 --dart-define=API_TCP_PORT=3002 \
  --dart-define=JAVA_TCP_HOST=127.0.0.1 --dart-define=JAVA_TCP_PORT=3000
```

Use `127.0.0.1` no iPhone simulado. Para testar num iPhone físico, configure a assinatura no Xcode e use o IP do computador servidor nos dois endereços do Flutter. Em `backend/.env`, configure `TCP_HOST` com esse IP. No emulador Android padrão, use `10.0.2.2` nos dois endereços e permita a conexão TCP com o Node no computador. Se mudar `AUTH_HTTP_PORT` no Node, use a mesma porta em `-Dnode.url` no Java.

A conexão atual envia a senha e o token em TCP sem criptografia. Use contas de desenvolvimento em um ambiente controlado. Para disponibilizar o app pela internet, a conexão do Flutter com o servidor precisa de TLS.

## Como usar o aplicativo

### Aluno

Crie a conta com nome, e-mail, senha, data de nascimento e ano escolar. A lista vai do 1º ao 3º ano do Ensino Médio e inclui **Outro**. Se ativar o cadastro educacional, escolha uma escola ativa. O código da turma pode ser informado no cadastro ou depois, em **Perfil → Minha turma**. Cada aluno pode estar em uma turma por vez.

Em **Trilha**, comece pelo diagnóstico ou escolha **Praticar por disciplina**. A trilha recomenda primeiro conteúdos em que houve dificuldade. Quando o aluno acerta tudo, ela propõe assuntos diferentes para continuar o estudo. Nas etapas com material publicado, conclua a leitura antes da prática. A próxima etapa é liberada quando a anterior estiver concluída.

Leia o enunciado e marque a alternativa na própria tela da questão. O app identifica a banca, o ano e o caderno para consulta da fonte. Respostas e leituras ficam salvas. As telas de progresso, conquistas e notificações usam o histórico da conta.

### Professor

O cadastro do professor inclui escola e código de professor. Na aba **Turmas**, escolha sua disciplina e crie uma turma. Compartilhe o código de matrícula com os alunos. Quem criou a turma pode renovar o código e gerar um convite de uso único, válido por 24 horas, para outro professor.

Abra uma turma em **Turmas** ou **Relatórios** para ver o painel de quartis. Os cartões mostram cada aluno e seu aproveitamento na disciplina. Use **Buscar aluno por nome** ou toque em um aluno para ver o desempenho por conteúdo.

O ranking usa respostas corrigidas na disciplina depois da matrícula. Cada aluno precisa ter respondido pelo menos cinco questões distintas, e a turma precisa ter ao menos quatro alunos que atinjam esse mínimo. Empates ficam juntos. O painel também mostra alunos sem respostas e alunos abaixo do mínimo.

## Como as partes se comunicam

```text
Cadastro e login   Flutter → Java (TCP 3000) → Node (HTTP 3001) → MongoDB
Demais operações   Flutter → Node (TCP 3002) → MongoDB e Neo4j
```

Cada mensagem TCP é um objeto JSON em UTF-8, terminado por uma quebra de linha. O Java valida `VALIDAR_LOGIN` e `VALIDAR_CADASTRO`. O Node confere credenciais, escola e matrícula, grava o aceite dos termos e emite a sessão. O Flutter usa a sessão nas demais operações, como trilhas e turmas. [Formato dos pedidos ao Java](docs/CONTRATO_SERVIDOR.md)

As senhas são armazenadas no MongoDB com hash scrypt. O token fica em memória no aplicativo, então é preciso entrar novamente depois de fechar o app. Quando a confirmação por e-mail está ativa, a conta nova recebe um código. O vínculo com a escola é declarado no cadastro. [Autenticação e configuração SMTP](AUTENTICACAO.md)

## Bancos e catálogo

Os bancos compartilhados do grupo são MongoDB Atlas e Neo4j Aura. O catálogo ativo no Aura guarda o enunciado, as alternativas, o gabarito e os vínculos de conteúdo de cada questão. O Neo4j precisa estar disponível para carregar questões e iniciar diagnósticos ou práticas.

Para conferir as conexões e o catálogo sem abrir o aplicativo, rode na raiz:

```sh
node scripts/iniciar.mjs --check
```

Se o endereço do Aura não resolver, confira se a instância está ativa e se o endereço em `backend/.env` está correto. Também é possível usar uma instância local de Neo4j. [Configuração dos bancos e publicação do catálogo](CONFIGURACAO_DOS_BANCOS.md)

## Verificar o código

Na pasta `backend/`, use `npm ci` e `npm test`. Na pasta `frontend/`, use `flutter pub get`, `flutter analyze` e `flutter test`.

A suíte de iPhone roda no simulador com dados isolados. Os testes do Flutter conferem as mensagens TCP de cadastro e login. Os testes do Node conferem o contrato HTTP e as regras de sessão com dados simulados. [Comandos para rodar no iPhone](frontend/README.md#verificar-no-iphone)

## Arquivos do projeto

| Caminho | Conteúdo |
| --- | --- |
| [`frontend/`](frontend/README.md) | Aplicativo Flutter, assets e testes |
| [`backend/`](backend/README.md) | Protocolo TCP, rotas e acesso aos bancos |
| [`scripts/`](scripts/) | Inicialização do ambiente e preparação do iPhone |

O Git guarda código, assets, testes, configurações compartilhadas e arquivos de dependências. O [`.gitignore`](.gitignore) deixa de fora credenciais, certificados privados, cópias dos bancos, arquivos de compilação e registros locais.
