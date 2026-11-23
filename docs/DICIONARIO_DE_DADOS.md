# Dicionário de Dados do Gabariteii · MongoDB

Projeto Integrador IV da PUC-Campinas · Time 13

## 1. Histórico de versões

| Data | Autor | Versão | Comentários |
| --- | --- | --- | --- |
| 22/11/2026 | Lucas Soares Gonçalves | 1.0.0 | Esquema do MongoDB, regras de negócio, referências e índices da entrega. |

## 2. Entidades e atributos conceituais

O MongoDB armazena contas, vínculos escolares, trilhas e progresso. O Neo4j mantém o catálogo de questões, as relações entre conteúdos e os materiais atuais. Nas tabelas, a obrigatoriedade se refere ao estado da entidade descrito na linha. Os exemplos são fictícios.

### 2.1. Usuário

Representa uma conta de aluno ou professor. O perfil determina as telas e operações disponíveis após o login.

| Atributo / dado | Tipo conceitual | Obrigatório | Característica | Ex. aceito | Ex. não aceito | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| Identificador | Identificador | Sim | Simples | Identificador único gerado pelo MongoDB | E-mail como chave primária | Identifica a conta mesmo ao atualizar o nome. |
| Nome | Texto | Sim | Simples | Ana Silva | A | De 2 a 120 caracteres após remover espaços nas extremidades. |
| E-mail | Texto | Sim | Simples | ana@teste.example | ana@ | Único, convertido para minúsculas. Limite de 254 caracteres. |
| Perfil | Enumeração | Sim | Simples | Aluno | Coordenador | Aluno ou professor. |
| Senha protegida | Texto | Sim | Simples | Representação com salt e derivação scrypt | Senha em texto claro | O backend armazena o hash e verifica a senha recebida. |
| Ano escolar | Enumeração | Para aluno novo | Simples | 2º ano do Ensino Médio | 4º ano do Ensino Médio | Anos 1 a 3 ou Outro. |
| Escola | Referência | Para professor e cadastro educacional | Simples | ESCOLA-AVAL-001 | Código de escola inexistente | O cadastro exige uma escola ativa quando há vínculo educacional. |
| Aceite, criação e atualização | Data e hora | Sim | Simples, uma por evento | 22/11/2026 às 09h | Texto livre | Mantém as datas do aceite dos termos e das alterações da conta. |
| Versão da sessão | Inteiro | Sim | Simples | 0 | “primeira” | Começa em zero. Logout e troca de senha avançam a versão e revogam os tokens antigos. |

A data de nascimento e o código de professor são entradas validadas durante o cadastro. A conta persistida guarda o aceite em data e hora, e o vínculo educacional pela referência à escola.

### 2.2. Escola

Organiza as opções de cadastro e vincula as turmas a uma instituição.

| Atributo / dado | Tipo conceitual | Obrigatório | Característica | Ex. aceito | Ex. não aceito | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| Código | Identificador textual | Sim | Simples | ESCOLA-AVAL-001 | Código duplicado | É a chave do documento. |
| Nome | Texto | Sim | Simples | Escola Horizonte | Nome vazio | Exibido na seleção de escola. |
| Ativa | Booleano | Sim | Simples | Verdadeiro | “sim” como texto | O cadastro lista escolas ativas. |
| Demonstração | Booleano | Não | Simples | Falso | “demo” como texto | Marcador legado. O aplicativo filtra as escolas marcadas como demonstração no cadastro. |

### 2.3. Turma

Agrupa alunos. Cada professor vinculado vê as respostas da disciplina que leciona.

| Atributo / dado | Tipo conceitual | Obrigatório | Característica | Ex. aceito | Ex. não aceito | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| Identificador | Identificador | Sim | Simples | Identificador único | ID de outra turma | Chave do documento. |
| Nome | Texto | Sim | Simples | 3º A — Matemática | A | Na criação, deve ter de 2 a 80 caracteres. |
| Escola | Referência | Sim | Simples | ESCOLA-AVAL-001 | Escola inexistente | A turma pertence à escola do professor que a criou. |
| Código de matrícula | Texto | Sim | Simples | A1B2C3D4E5F6 | TURMA123 | Doze caracteres hexadecimais em maiúsculas. Único e renovável pelo criador da turma. |
| Criador e data de criação | Referência e data | Sim | Simples, um por campo | Conta de professor e uma data | Conta de aluno como criador | O criador pode renovar o código e convidar docentes. |
| Docentes | Lista de vínculos | Sim | MC | Professor vinculado a Matemática | Docente de outra escola | Inclui o criador. A disciplina é guardada em cada vínculo. |
| Convite de docente | Convite | Quando gerado | C | Hash e vencimento em 24 horas | Código em texto claro | O convite válido é consumido quando um docente elegível entra. |

