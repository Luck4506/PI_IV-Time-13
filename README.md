# PI IV — Time 13

Plataforma **Trilha**, de aprendizagem adaptativa e gamificada.

Para o servidor Java, consulte o [guia de execução e testes](docs/EXECUCAO_SERVIDOR.md) e o [contrato de cadastro e login](docs/CONTRATO_SERVIDOR.md). A integração com Node HTTP e Flutter deve seguir esses documentos; as instruções de frontend abaixo descrevem a versão presente nesta branch.

O front-end Flutter está em [`frontend/`](frontend/). A versão inicial reúne os fluxos de estudante e professor, com entrada única pelo login.

## Executar

Requer Flutter 3.47.2 / Dart 3.13.2 ou versão compatível com o `pubspec.yaml`.

```sh
cd frontend
flutter pub get
flutter run -d chrome
```

O aplicativo abre no login. Escolha Estudante ou Professor e use **Entrar**. Os campos já vêm com dados fictícios. Cadastro e diagnóstico também podem ser percorridos, sem criar uma conta real.

Veja [instruções do front-end](frontend/README.md) e [pendências de integração](frontend/docs/BACKEND.md).
