# Aplicativo Gabariteii

O app usa Flutter no iPhone. Na raiz do projeto, `node scripts/iniciar.mjs` inicia o Node e abre o simulador. Para executar com o validador externo, usar outro dispositivo ou mudar o endereço da API, siga a [instalação do projeto](../README.md).

## Arquivos do Flutter

| Caminho | Conteúdo |
| --- | --- |
| `lib/main.dart` e `lib/src/app.dart` | Entrada, tema e navegação |
| `lib/src/telas/` | Cadastro, login e áreas de aluno e professor |
| `lib/src/services/` | Pedidos TCP, sessão, atividade e turmas |
| `assets/images/` | Logo do Gabariteii e ilustração da turma |
| `ios/Runner/Assets.xcassets/` | Ícones e recursos do projeto iOS |
| `test/` e `integration_test/` | Testes de telas, lógica e execução no aparelho |

## Verificar no iPhone

Na pasta `frontend/`, instale as dependências com `flutter pub get`. Abra um simulador e copie o ID mostrado por `flutter devices`.

```sh
flutter test integration_test/iphone_test.dart -d ID_DO_SIMULADOR
```

A suíte abre o app no iPhone simulado e percorre a área do aluno e a busca nos quartis. As telas recebem dados em memória por TCP.

Para incluir cadastro, login e sessão no Node, instale primeiro as dependências com `npm ci` em `backend/`. Em outro terminal, dentro de `frontend/`, rode `node integration_test/servidor_local.mjs`. Deixe o servidor aberto e use a porta que ele imprimir. A suíte usa contas em memória e simula a resposta do validador.

```sh
flutter test integration_test/iphone_test.dart -d ID_DO_SIMULADOR --dart-define=GABARITEII_QA_NODE_PORT=PORTA
```

Rode também `flutter analyze` e `flutter test` para conferir o código e a suíte do Flutter. [Configuração da conexão com a API](docs/BACKEND.md)
