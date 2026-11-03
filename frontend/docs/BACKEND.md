# Integração com a API

A API está em `../../backend/`. O Flutter usa `lib/src/services/api_service.dart`, com endereço configurável por `--dart-define=API_BASE_URL=...`. O padrão é `http://127.0.0.1:3000`.

| Área | Integração atual | Pendente |
| --- | --- | --- |
| Login/cadastro | Cadastro real no MongoDB, autenticação, erros, carregamento, sessão e logout | Verificação de e-mail, recuperação de senha, Google, publicação dos termos reais e verificação escolar |
| Perfil | Nome, e-mail, perfil e campo escolar retornados pela API | Formulário visual de edição; a API já oferece PATCH /api/usuarios/me |
| Diagnóstico e prática | Questões corrigíveis do Neo4j, correção no servidor, respostas e histórico persistidos no MongoDB | Imagens e seleção por série quando houver essa classificação no catálogo |
| Trilha | Caminho visual por conteúdos, material e prática, bloqueio sequencial, reforço por erros e progresso salvo no MongoDB | Regras pedagógicas mais avançadas |
| Material | Exemplos da versão anterior | Conteúdos completos, desbloqueio e favoritos |
| Progresso/conquistas | Indicadores demonstrativos | Cálculo e persistência de estatísticas, XP e medalhas |
| Notificações | Marcação local | Busca e preferências persistentes |
| Turmas/alunos/relatórios | Exemplos da versão anterior | Dados reais, matrículas, permissões escolares e exportação |

## Separação dos bancos

MongoDB Atlas armazena cadastro, autenticação, trilhas, referências às questões, materiais, leituras, respostas, resultados e histórico por usuário. O catálogo de enunciados, alternativas, gabaritos e relações de conteúdo fica no Neo4j Aura, que o aplicativo apenas consulta. As correções usadas em cada tentativa também são registradas no MongoDB para preservar o histórico.

O cadastro oferece um seletor de ano escolar, do 6º ano ao 3º ano do Ensino Médio, mais Outro.

## Segurança e testes

A API valida dados, protege senhas com scrypt, exige token nos endpoints de dados e não permite promover o próprio perfil via PATCH. O ambiente local permite cadastro de professor para testes; a configuração padrão de novas instalações o desativa. O campo de código escolar ainda não valida vínculo institucional.

No navegador, um cookie HttpOnly mantém a sessão por até 12 horas. Ao abrir, o app confirma a conta na API. Sessão inválida volta ao login; indisponibilidade permite tentar novamente. A navegação confere estudante/professor. O token não é salvo no localStorage. No cliente nativo o Bearer continua em memória, com novo login após reabrir. O backend usa credenciais locais em .env, fora do Git. O Flutter não contém credenciais dos bancos.

Os testes de interface usam uma API simulada. O script backend/scripts/smoke.js verifica os bancos reais, cria e remove uma conta fictícia temporária e confirma cadastro, login, perfil, logout, leitura do grafo e separação de coleções. O resultado fica em .local/VERIFICACAO.json.

As novas rotas `/api/trilhas` estão documentadas no backend. O exemplo completo fica em `TESTAR_TRILHAS.md`; `backend/scripts/verify-trails-live.js` testa os bancos reais e confirma que o grafo continua inalterado.
