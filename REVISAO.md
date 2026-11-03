# Revisão dos fluxos implementados — 28/10/2026

Revisão concluída para cadastro, login, sessão Web, proteção das telas, trilhas por conteúdos, leitura, prática e persistência nos bancos. API e aplicativo local permaneceram em execução ao final.

## Correções feitas nesta revisão

- A exploração não reinsere uma questão já acertada na atividade anterior ao reunir outras questões do mesmo conteúdo. A revisão por erros pode retomar a questão da dificuldade, como prática desse conteúdo.
- Respostas inválidas da API e dados incompletos de conta agora produzem erros recuperáveis. Um perfil desconhecido não autentica.
- Uma resposta 401 encerra a sessão mesmo quando vem sem JSON. Uma resposta atrasada da sessão anterior não encerra um login novo nem apaga seu cookie.
- Confirmações simultâneas da primeira leitura usam o mesmo registro no MongoDB, sem erro de e-mail duplicado.
- A API permanece acessível durante uma falha de conexão, bloqueia operações até inicializar o MongoDB e tenta reconectar. O login não depende da disponibilidade do Neo4j.
- Inicialmente, a regra do Atlas foi substituída pelo IP da nova rede. Posteriormente, em 28/10/2026, o usuário solicitou e confirmou a liberação para todos os IPv4 (`0.0.0.0/0`) durante os testes. Autenticação e TLS permanecem obrigatórios; API, MongoDB e Neo4j passaram novamente na verificação de prontidão.
- A nova rede recusava a consulta DNS SRV do Atlas. A configuração local passou a usar a conexão padrão do mesmo cluster, com seus três hosts, autenticação e TLS. Essa alternativa é documentada pelo [MongoDB Atlas](https://www.mongodb.com/docs/atlas/troubleshoot-connection/). Não houve mudança do DNS do computador.

## Conferência

| Verificação | Resultado |
| --- | --- |
| Testes da API e recomendação | 20 aprovados |
| Testes Flutter, sessão e conteúdos | 27 aprovados |
| Análise estática do Flutter | Sem problemas |
| Compilação Web de produção | Aprovada |
| Dependências de produção do backend | npm audit: nenhuma vulnerabilidade conhecida reportada |
| Cadastro, senha protegida, e-mail duplicado, login, perfil e logout nos bancos reais | Aprovados |
| Reutilização das duas contas existentes, restauração por cookie, perfil e isolamento | Aprovados |
| Diagnóstico com erro e diagnóstico com todos os acertos | Aprovados |
| Conclusão das seis etapas e geração da continuação | Aprovadas |
| Criação, resposta final e leitura simultâneas | Aprovadas, sem duplicar registros |
| Bloqueio da próxima etapa e leitura antes da prática | Aprovados na API e na interface |
| Conteúdo sem material publicado | Exibe preparação e mantém a prática disponível |
| Navegador real | Login, recuperação após falha de rede, leitura previamente salva, resposta salva, conclusão e próxima etapa liberada |
| Sessão e progresso após atualizar a página | Preservados |
| Prontidão da API | MongoDB e Neo4j conectados |

O grafo mantém **93 nós e 134 relacionamentos**, com 45 questões, 45 conteúdos e 3 disciplinas. Rótulos, tipos de relacionamentos, índices e restrições conferem com o inventário da migração. A comparação integral das propriedades de nós e relacionamentos antes e depois dos testes também passou. As operações da aplicação no Neo4j continuam apenas de leitura; os dados de uso ficam no MongoDB.

Os testes reais acrescentaram exemplos ao histórico da conta fictícia. Uma etapa da trilha normal dessa conta foi concluída pela interface para conferir o desbloqueio; a próxima ficou disponível. A conta temporária do teste de cadastro foi removida pelo próprio teste. Contas existentes e seus históricos foram preservados.

## Limites que permanecem

- Verificação de e-mail não foi implementada, conforme solicitado. Recuperação por e-mail e login Google continuam pendentes.
- Há três materiais teóricos de Física para demonstração. Os demais aguardam publicação do material.
- Imagens e partes gráficas dos enunciados dependem da integração dos arquivos do catálogo. Cinco questões sem gabarito continuam preservadas e ficam fora da prática corrigível.
- XP, conquistas, estatísticas gerais, turmas e relatórios ainda têm dados demonstrativos. O vínculo escolar do professor não é validado.
- A sessão persistente foi conferida no navegador. A versão nativa mantém o token em memória e exige login ao reabrir; não foi testada em aparelho nesta revisão.
- Os bancos estão na nuvem, mas API e Flutter rodam neste computador. Uma mudança de IP exige atualizar a regra restrita do Atlas. Publicação externa ainda exige HTTPS e configuração do ambiente publicado.

Relatórios sem senhas em `.local/VERIFICACAO.json`, `.local/VERIFICACAO_AUTENTICACAO.json`, `.local/VERIFICACAO_TRILHAS.json`, `.local/REVISAO_GRAFO.json` e `.local/REVISAO_FINAL.json`. Os testes reais de autenticação e trilhas devem rodar em sequência, pois o logout revoga sessões usadas na conferência de isolamento.