### 2.4. Matrícula

Representa o vínculo atual do aluno. O identificador do aluno é a chave, o que limita a matrícula a uma turma por conta.

| Atributo / dado | Tipo conceitual | Obrigatório | Característica | Ex. aceito | Ex. não aceito | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| Aluno | Referência | Sim | Simples | Conta com perfil de aluno | Conta de professor | Chave da matrícula. |
| Turma | Referência | Sim | Simples | Turma existente | Turma inexistente | O aluno pode entrar durante o cadastro ou pelo perfil. |
| Ingresso | Data e hora | Sim | Simples | 22/11/2026 às 09h | Data ausente | O relatório inclui respostas da disciplina feitas desde a matrícula. |

### 2.5. Disciplina do professor

Registra a disciplina escolhida pelo docente. A escolha é única por professor e baseia-se no catálogo disponível.

| Atributo / dado | Tipo conceitual | Obrigatório | Característica | Ex. aceito | Ex. não aceito | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| Professor | Referência | Sim | Simples | Conta de professor | Conta removida | Chave do documento. |
| Disciplina | Texto de catálogo | Sim | Simples | Matemática | Nome fora do catálogo | Validada no Neo4j. |
| Criação | Data e hora | Sim | Simples | Data em que fez a escolha | “novembro” | A escolha já gravada é preservada em reenvios. |

### 2.6. Trilha

Registra uma atividade de estudo e suas respostas na ordem planejada. Pode fazer parte de uma sequência iniciada por diagnóstico ou prática.

| Atributo / dado | Tipo conceitual | Obrigatório | Característica | Ex. aceito | Ex. não aceito | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| Identificador e usuário | Identificadores | Sim | Simples, um por campo | ID da trilha e conta de aluno existente | Trilha sem usuário | O usuário é o dono do histórico. |
| Tipo | Enumeração | Sim | Simples | Revisão | Simulado integral | Diagnóstico, prática, revisão ou exploração. |
| Modo | Enumeração | Sim | Simples | Normal | Público | Normal ou exemplo. Atividade e relatórios consideram o modo normal. |
| Estado | Enumeração | Sim | Simples | Em andamento | Concluída com questões sem resposta | A última resposta conclui a trilha. |
| Versão | Inteiro positivo | Sim | Simples | 2 | 0 | Incrementada ao salvar uma resposta. Protege contra sobrescrita por gravações simultâneas. |
| Chave de início | Texto | Ao iniciar pela API | Simples | chave-avaliacao-0001 | Chave repetida para criar outra trilha do mesmo usuário | De 16 a 100 caracteres na API. Repetir a chave devolve a trilha já criada. |
| Origem e continuação | Referências | Conforme a sequência | Simples, uma por campo | Referência a uma trilha da mesma conta | Origem em outra conta | Uma trilha concluída pode gerar uma continuação. |
| Itens | Lista de questões | Sim | MC | Questões vinculadas ao Neo4j com as respostas salvas | Lista vazia ou questão repetida na mesma trilha | O validador permite de 1 a 20 itens. |
| Criação e atualização | Data e hora | Sim | Simples, uma por evento | Data inicial e data do último avanço | Data inválida | Usadas na ordenação do histórico. |
| Conclusão | Data e hora | Quando concluída | Simples | Data da última resposta | Data de conclusão de trilha em andamento | Também alimenta o XP. |

### 2.7. Material de estudo legado

Representa uma explicação publicada em MongoDB nas instalações anteriores. O backend a consulta quando o material do subtema está indisponível no Neo4j.

