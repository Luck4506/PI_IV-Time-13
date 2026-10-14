# Integração futura com o back-end

As telas e rotas estão prontas para navegação com exemplos locais. Ainda não existe contrato de API neste repositório; nenhum endpoint foi inventado. A próxima etapa é definir os contratos e introduzir serviços/repositórios para substituir os dados demonstrativos.

| Área | Situação atual | Integração necessária |
| --- | --- | --- |
| Login/cadastro | Validação local e navegação por perfil | Autenticação, cadastro, erros, sessão, recuperação de senha e Google |
| Perfil | Marina/Ana e preferências locais | Dados do usuário, edição, metas, avatar, consentimentos e persistência |
| Diagnóstico | Perguntas locais e resultado fixo | Salvar respostas, calcular resultado e gerar trilha |
| Trilha/material | Conteúdo e bloqueios de exemplo | Conteúdos, pré-requisitos, desbloqueio, favoritos e recomendações |
| Prática | Seleção, correção e resumo locais | Banco de questões, envio de respostas, progresso, XP e adaptação |
| Progresso/conquistas | Percentuais e medalhas de exemplo | Estatísticas, revisões, missões e recompensas reais |
| Notificações | Lista e marcação de leitura locais | Busca, estado de leitura persistente e preferências |
| Turmas | Busca local; identificação e indicadores por turma | Turmas reais, matrícula, criação, filtros, mapa e estudantes por turma |
| Alunos | Perfis demonstrativos distintos | Desempenho individual, intervenções e acompanhamento |
| Relatórios | Tela com indicadores de exemplo | Filtros, geração, exportação e compartilhamento |

## Pontos de entrada no código

- `telas/autenticacao/tela_entrada.dart`: substituir `_continue` pela autenticação e tratar carregamento/erro antes de navegar.
- `telas/autenticacao/tela_cadastro.dart`: enviar os dados validados, definir termos/política reais e só continuar após confirmação do serviço.
- `telas/autenticacao/tela_questoes_diagnostico.dart` e `tela_resultado_diagnostico.dart`: enviar respostas e apresentar o resultado retornado.
- `telas/estudante/dados_progresso_disciplinas.dart`: dados de disciplinas e tópicos.
- `telas/professor/dados_turma.dart` e `tela_detalhes_estudante.dart`: modelos/exemplos de turma e estudante.
- Demais indicadores e conteúdos ainda estão próximos das respectivas telas, como no projeto de origem. Extraí-los conforme os contratos forem definidos.
- `widgets.dart`: `showPendingFeature` identifica ações ainda não integradas.

Ao conectar os serviços, implementar carregamento, lista vazia, erro e nova tentativa; atualizar os modelos conforme o contrato real; substituir nomes e indicadores fixos; vincular cada turma aos seus próprios alunos; testar permissões no servidor. Retirar o aviso de acesso local do login somente quando autenticação e persistência estiverem integradas.

As rotas do front-end não são controle de autorização. A validação de senha é apenas local (mínimo de oito caracteres); alinhar as regras definitivas com o serviço. A aplicação atual não armazena senhas nem tokens.
