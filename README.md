# Gabariteii

Projeto Integrador IV da PUC-Campinas · Time 13

O Gabariteii é um aplicativo de estudo para o Ensino Médio. Os alunos respondem a questões de vestibular, consultam materiais e seguem trilhas adaptadas ao seu desempenho. Os professores podem criar turmas e acompanhar o progresso por disciplina, tópico e quartil.

## Integrantes

| Nome | RA |
| --- | --- |
| Arthur Valerio de Santi | 25006924 |
| Henrique Young de Azevedo | 25005651 |
| Lucas Soares Gonçalves | 25009467 |
| Marcus Vinicius Martins Pulini | 25009605 |
| Sofia de Sousa | 25005435 |

## Como rodar

Os servidores Node.js e Java rodam no computador de quem está avaliando. O aplicativo roda em um emulador ou simulador nesse mesmo computador e usa os bancos e o serviço de e-mail do projeto pela internet.

| Sistema | Onde abrir o aplicativo |
| --- | --- |
| Windows | Emulador Android do Android Studio |
| macOS | Simulador de iPhone do Xcode ou emulador Android do Android Studio |

### 1. Baixar e extrair a entrega

1. Abra a página do **Release** no GitHub com a conta que tem acesso ao repositório. Em **Assets**, baixe **Source code (zip)**.
2. Extraia o ZIP inteiro. A **raiz do projeto** é a pasta extraída que contém `pom.xml`, `backend/` e `frontend/`. Use essa pasta como ponto de partida em cada nova janela de terminal.
3. Confira se o arquivo `backend/.env` veio no ZIP. Ele já contém a configuração dos bancos e do e-mail. No Finder do macOS, pressione **⌘ + Shift + .** para mostrar arquivos ocultos, se necessário.

### 2. Preparar o computador

#### Ferramentas dos dois sistemas

