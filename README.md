# PI IV — Time 13

Plataforma **Trilha**, de aprendizagem adaptativa e gamificada.

O front-end Flutter está em [`frontend/`](frontend/). A versão inicial reúne os fluxos de estudante e professor, com entrada única pelo login.

## Executar

Requer Flutter 3.47.2 / Dart 3.13.2 ou versão compatível com o `pubspec.yaml`.

```sh
cd frontend
flutter pub get
flutter run -d chrome
```

O aplicativo abre no login e exige uma conta real da API. Cadastro, autenticação e perfil usam MongoDB Atlas; prática e diagnóstico carregam questões do Neo4j Aura.

Execute a API em `backend/` e o Flutter Web na porta 5173 conforme o [guia do backend](backend/README.md). No macOS, `Iniciar Trilha.command` abre os serviços locais. Os indicadores acadêmicos e as turmas ainda contêm exemplos; progresso, respostas e trilhas adaptativas ainda não são persistidos.

Veja [instruções do front-end](frontend/README.md) e [pendências de integração](frontend/docs/BACKEND.md).
