# Trilha — front-end

Aplicativo Flutter do Projeto Integrador IV, Time 13. Versão inicial do front-end, com entrada pelo login e navegação por perfil.

Para configurar outro computador do grupo com um único arquivo de credenciais, siga o [README da raiz](../README.md). O arquivo recebido fica em `backend/.env`; as senhas dos bancos não são colocadas no frontend.

## Executar e validar

```sh
flutter pub get
flutter run -d chrome --web-port=5173 --dart-define=API_BASE_URL=http://127.0.0.1:3000
flutter test
flutter analyze
flutter build web
```

Também foram preservados os projetos Android, iOS, macOS, Linux e Windows. Cada plataforma requer seu ambiente de desenvolvimento; a integração foi validada com testes Flutter e compilação web. Os identificadores nativos `com.example.trilha` são provisórios para desenvolvimento.

Inicie a API em `../backend/` antes do aplicativo. Veja o guia em `../backend/README.md`.

## Fluxos disponíveis

- Login com escolha de estudante/professor, validação de e-mail e senha e saída que limpa a navegação anterior.
- Cadastro com validação dos campos, consentimento inicialmente desmarcado e preservação do perfil escolhido.
- Introdução ao diagnóstico e questões carregadas da API, com correção pelo grafo quando há gabarito.
- Estudante: início, trilha, material, prática com correção e resumo, progresso, detalhes por disciplina e tópico, conquistas, notificações e perfil.
- Professor: painel, busca local de turmas, detalhes da turma selecionada, detalhes de cada estudante, relatórios e perfil.
- Marcação local das notificações como lidas e preferências visuais de perfil.

## Estado dos dados

Cadastro e autenticação persistem no MongoDB Atlas. A API retorna o perfil e o nome real da conta. No navegador, a sessão usa cookie HttpOnly e é restaurada por até 12 horas; sair revoga as sessões da conta. A navegação também confere o perfil. No cliente nativo, o token continua apenas em memória. Neste ambiente local, o cadastro de professor está habilitado para testes, além das contas fictícias já preparadas. O vínculo escolar ainda não é verificado; a configuração padrão para outras instalações desativa esse cadastro.

Prática e diagnóstico usam trilhas salvas no MongoDB e consultam as questões do Neo4j Aura, sem perguntas fixas nas telas. A correção acontece no servidor e informa quando o grafo ainda não tem gabarito. Imagens referenciadas no grafo ainda exigem integração dos arquivos de mídia.

Percentuais, recomendações, alunos, turmas e relatórios continuam demonstrativos. As atividades persistem respostas e trilhas no MongoDB, com reforço por erros e exploração após todos os acertos. O painel geral de XP ainda é demonstrativo. A seleção de turma mantém os exemplos da versão anterior.

Verificação de e-mail, autenticação Google, recuperação de senha e preferências persistentes ainda estão pendentes. As senhas dos bancos ficam somente no backend; o aplicativo recebe um token de sessão.

## Organização

- `lib/main.dart`: entrada do aplicativo.
- `lib/src/app.dart`: rotas e tema.
- `lib/src/telas/autenticacao/`: autenticação, cadastro e diagnóstico.
- `lib/src/telas/estudante/`: telas de estudante e dados locais de disciplinas.
- `lib/src/telas/professor/`: telas de professor e modelos de turmas/alunos.
- `lib/src/theme.dart` e `widgets.dart`: identidade visual e componentes compartilhados.
- `test/`: testes de navegação, formulários e comportamento local.
- `lib/src/services/api_service.dart`: conexão HTTP, sessão e modelos de usuário.
- `lib/src/graph_quiz_screen.dart`: questões e correção pela API.
- `docs/BACKEND.md`: integração atual e pendências.

Os arquivos de tela usam `part` e os arquivos `telas_autenticacao.dart`, `telas_estudante.dart` e `telas_professor.dart` são suas bibliotecas de entrada.

## OneDrive neste Mac

O analisador desta versão do Flutter apresentou erro interno ao processar o caminho com acentos do OneDrive. A análise foi executada em cópia temporária com caminho simples. Se o problema ocorrer, execute a validação em uma cópia fora do OneDrive. Nenhum link de build ou caminho particular da máquina é necessário no repositório.

Veja `../TESTAR_TRILHAS.md` para testar os dois caminhos da geração de trilhas.

A trilha apresenta conteúdos em um caminho alternado, com etapas disponíveis, concluídas e bloqueadas. Cada conteúdo abre teoria e depois prática; leitura e respostas ficam no MongoDB. Materiais ainda não publicados aparecem em preparação. As telas estão em `content_trail_map.dart`, `content_stage_screen.dart` e `user_trail_view.dart`.