| Atributo / dado | Tipo conceitual | Obrigatório | Característica | Ex. aceito | Ex. não aceito | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| Subtema | Identificador textual | Sim | Simples | ID derivado de Matemática e Geometria plana | ID de outro subtema | Identifica o mesmo conteúdo nas duas fontes. |
| Nome, disciplina, título e origem | Texto | Título sim. Demais campos conforme o documento legado | Simples, um por campo | Geometria plana · Matemática | Título vazio | Identifica o conteúdo e seu material didático. |
| Versão | Inteiro positivo | Sim | Simples | 1 | 0 | A leitura acompanha a versão publicada. |
| Publicado | Booleano | Sim para exibição | Simples | Verdadeiro | Falso para conteúdo que deve aparecer | A consulta filtra apenas o material publicado. |
| Blocos | Lista de blocos | Sim | MC | Título e texto de uma explicação | Lista vazia | Os blocos aparecem na ordem gravada. |
| Atualização | Data e hora | No lote de publicação | Simples | Data de publicação | Data inválida | Registra a preparação do material legado. |

### 2.8. Progresso de leitura

Registra que o aluno concluiu o material de um subtema dentro de uma trilha. A leitura libera a prática da etapa quando existe material publicado.

| Atributo / dado | Tipo conceitual | Obrigatório | Característica | Ex. aceito | Ex. não aceito | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| Identificador | Identificador | Sim | Simples | ID de um registro de leitura | ID duplicado | Chave primária. |
| Usuário, trilha e conteúdo | Referências | Sim | Simples, uma por campo | Conta, sua trilha e um subtema dessa trilha | Trilha de outra conta | A combinação é única. |
| Versão lida | Inteiro positivo | Sim | Simples | 2 | Versão negativa | O registro preserva a maior versão gravada. |
| Criação e conclusão da leitura | Data e hora | Sim | Simples, uma por evento | Data da leitura | Ausência de data de leitura | Mantém a data inicial e a maior data de confirmação de leitura. |

### 2.9. Estado de leitura das notificações

Marca até quando as notificações de conquistas foram lidas. As notificações em si são calculadas a partir das trilhas, das respostas e das datas das conquistas.

| Atributo / dado | Tipo conceitual | Obrigatório | Característica | Ex. aceito | Ex. não aceito | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| Usuário | Referência | Sim | Simples | ID da conta | ID de turma | Chave do documento de leitura. |
| Lidas até | Data e hora | Sim | Simples | Data em que marcou as notificações como lidas | “lidas” | Notificações conquistadas até essa data aparecem como lidas. |

### 2.10. Verificação de e-mail

Controla a confirmação de uma conta nova. O documento muda de pendente para confirmado quando o código e a senha são validados.

| Atributo / dado | Tipo conceitual | Obrigatório | Característica | Ex. aceito | Ex. não aceito | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| Usuário e e-mail | Referência e texto | Sim | Simples, um por campo | Conta e e-mail do cadastro | E-mail de outra conta | A referência ao usuário é a chave do documento. |
| Código pendente | Código temporário | Enquanto pendente | C | Hash SHA-256 com expiração | Código em texto claro no banco | O código vale por 30 minutos. Um novo envio pode ocorrer após um minuto. |
| Confirmação | Data e hora | Depois de confirmar | Simples | Data da confirmação válida | Data sem confirmação do código | Ao confirmar, remove-se o hash e as datas de controle do código. |

### 2.11. Recuperação de senha

Mantém um código temporário por conta. O uso válido consome o documento e troca a senha em uma transação.

| Atributo / dado | Tipo conceitual | Obrigatório | Característica | Ex. aceito | Ex. não aceito | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| Usuário | Referência | Sim | Simples | Conta cadastrada | Conta inexistente | Chave do documento. |
| Código de recuperação | Código temporário | Sim | C | Hash SHA-256 com data de expiração | Código já consumido | Vale por 30 minutos. A troca revoga as sessões antigas. |

## 3. Tipos especiais, compostos ou específicos

| Marcação | Significado |
| --- | --- |
| C | Valor composto por mais de um campo. |
| M | Lista de valores simples. |
| MC | Lista de valores compostos. |

### 3.1. Item de trilha e resposta

| Atributo / dado | Tipo | Obrigatório | Comentários |
| --- | --- | --- | --- |
| `questaoId` | Texto | Sim | Referência à questão no Neo4j. |
| `nome`, `disciplina` | Texto | Sim | Resumo da questão guardado na trilha. |
| `conteudos` | Lista de textos (M) | Sim | Subtemas associados à questão. |
| `motivo` | Objeto (C) | Sim | O planejador usa `tipo`, `origens`, `relacoes`, `pontuacao` e `descricao` para registrar por que escolheu o item. |
| `resposta.alternativa`, `resposta.gabarito` | Enumeração | Quando respondida | Letras A a E. O gabarito precisa corresponder a uma alternativa existente no catálogo. |
| `resposta.correta`, `resposta.corrigida` | Booleano | Quando respondida | Indicam acerto e correção registrada. |
| `resposta.respondidaEm` | Data e hora | Quando respondida | Usada para apurar desempenho e atividade. |

