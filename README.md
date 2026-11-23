# Gabariteii

Projeto Integrador IV da PUC-Campinas · Time 13

O Gabariteii é um aplicativo de estudo para o Ensino Médio que oferece questões de vestibular, materiais didáticos e trilhas adaptadas às respostas dos alunos. Os professores podem criar turmas e acompanhar o desempenho por disciplina, tópico e quartil.

## Integrantes

| Nome | RA |
| --- | --- |
| Arthur Valerio de Santi | 25006924 |
| Henrique Young de Azevedo | 25005651 |
| Lucas Soares Gonçalves | 25009467 |
| Marcus Vinicius Martins Pulini | 25009605 |
| Sofia de Sousa | 25005435 |

## Tecnologias

Flutter e Dart no aplicativo, Java 25 e Maven no servidor de cadastro e login, Node.js na API, MongoDB Atlas para contas e progresso, Neo4j Aura para o catálogo e Nodemailer com Gmail para envio de e-mail.

## Estrutura do repositório

```text
.
├── .idea/, .vscode/         configurações dos editores
├── backend/
│   ├── src/                 API TCP e HTTP, autenticação, trilhas e turmas
│   ├── scripts/             manutenção e auditoria dos bancos
│   └── test/                testes da API
├── docs/                    dicionário de dados e contrato do servidor
├── frontend/
│   ├── lib/                 telas e serviços Flutter
│   ├── assets/              imagens do aplicativo
│   ├── test/                testes de telas e serviços
│   ├── integration_test/    testes em simulador
│   └── android/, ios/, linux/, macos/, web/, windows/
│                            arquivos de plataforma do Flutter
├── scripts/                 atalhos de desenvolvimento
├── src/
│   ├── main/java/           servidor Java
│   └── test/java/           testes do servidor Java
├── Iniciar Gabariteii.command
└── pom.xml                  dependências e compilação do Java
```

## Como rodar

### Pré-requisitos

- Node.js 22 ou superior com npm.
- JDK 25 e Maven. O comando `mvn -v` deve indicar que o Maven está utilizando a JDK 25.
- Flutter SDK com Dart 3.13.2 ou superior na série 3.
- Emulador Android configurado no Android Studio ou simulador iOS no macOS com Xcode.
- Conexão com a internet e acesso ao repositório privado pelo GitHub.

### 1. Baixar e extrair o ZIP

1. Na página do Release da entrega, localize a seção **Assets** e baixe **Source code (zip)**.
2. Extraia todo o conteúdo do arquivo ZIP e abra um terminal na pasta extraída que contém `pom.xml` e os diretórios `backend/` e `frontend/`. Essa é a **raiz do projeto** usada nas próximas etapas.
3. Verifique a presença de `backend/.env`, arquivo de configuração do MongoDB Atlas, do Neo4j Aura e do Gmail do projeto. O sistema pode ocultar arquivos cujo nome começa com ponto.

### 2. Iniciar a API Node.js

Na raiz do projeto, execute os comandos abaixo:

```sh
cd backend
npm ci
npm run db:check
npm start
```

O comando `npm run db:check` verifica a conexão com os dois bancos e a disponibilidade do catálogo. Mantenha a API em execução. Se o Atlas recusar a conexão em outra rede, verifique se o IP público dessa rede está autorizado no projeto Atlas.

### 3. Iniciar o servidor Java

Abra outro terminal na raiz do projeto e execute:

```sh
mvn -q compile org.codehaus.mojo:exec-maven-plugin:3.5.0:java "-Dexec.mainClass=br.com.puccampinas.trilhas.Servidor" "-Dexec.args=3000" "-Dnode.url=http://127.0.0.1:3001"
```

Como alternativa, no IntelliJ, abra o `pom.xml`, selecione a JDK 25 e execute `br.com.puccampinas.trilhas.Servidor` com o argumento `3000` e a opção de JVM `-Dnode.url=http://127.0.0.1:3001`. Mantenha o servidor em execução durante o uso do aplicativo.

### 4. Executar o aplicativo Flutter

Inicie o emulador ou simulador. Em um terceiro terminal, na raiz do projeto, execute:

```sh
cd frontend
flutter pub get
flutter devices
```

Substitua `ID_DO_DISPOSITIVO` pelo identificador exibido por `flutter devices`.

**Emulador Android**

```sh
flutter run -d ID_DO_DISPOSITIVO --dart-define=JAVA_TCP_HOST=10.0.2.2 --dart-define=JAVA_TCP_PORT=3000 --dart-define=API_TCP_HOST=10.0.2.2 --dart-define=API_TCP_PORT=3002
```

**Simulador iOS**

```sh
flutter run -d ID_DO_DISPOSITIVO --dart-define=JAVA_TCP_HOST=127.0.0.1 --dart-define=JAVA_TCP_PORT=3000 --dart-define=API_TCP_HOST=127.0.0.1 --dart-define=API_TCP_PORT=3002
```

### 5. Utilizar a aplicação

Utilize um endereço de e-mail ao qual tenha acesso. O Gabariteii envia os códigos de confirmação de cadastro e recuperação de senha pelo Gmail do projeto. Após confirmar o endereço, acesse a aplicação pela tela de login. Para cadastrar um professor, selecione uma escola ativa e informe um código de quatro dígitos, como `1234`.

- **Aluno** · abra **Trilha** para iniciar um diagnóstico ou praticar por disciplina. As questões vêm do Neo4j Aura. Respostas e leituras são salvas no MongoDB Atlas.
- **Professor** · escolha sua disciplina, crie uma turma e compartilhe o código de matrícula. Abra **Turmas** ou **Relatórios** para acompanhar os alunos já matriculados.

Para encerrar, digite `q` no terminal do Flutter e `desativar` no console do Java. Interrompa o Node com `Ctrl+C`. Os dados persistem nos serviços em nuvem.

## Testes e documentação

| Comando | Diretório |
| --- | --- |
| `mvn test` | Raiz |
| `npm test` | `backend/` |
| `flutter analyze` e `flutter test` | `frontend/` |

Cadastro e login passam do Flutter ao Java em TCP `3000`, e o Java encaminha essas operações ao Node em HTTP `3001`. O Flutter envia as outras operações ao Node em TCP `3002`. A API consulta o Atlas e o Aura.

- [Dicionário de dados do MongoDB](docs/DICIONARIO_DE_DADOS.md)
- [Contrato do servidor Java](docs/CONTRATO_SERVIDOR.md)
