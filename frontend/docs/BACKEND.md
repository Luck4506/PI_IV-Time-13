# Integração com a API

A API está em `../../backend/`. O Flutter usa `lib/src/services/api_service.dart`, com endereço configurável por `--dart-define=API_BASE_URL=...`. O padrão é `http://127.0.0.1:3000`.

| Área | Integração atual | Pendente |
| --- | --- | --- |
| Login/cadastro | Cadastro real no MongoDB, autenticação, erros, carregamento, sessão e logout | Recuperação de senha, Google, publicação dos termos reais e verificação escolar |
| Perfil | Nome, e-mail, perfil e campo escolar retornados pela API | Formulário visual de edição; a API já oferece PATCH /api/usuarios/me |
| Diagnóstico e prática | Questões do Neo4j e correção no servidor quando há gabarito | Persistência de tentativas, imagens, seleção adaptativa e geração de trilha |
| Trilha/material | Telas de exemplo da versão anterior | Conteúdos e pré-requisitos reais, desbloqueio e favoritos |
| Progresso/conquistas | Indicadores demonstrativos | Cálculo e persistência de estatísticas, XP e medalhas |
| Notificações | Marcação local | Busca e preferências persistentes |
| Turmas/alunos/relatórios | Exemplos da versão anterior | Dados reais, matrículas, permissões escolares e exportação |

## Separação dos bancos

MongoDB Atlas armazena somente cadastro e dados de autenticação de usuários. Questões, alternativas, gabaritos e relações de conteúdo ficam no Neo4j Aura. Nenhuma resposta de atividade é gravada no MongoDB.

## Segurança e testes

A API valida dados, protege senhas com scrypt, exige token nos endpoints de dados e não permite promover o próprio perfil via PATCH. O ambiente local permite cadastro de professor para testes; a configuração padrão de novas instalações o desativa. O campo de código escolar ainda não valida vínculo institucional.

O token fica em memória; recarregar o navegador exige login novamente. O backend usa credenciais locais em .env, fora do Git. O Flutter não contém credenciais dos bancos.

Os testes de interface usam uma API simulada. O script backend/scripts/smoke.js verifica os bancos reais, cria e remove uma conta fictícia temporária e confirma cadastro, login, perfil, logout, leitura do grafo e separação de coleções. O resultado fica em .local/VERIFICACAO.json.