### 3.2. Vínculo de docente e convite

| Atributo / dado | Tipo | Obrigatório | Comentários |
| --- | --- | --- | --- |
| `docentes[].professorId` | Referência | Em cada vínculo | Conta com perfil de professor. |
| `docentes[].disciplina` | Texto | Em cada vínculo | Disciplina do professor na turma. |
| `conviteProfessor.hash` | Texto | Em cada convite | Hash SHA-256 do código de convite. |
| `conviteProfessor.expiraEm` | Data e hora | Em cada convite | Vencimento 24 horas após a geração. |

### 3.3. Bloco de material

| Atributo / dado | Tipo | Obrigatório | Comentários |
| --- | --- | --- | --- |
| `titulo` | Texto | Sim | Título do trecho. |
| `texto` | Texto | Sim | Explicação exibida na tela de leitura. |

### 3.4. Código temporário

| Atributo / dado | Tipo | Obrigatório | Comentários |
| --- | --- | --- | --- |
| `tokenHash` | Texto | Enquanto houver código ativo | Hash SHA-256 de um código aleatório de 32 bytes apresentado ao usuário em Base64URL. |
| `expiraEm` | Data e hora | Enquanto houver código ativo | Vence 30 minutos após a geração. |
| `reenviarDepoisDe` | Data e hora | Enquanto houver código ativo | Libera um novo envio depois de um minuto. |

## 4. Desdobramento físico ou tecnológico

### 4.1. MongoDB orientado a documentos

As referências de conta e turma usam BSON `ObjectId`. As datas usam BSON `Date` e os contadores usam BSON `Int32`. O estado é armazenado em campos de texto ou booleanos de acordo com a tabela.

| Entidade | Coleção | Campos físicos e estratégia |
| --- | --- | --- |
| Usuário | `usuarios` | `_id`, `nome`, `email`, `perfil` (`student`, `teacher`), `senhaHash`, `anoEscolar`, `codigoEscola`, `termosAceitosEm`, `criadoEm`, `atualizadoEm`, `tokenVersion`. `codigoEscola` é texto. |
| Escola | `escolas` | `_id` textual, `nome`, `ativa` e `demonstracao` opcional. |
| Turma | `turmas` | `_id`, `nome`, `codigoEscola` textual, `codigo`, `criadoPor`, `criadoEm`, `docentes[]` e `conviteProfessor` opcional. Vínculos de docentes e convite são embutidos. |
| Matrícula | `turmas_alunos` | `_id` é o ID do aluno. `turmaId` referencia a turma e `ingressouEm` marca o início do vínculo. |
| Disciplina do professor | `professores_disciplinas` | `_id` é o ID do professor. `disciplina` é texto e `criadoEm` é a data da escolha. |
| Trilha | `trilhas` | `_id`, `usuarioId`, `tipo` (`diagnostico`, `pratica`, `revisao`, `exploracao`), `modo` (`normal`, `exemplo`), `status` (`em_andamento`, `concluida`), `versao`, `chave`, `origemId`, `proximaTrilhaId`, `itens[]`, `criadoEm`, `atualizadoEm`, `concluidaEm`. Questões são referenciadas por texto e as respostas ficam embutidas nos itens. |
| Material de estudo legado | `materiais_conteudo` | `_id` textual, `nome`, `disciplina`, `titulo`, `versao`, `publicado`, `origem`, `atualizadoEm`, `blocos[]` embutidos. O ID deriva da disciplina e do nome do subtema. |
| Progresso de leitura | `progresso_conteudos` | `_id`, `usuarioId`, `trilhaId`, `conteudoId` textual, `materialVersao`, `criadoEm`, `leituraConcluidaEm`. |
| Estado de notificações | `notificacoes_usuario` | `_id` é o ID do usuário e `lidasAte` é a data-limite de leitura. |
| Verificação de e-mail | `verificacoes_email` | `_id` é o ID do usuário. `email`, `tokenHash`, `expiraEm`, `reenviarDepoisDe`, `confirmadoEm`. |
| Recuperação de senha | `recuperacoes_senha` | `_id` é o ID do usuário. `tokenHash`, `expiraEm`, `reenviarDepoisDe`. |

