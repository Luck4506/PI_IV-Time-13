# Bancos configurados — 27/10/2026

## Testar agora

- Aplicativo: http://127.0.0.1:5173
- Estado dos bancos pela API: http://127.0.0.1:3000/health/ready
- Contas fictícias de estudante e professor: `.local/ACESSOS_DE_TESTE.md`.
- Para criar outro usuário de teste, use **Ainda não tenho uma conta** no aplicativo. O cadastro de estudante e professor está habilitado neste ambiente local; o código escolar é informativo e ainda não verifica vínculo institucional.

O app e a API estão executando neste Mac. Mantenha-os abertos durante os testes. Os bancos ficam nos serviços de nuvem e os planos gratuitos podem pausar por inatividade. Para reiniciar os serviços locais, abra `Iniciar Trilha.command`.

## MongoDB Atlas

- Projeto: `Trilha-PI-IV`.
- Cluster: `Cluster`, plano Free / M0, AWS São Paulo.
- Banco: `trilha`; coleção: `usuarios`.
- Usuário da aplicação: `trilha_api`, com `readWrite` somente em `trilha`.
- Acesso de rede limitado ao IP público atual do computador.
- E-mail único, validação de campos e senha protegida com scrypt.
- Nenhuma coleção de questões ou respostas de atividades.

## Neo4j Aura

- Instância: `Trilha-Projeto-Integrador`, AuraDB Free.
- ID: `4e82e839`.
- Origem: `Projeto_integrador`, Neo4j Desktop 2026.09.0.
- Importação integral pelo dump original, usando a ferramenta oficial do Neo4j.

| Conteúdo conferido no Aura | Quantidade |
|---|---:|
| Nós | 93 |
| Disciplinas | 3 |
| Conteúdos | 45 |
| Questões | 45 |
| Relacionamentos | 134 |
| Restrições de unicidade | 3 |

As relações preservadas incluem `FAZ_PARTE_DE`, `ABORDA`, `MAIS_FACIL_QUE`, `MESMO_RACIOCINIO`, `MESMO_TEMA`, `PARECIDA_COM` e `MESMO_TEXTO_BASE`.

O banco original do Desktop foi preservado. O backup está em `backend/backups/projeto-integrador/neo4j.dump`, com checksum SHA-256 `df65f3dfb76a31a88ee561db5bd7f78cc09fc65b63a6715bb4559cd65242074d`. O manifesto do envio e o inventário do Aura estão na mesma pasta, fora do Git.

## Integração e verificação

O backend está em `backend/`. Cadastro, login, leitura do próprio perfil, atualização do próprio cadastro e logout usam o MongoDB. As telas de prática e diagnóstico buscam questões e correção no Neo4j pela API.

O teste real confirmou cadastro persistido, senha protegida, rejeição de e-mail duplicado, autenticação, perfil, logout, consulta das 45 questões e das três disciplinas, acesso dos dois perfis fictícios e presença exclusiva da coleção `usuarios` no MongoDB. O relatório sem senhas está em `.local/VERIFICACAO.json`.

No navegador também foram verificados login de estudante, abertura de uma questão do Aura e correção da alternativa pelo servidor.

Os indicadores de progresso, turmas e relatórios permanecem demonstrativos. As tentativas ainda não são salvas; não há cálculo adaptativo de trilha ou XP nesta etapa. As referências de imagens foram preservadas no grafo, mas os arquivos de mídia ainda não são exibidos no app. Autenticação Google e recuperação de senha continuam pendentes.

As credenciais estão em `backend/.env`, ignorado pelo Git. Use o usuário e o nome de banco informados pelo arquivo de credenciais do Aura; a instância atual utiliza seu ID nesses campos. Não coloque credenciais dos bancos no Flutter.

Para os comandos e contratos da API, consulte `backend/README.md`.
