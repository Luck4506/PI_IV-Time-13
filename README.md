# Gabariteii

Projeto Integrador IV · Time 13

O Gabariteii é um aplicativo de estudo para alunos do Ensino Médio. A trilha muda de acordo com as respostas do aluno. O professor acompanha o desempenho da turma na própria disciplina.

## Rodar no iPhone simulado

Você vai precisar de Node.js 22 ou superior e Flutter com Dart 3.13.2 ou superior dentro da série 3. Para rodar no iPhone, use um Mac com Xcode e um simulador iOS instalado.

Coloque o arquivo de configuração do grupo em `backend/.env`. Para configurar um ambiente próprio, copie [`backend/.env.example`](backend/.env.example) e preencha os dados do MongoDB, do Neo4j e do remetente de e-mail. Gere o `JWT_SECRET` do ambiente com `openssl rand -hex 32`. As credenciais ficam no backend.

Na raiz do projeto, rode:

```sh
node scripts/iniciar.mjs
```

O comando instala as dependências da API quando necessário, inicia o Node e abre o Flutter no simulador. No Mac também dá para abrir **Iniciar Gabariteii.command**. No VS Code, com um simulador disponível, selecione **Gabariteii — iPhone no Device Hub** em **Executar e Depurar**.

Para cadastrar e fazer login, inicie à parte o validador Java fornecido pela equipe na mesma máquina que o Node. Use a porta `JAVA_VALIDATOR_PORT` de `backend/.env`, que por padrão é `3001`. [Contrato do validador](SCHEMA_E_VALIDACAO_JAVA.md)

Pressione `q` no terminal para fechar a execução do Flutter. A API continua em segundo plano e grava os registros em `.local/api-ios.log`.

## Rodar os serviços manualmente

Com o arquivo `backend/.env` configurado, abra dois terminais na raiz do projeto. Os comandos usam as portas padrão.

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
flutter run -d ID_DO_DISPOSITIVO --dart-define=API_TCP_HOST=127.0.0.1 --dart-define=API_TCP_PORT=3002
```

Use `127.0.0.1` no iPhone simulado. Para testar num iPhone físico, configure a assinatura do projeto no Xcode, coloque o iPhone e o computador do servidor na mesma rede privada e use no Flutter o IP desse computador. Em `backend/.env`, configure `TCP_HOST` com o IP local do servidor para aceitar a conexão do aparelho. No emulador Android padrão, o endereço do computador é `10.0.2.2`.

A conexão atual envia a senha e o token em TCP sem criptografia. Use contas de desenvolvimento em um ambiente controlado. Para disponibilizar o app pela internet, a conexão do Flutter com o servidor precisa de TLS.

## Como usar o aplicativo

### Aluno

Crie a conta com nome, e-mail, senha, data de nascimento e ano escolar. A lista vai do 1º ao 3º ano do Ensino Médio e inclui **Outro**. Se ativar o cadastro educacional, escolha uma escola ativa. O código da turma pode ser informado no cadastro ou depois, em **Perfil → Minha turma**. Cada aluno pode estar em uma turma por vez.

Em **Trilha**, comece pelo diagnóstico ou escolha **Praticar por disciplina**. A trilha recomenda primeiro conteúdos em que houve dificuldade. Quando o aluno acerta tudo, ela propõe assuntos diferentes para continuar o estudo. Nas etapas com material publicado, conclua a leitura antes da prática. A próxima etapa é liberada quando a anterior estiver concluída.

As questões apontam para a página do caderno do vestibular. Abra a página, volte ao aplicativo e marque a alternativa. Respostas e leituras ficam salvas. As telas de progresso, conquistas e notificações usam o histórico da conta.

### Professor

O cadastro do professor inclui escola e código de professor. Na aba **Turmas**, escolha sua disciplina e crie uma turma. Compartilhe o código de matrícula com os alunos. Quem criou a turma pode renovar o código e gerar um convite de uso único, válido por 24 horas, para outro professor.

Abra uma turma em **Turmas** ou **Relatórios** para ver o painel de quartis. Os cartões mostram cada aluno e seu aproveitamento na disciplina. Use **Buscar aluno por nome** ou toque em um aluno para ver o desempenho por conteúdo.

O ranking usa respostas corrigidas na disciplina depois da matrícula. Cada aluno precisa ter respondido pelo menos cinco questões distintas, e a turma precisa ter ao menos quatro alunos que atinjam esse mínimo. Empates ficam juntos. O painel também mostra alunos sem respostas e alunos abaixo do mínimo.

## Como as partes se comunicam

```text
Flutter → Node.js (TCP 3002)
             ├── Java (TCP 3001) · valida os campos do cadastro e do login
             ├── MongoDB · guarda contas, turmas, leituras, trilhas e respostas
             └── Neo4j · fornece questões, gabaritos e relações do catálogo
```

O Flutter envia todos os pedidos ao Node. Cada mensagem é um objeto JSON em UTF-8, terminado por uma quebra de linha. O Node confere a senha da conta, gerencia a sessão e encaminha ao validador Java externo só `VALIDAR_LOGIN` e `VALIDAR_CADASTRO`. Escola, matrícula e aceite dos termos são tratados no Node. O cadastro envia `perfil` como número. [Formato dos pedidos ao Java](SCHEMA_E_VALIDACAO_JAVA.md)

As senhas são armazenadas no MongoDB com hash scrypt. O token fica em memória no aplicativo, então é preciso entrar novamente depois de fechar o app. Quando a confirmação por e-mail está ativa, a conta nova recebe um código. O vínculo com a escola é declarado no cadastro. [Autenticação e configuração SMTP](AUTENTICACAO.md)

## Bancos e catálogo

Os bancos compartilhados do grupo são MongoDB Atlas e Neo4j Aura. O catálogo versionado contém 141 questões de 10 disciplinas, divididas em 38 conteúdos. O Neo4j precisa estar disponível para carregar questões e iniciar diagnósticos ou práticas.

Para conferir as conexões e o catálogo sem abrir o aplicativo, rode na raiz:

```sh
node scripts/iniciar.mjs --check
```

Se o endereço do Aura não resolver, confira se a instância está ativa e se o endereço em `backend/.env` está correto. Também é possível usar uma instância local de Neo4j. [Configuração dos bancos e publicação do catálogo](CONFIGURACAO_DOS_BANCOS.md)

## Verificar o código

Na pasta `backend/`, use `npm ci` e `npm test`. Na pasta `frontend/`, use `flutter pub get`, `flutter analyze` e `flutter test`.

A suíte de iPhone roda no simulador com dados isolados. Ela cobre a abertura do app, a área do aluno e a busca nos quartis. O Node de teste também permite verificar cadastro, login e sessão com uma resposta simulada do validador. [Comandos para rodar no iPhone](frontend/README.md#verificar-no-iphone)

## Arquivos do projeto

| Caminho | Conteúdo |
| --- | --- |
| [`frontend/`](frontend/README.md) | Aplicativo Flutter, assets e testes |
| [`backend/`](backend/README.md) | Protocolo TCP, rotas e acesso aos bancos |
| [`scripts/`](scripts/) | Inicialização do ambiente e preparação do iPhone |

O Git guarda código, assets, testes, configurações compartilhadas e arquivos de dependências. O [`.gitignore`](.gitignore) deixa de fora credenciais, certificados privados, cópias dos bancos, arquivos de compilação e registros locais.