Exemplo de uma trilha em andamento, em MongoDB Extended JSON:

```json
{
  "_id": { "$oid": "100000000000000000000001" },
  "usuarioId": { "$oid": "100000000000000000000002" },
  "tipo": "pratica",
  "modo": "normal",
  "status": "em_andamento",
  "versao": { "$numberInt": "1" },
  "chave": "chave-avaliacao-0001",
  "itens": [
    {
      "questaoId": "VEST-ENEM-2018-D2-AZUL-Q122",
      "nome": "Dinâmica e energia",
      "disciplina": "Física",
      "conteudos": ["Dinâmica e energia"],
      "motivo": {
        "tipo": "inicial",
        "origens": [],
        "relacoes": [],
        "pontuacao": 0,
        "descricao": "Questão inicial da prática."
      }
    }
  ],
  "criadoEm": { "$date": "2026-11-22T12:00:00.000Z" },
  "atualizadoEm": { "$date": "2026-11-22T12:00:00.000Z" }
}
```

**Justificativa.** Itens e respostas são lidos juntos e têm quantidade limitada. Embuti-los permite atualizar uma resposta e o estado da trilha no mesmo documento. Contas, turmas e matrículas têm ciclos de vida e consultas próprios, por isso usam referências. A matrícula é indexada tanto pela conta quanto pela turma. Códigos de recuperação ficam separados da conta para permitir expiração automática. O backend usa transações ao cadastrar com matrícula ou confirmação e ao trocar a senha.

### 4.2. Desdobramento para banco relacional

A persistência documentada nesta entrega é a implementação em coleções do MongoDB, descrita na seção anterior.

## 5. Consultas, índices e observações de arquitetura

| Consulta ou regra | Campos | Índice usado | Observação |
| --- | --- | --- | --- |
| Buscar ou cadastrar conta pelo e-mail | `usuarios.email` | `email_unico`, único | A busca usa e-mail normalizado. |
| Confirmar endereço pelo hash | `verificacoes_email.tokenHash` | `link_de_confirmacao_unico`, único e esparso | Contas confirmadas já perderam o hash. |
| Buscar código de recuperação e expirar registros | `recuperacoes_senha.tokenHash`, `expiraEm` | `codigo_de_recuperacao_unico` e TTL `expiracao_dos_codigos` | A rota checa o vencimento antes de consumir, mesmo antes da limpeza pelo TTL. |
| Buscar histórico e trilha em andamento | `trilhas.usuarioId`, `modo`, `criadoEm`, `_id` e estado | `historico_por_modo` e `trilha_em_andamento`, parcial | O histórico lista as 30 atividades mais recentes do modo solicitado. |
| Repetir início e gerar continuação | `trilhas.usuarioId` + `chave`; `origemId` | `inicio_idempotente` e `uma_continuacao_por_trilha`, únicos e parciais | Evitam criar duas trilhas para a mesma operação ou origem. |
| Listar turmas do professor | `turmas.codigoEscola`, `docentes.professorId` | `turmas_do_professor` | Filtra escola e vínculo de docente. |
| Matricular aluno ou aceitar convite | `turmas.codigo`, `conviteProfessor.hash` | `codigo_da_turma`, único, e `convite_docente`, esparso | A matrícula atual usa a chave `_id` do aluno. |
| Listar alunos, calcular quartis e detalhar desempenho | `turmas_alunos.turmaId` e trilhas dos alunos | `alunos_da_turma` e `historico_por_modo` | O relatório usa respostas corrigidas na disciplina desde o ingresso. Exige cinco questões distintas por aluno e pelo menos quatro alunos elegíveis para formar quartis. |
| Salvar e consultar leitura | `progresso_conteudos.usuarioId`, `trilhaId`, `conteudoId` | `leitura_por_usuario_etapa`, único | A versão lida libera a prática da etapa. |
| Consultar escola, disciplina do professor ou estado das notificações | `_id` da coleção | `_id_` | Busca direta pela chave. |

Os validadores de `usuarios` e `trilhas` estão no backend. A API verifica os vínculos entre coleções e o catálogo do Neo4j. XP, medalhas, sequência e quartis são calculados a partir dos registros de atividade. O desenho físico evita armazenar cópias desses resultados em coleções próprias.
