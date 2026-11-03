# Executar no iPhone simulado pelo VS Code

Conferido em 28/10/2026 com Flutter 3.47.2, Xcode 27.1 e **iPhone 16e / iOS 26.3.1** no Device Hub.

## Como abrir

1. Abra a pasta `PI_IV-Time-13` no VS Code. Se preferir abrir apenas `frontend`, a configuração também está disponível lá.
2. Abra **Executar e Depurar** e selecione **Trilha — iPhone no Device Hub**.
3. Pressione **F5**.
4. Use uma conta já cadastrada. As trilhas e respostas continuam nos mesmos bancos na nuvem.

O perfil prepara o cache de compilação, verifica/inicia a API e seleciona o emulador iOS da extensão Flutter. Se o Device Hub já estiver com um iPhone iniciado, esse simulador é usado. Para trocar o modelo, escolha outro iPhone no Device Hub e inicie-o antes de executar. A configuração força o destino de simulador, mesmo que um iPhone físico esteja selecionado na barra de dispositivos.

O endereço usado é `http://127.0.0.1:3000`, apropriado para o simulador neste Mac. Os bancos continuam acessíveis apenas pelo backend; não há senhas de banco dentro do app.

Se aparecer a solicitação de rede local do Flutter, essa permissão permite a conexão de depuração. O hot reload fica disponível pelo VS Code.

## Comando único no terminal

Abra o terminal integrado do VS Code na pasta `PI_IV-Time-13` e execute:

```bash
bash scripts/rodar-iphone.sh
```

Se o VS Code estiver aberto apenas na pasta `frontend`, use `bash ../scripts/rodar-iphone.sh`.

O comando prepara o cache fora do OneDrive, reutiliza ou inicia a API, aguarda os bancos, inicia o simulador quando necessário, obtém as dependências Flutter e executa o app. Usa um iPhone já iniciado, preferindo o iPhone 16e quando há mais de um disponível. Mantenha o terminal aberto durante os testes; pressione `r` para atualizar o aplicativo e `q` para encerrar a execução. A API permanece em segundo plano para os próximos testes.

Para apenas conferir a preparação, sem abrir o aplicativo:

```bash
bash scripts/rodar-iphone.sh --check
```

Se o comando pedir um iPhone no Device Hub, selecione o modelo, clique **Start** e execute novamente.

Em 28/10/2026, o usuário solicitou e confirmou a liberação do Atlas para todos os IPv4 (`0.0.0.0/0`) durante os testes. Enquanto essa regra estiver ativa, não é necessário atualizar o IP ao mudar de rede. O banco continua exigindo autenticação e TLS. Se a preparação falhar, confira a conexão de internet e o estado dos serviços.

## O que foi conferido

- Flutter e Xcode prontos para iOS; runtime do simulador instalado.
- Compilação iOS de depuração aprovada.
- Assinatura do aplicativo verificada com `codesign --verify --deep --strict`.
- Info.plist válido, com `_dartVmService._tcp` e a descrição de acesso para depuração, adicionados pelo Flutter.
- Instalação e abertura reais do app no iPhone 16e, com serviço de depuração e sincronização de arquivos ativos.
- Tela de login carregada após a consulta de sessão na API local. Os dois bancos passaram na verificação de prontidão antes da execução.
- Configurações de execução e tarefa preparatória reconhecidas pelo esquema da extensão Flutter instalada no VS Code. A instalação/execução do app foi testada com o comando Flutter equivalente; o clique em F5 na interface do VS Code não foi automatizado nesta conferência.

Não foi concluído um login pela interface nativa nesta conferência. A tela de entrada e sua conexão inicial com a API foram verificadas. A sessão nativa continua em memória: ao encerrar/reiniciar o aplicativo, entre novamente com a mesma conta para retomar o histórico. Os testes de autenticação e trilhas dos bancos constam em `REVISAO.md`.

## Correção da pasta OneDrive

A primeira compilação falhou porque o diretório gerado `Flutter.framework` recebeu `com.apple.FinderInfo`, recusado pela assinatura do iOS. O código-fonte permanece na pasta original. O script `scripts/prepare-ios.mjs` mantém `frontend/build` como um link para um cache temporário fora do OneDrive, ignorado pelo Git. A compilação e a execução posteriores passaram sem desativar assinatura ou proteções do iOS.

Os artefatos antigos foram preservados em `.local/ios-build-backups`. O script recria o cache caso o macOS o remova. Não mova manualmente arquivos de código para esse cache.

O preparo também pode ser executado na raiz:

```sh
node scripts/prepare-ios.mjs
```

Ele reutiliza a API existente ou a inicia em segundo plano, aguardando MongoDB e Neo4j. Se iniciada pelo script, a saída fica em `.local/api-ios.log`.

Fontes: [configuração iOS do Flutter e Device Hub](https://docs.flutter.dev/platform-integration/ios/setup), [depuração iOS e rede local](https://docs.flutter.dev/platform-integration/ios/ios-debugging), [explicação da Apple para metadados recusados na assinatura](https://developer.apple.com/library/archive/qa/qa1940/_index.html).
