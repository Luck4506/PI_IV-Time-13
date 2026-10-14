# Trilha — front-end

Aplicativo Flutter do Projeto Integrador IV, Time 13. Versão inicial do front-end, com entrada pelo login e navegação por perfil.

## Executar e validar

```sh
flutter pub get
flutter run -d chrome
flutter test
flutter analyze
flutter build web
```

Também foram preservados os projetos Android, iOS, macOS, Linux e Windows. Cada plataforma requer seu ambiente de desenvolvimento; a integração foi validada com testes Flutter e compilação web. Os identificadores nativos `com.example.trilha` são provisórios para desenvolvimento.

## Fluxos disponíveis

- Login com escolha de estudante/professor, validação de e-mail e senha e saída que limpa a navegação anterior.
- Cadastro com validação dos campos, consentimento inicialmente desmarcado e preservação do perfil escolhido.
- Introdução, questões e resultado demonstrativo do diagnóstico.
- Estudante: início, trilha, material, prática com correção e resumo, progresso, detalhes por disciplina e tópico, conquistas, notificações e perfil.
- Professor: painel, busca local de turmas, detalhes da turma selecionada, detalhes de cada estudante, relatórios e perfil.
- Marcação local das notificações como lidas e preferências visuais de perfil.

## Estado dos dados

O login informa que o acesso ainda usa dados locais de exemplo. Login não autentica; cadastro não cria contas. Os nomes dos perfis continuam sendo Marina e Ana, independentemente dos campos preenchidos. Interações locais não persistem depois de reiniciar o app e algumas reiniciam ao sair da tela.

Prática usa questões locais. Diagnóstico, percentuais, recomendações, alunos e relatórios usam exemplos do app original; responder ao diagnóstico não calcula uma trilha real. A seleção de turma atualiza identificação e indicadores, enquanto mapa de domínio e lista de estudantes ainda compartilham exemplos demonstrativos.

Operações dependentes de serviços mostram um aviso de indisponibilidade; etapas bloqueadas da trilha continuam bloqueadas. Não há chamadas externas, credenciais, envio de e-mails ou autenticação Google.

## Organização

- `lib/main.dart`: entrada do aplicativo.
- `lib/src/app.dart`: rotas e tema.
- `lib/src/telas/autenticacao/`: autenticação, cadastro e diagnóstico.
- `lib/src/telas/estudante/`: telas de estudante e dados locais de disciplinas.
- `lib/src/telas/professor/`: telas de professor e modelos de turmas/alunos.
- `lib/src/theme.dart` e `widgets.dart`: identidade visual e componentes compartilhados.
- `test/`: testes de navegação, formulários e comportamento local.
- `docs/BACKEND.md`: pontos a integrar quando o back-end estiver disponível.

Os arquivos de tela usam `part` e os arquivos `telas_autenticacao.dart`, `telas_estudante.dart` e `telas_professor.dart` são suas bibliotecas de entrada.

## OneDrive neste Mac

O analisador desta versão do Flutter apresentou erro interno ao processar o caminho com acentos do OneDrive. A análise foi executada em cópia temporária com caminho simples. Se o problema ocorrer, execute a validação em uma cópia fora do OneDrive. Nenhum link de build ou caminho particular da máquina é necessário no repositório.