| Ferramenta | O que instalar ou conferir |
| --- | --- |
| **Node.js e npm** | Instale o Node.js 22 ou superior. O instalador inclui o npm. [Download do Node.js](https://nodejs.org/en/download) |
| **JDK e Maven** | Instale a JDK **25** e o Maven. Configure `JAVA_HOME` para a pasta da JDK e adicione o diretório `bin` do Maven ao `PATH`. [Download da JDK 25](https://adoptium.net/temurin/releases/?version=25) · [Instalação do Maven](https://maven.apache.org/install.html) |
| **Flutter SDK** | Instale o Flutter com Dart **3.13.2 ou mais recente na série 3**. A versão usada nos testes foi Flutter **3.47.2**. Adicione o diretório `bin` do Flutter ao `PATH` e siga o guia do seu sistema para os pré-requisitos do SDK, incluindo o Git. [Instalação do Flutter](https://docs.flutter.dev/install/manual) |

Depois da instalação, abra um novo terminal. No Windows, use o **PowerShell**. Os comandos abaixo devem mostrar as versões instaladas. A saída de `mvn -v` deve indicar Java 25.

```text
node -v
java -version
mvn -v
flutter --version
```

#### Windows ou macOS com Android

1. Instale o **Android Studio**. No **SDK Manager**, instale o Android SDK, **Build-Tools**, **Command-line Tools**, **Platform-Tools** e **Android Emulator**. Se a compilação solicitar componentes adicionais, instale a versão indicada do **NDK (Side by side)** ou do **CMake** pelo mesmo painel.
2. Abra **Device Manager**, crie um dispositivo virtual e inicie o emulador.
3. No terminal, execute os comandos abaixo. Revise as licenças do SDK caso sejam apresentadas e confira se a seção **Android toolchain** está pronta.

```text
flutter doctor --android-licenses
flutter doctor
```

Se o emulador não iniciar ou o Flutter apontar ferramentas pendentes, siga o [guia de configuração do Android](https://docs.flutter.dev/platform-integration/android/setup).

#### macOS com iPhone

1. Instale e abra o **Xcode** para concluir a configuração inicial. Na seção de componentes do Xcode, baixe o runtime do iOS para o simulador.
2. Abra um iPhone simulado pelo **Simulator** ou **Device Hub**, conforme a versão do Xcode.
3. Rode `flutter doctor` e confira a seção **Xcode**. [Guia de configuração do iOS](https://docs.flutter.dev/platform-integration/ios/setup)

### 3. Iniciar o Node.js

No primeiro terminal, aberto na raiz do projeto, rode a sequência do seu sistema. Aguarde cada comando terminar antes de rodar o próximo. Prossiga para a inicialização se `db:check` mostrar `mongodb: ok` e `neo4j: ok` na saída JSON.

**Windows — PowerShell**

```powershell
cd backend
npm.cmd ci
npm.cmd run db:check
npm.cmd start
```

**macOS — Terminal**

```sh
cd backend
npm ci
npm run db:check
npm start
```

Mantenha esse terminal aberto. Antes de continuar, confirme que aparecem `Autenticação HTTP em 127.0.0.1:3001` e `MongoDB conectado e inicializado`. O Node também abre a porta `3002`, usada pelo aplicativo para confirmação de e-mail, recuperação de senha, trilhas e turmas.

### 4. Iniciar o servidor Java

Abra um segundo terminal na raiz do projeto, onde está o `pom.xml`. Copie a linha completa para o PowerShell ou para o Terminal do macOS.

```text
mvn -q compile org.codehaus.mojo:exec-maven-plugin:3.5.0:java "-Dexec.mainClass=br.com.puccampinas.trilhas.Servidor" "-Dexec.args=3000" "-Dnode.url=http://127.0.0.1:3001"
```

A primeira execução pode levar alguns minutos para baixar as dependências. Quando aparecer **`O servidor esta ativo!`**, o Java estará ouvindo na porta `3000`. Deixe esse terminal aberto também. O Java recebe cadastro e login do aplicativo e encaminha os pedidos ao Node na porta `3001`.

Se preferir iniciar pelo IntelliJ, abra o `pom.xml`, selecione a JDK 25 e execute `br.com.puccampinas.trilhas.Servidor`. Use `3000` em **Program arguments** e `-Dnode.url=http://127.0.0.1:3001` em **VM options**.

### 5. Abrir o aplicativo Flutter

Com o emulador ou simulador já aberto, use um terceiro terminal na raiz do projeto.

```text
cd frontend
flutter pub get
flutter devices
```

Na lista de dispositivos, copie o identificador do emulador Android ou do iPhone simulado. Use esse identificador no lugar do exemplo no comando abaixo.

**Emulador Android — Windows ou macOS**

```text
flutter run -d emulator-5554 --dart-define=JAVA_TCP_HOST=10.0.2.2 --dart-define=JAVA_TCP_PORT=3000 --dart-define=API_TCP_HOST=10.0.2.2 --dart-define=API_TCP_PORT=3002
```

Use o ID do dispositivo que aparece como `android` em `flutter devices`. O endereço `10.0.2.2` permite acessar os servidores locais de dentro do emulador. [Rede do emulador Android](https://developer.android.com/studio/run/emulator-networking-address)

**Simulador iOS — macOS**

```sh
flutter run -d ID_DO_SIMULADOR --dart-define=JAVA_TCP_HOST=127.0.0.1 --dart-define=JAVA_TCP_PORT=3000 --dart-define=API_TCP_HOST=127.0.0.1 --dart-define=API_TCP_PORT=3002
```

Substitua `ID_DO_SIMULADOR` pelo ID exibido para o iPhone marcado como simulador.

### 6. Usar e encerrar

- **Cadastro e login.** Use um endereço de e-mail ao qual tenha acesso. Na data de nascimento, digite ano, mês e dia apenas com números. O aplicativo adiciona os traços. Confirme o cadastro com o código recebido e entre. A tela **Esqueci minha senha** envia um código para redefinir a senha.
- **Aluno.** Abra **Trilha** para iniciar o diagnóstico ou praticar por disciplina. As questões vêm do Neo4j Aura. Respostas e leituras são salvas no MongoDB Atlas.
- **Professor.** No cadastro, selecione uma escola ativa e informe um código de quatro dígitos, como `1234`. Depois de entrar, escolha sua disciplina, crie uma turma e compartilhe o código de matrícula. Use **Turmas** e **Relatórios** para acompanhar os alunos matriculados.

Para encerrar, digite `q` no terminal do Flutter, `desativar` no terminal do Java e pressione **Ctrl+C** no terminal do Node. Os dados permanecem nos bancos em nuvem.

### Se algo falhar

| Sintoma | O que conferir |
| --- | --- |
| O terminal não encontra uma ferramenta | Abra uma janela nova após a instalação. Verifique o `PATH` e, para o Maven, confira a JDK em `mvn -v`. |
| O teste dos bancos falha | Confira se está em `backend/`, se o `.env` que veio no ZIP está presente e se a rede consegue acessar o Atlas e o Aura. |
| Um servidor informa que a porta está ocupada | Verifique se já existe outra cópia do projeto rodando. As portas esperadas são `3000` para o Java e `3001` e `3002` para o Node. |
| O emulador não aparece em `flutter devices` | Inicie o dispositivo virtual e aguarde a tela inicial. Rode `flutter doctor` para conferir a configuração da plataforma. |
| O cadastro ou login mostra **Serviço indisponível** | Confira as mensagens de inicialização nos dois terminais, a URL `http://127.0.0.1:3001` no comando do Java e os endereços usados no comando do Flutter. Veja o teste do Node abaixo. |
| O código de confirmação não chega | Confira a caixa de spam e use **Reenviar código**. Se continuar falhando, confira o terminal do Node no momento da tentativa. |

Para testar a rota de cadastro do Node com o serviço rodando, use um terminal separado. No **Windows**, execute:

```powershell
curl.exe -i -X POST -H "Content-Type: application/json" -d "{}" "http://127.0.0.1:3001/api/auth/cadastro"
```

No **macOS**, execute:

```sh
curl -i -X POST -H "Content-Type: application/json" -d '{}' 'http://127.0.0.1:3001/api/auth/cadastro'
```

Nesse teste, **`409 Conflict` com `Revise os dados informados.` é a resposta esperada**. O pedido com `{}` verifica se o Node atende na porta `3001` sem criar uma conta.

## Tecnologias e estrutura

Flutter e Dart no aplicativo, Java 25 e Maven no servidor de cadastro e login, Node.js na API, MongoDB Atlas para contas e progresso, Neo4j Aura para o catálogo e Nodemailer com Gmail para envio de e-mail.

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
├── README.md
└── pom.xml                  dependências e compilação do Java
```

## Testes e documentação

| Comando | Diretório |
| --- | --- |
| `mvn test` | Raiz |
| `npm.cmd test` no Windows ou `npm test` no macOS | `backend/` |
| `flutter analyze` e `flutter test` | `frontend/` |

- [Dicionário de dados do MongoDB](docs/DICIONARIO_DE_DADOS.md)
- [Contrato do servidor Java](docs/CONTRATO_SERVIDOR.md)
