# Contrato de cadastro e login

Contrato do servidor Java para integração com o Flutter móvel e o Node. Descreve o comportamento implementado; a integração com Node e bancos reais ainda precisa ser verificada em conjunto.

```text
Flutter → TCP/JSON por linha → Java → HTTP/JSON → Node → bancos
Flutter ← TCP/JSON por linha ← Java ← HTTP/JSON ← Node
```

## Transporte Flutter–Java

- UTF-8, um objeto JSON por linha, terminado por quebra de linha.
- O Flutter deve reconstruir as linhas do fluxo TCP; um pacote ou evento de leitura não equivale necessariamente a uma mensagem inteira.
- Quebras de linha dentro de textos devem ser escapadas pelo serializador JSON.
- Um pedido por vez, aguardando a resposta antes do próximo.
- Uma resposta final por pedido, pela mesma conexão, sem confirmação intermediária de campos válidos.
- A conexão permite novos pedidos depois de uma recusa. Fim do envio do cliente (EOF) encerra a supervisora e remove seu parceiro da lista.

## Pedidos de cadastro

Aluno sem vínculo educacional:

```json
{"tipo":"VALIDAR_CADASTRO","nome":"Ana Silva","dataNascimento":"2008-05-15","email":"ana@example.com","senha":"Abcde12!","perfil":1,"anoEscolar":2,"cadastroEducacional":false,"termosAceitos":true}
```

Professor:

```json
{"tipo":"VALIDAR_CADASTRO","nome":"Ivan Granja","dataNascimento":"1967-08-15","email":"ivan@example.com","senha":"Ivann12!","perfil":2,"codProfessor":"0042","cadastroEducacional":true,"codigoEscola":"ESCOLA-DEMO-001","termosAceitos":true}
```

Aluno educacional com turma:

```json
{"tipo":"VALIDAR_CADASTRO","nome":"Ana Silva","dataNascimento":"2008-05-15","email":"ana@example.com","senha":"Abcde12!","perfil":1,"anoEscolar":2,"cadastroEducacional":true,"codigoEscola":"ESCOLA-DEMO-001","termosAceitos":true,"codigoTurma":"0A1B2C3D4E5F"}
```

| Campo | Regra Java |
| --- | --- |
| `tipo` | Texto `VALIDAR_CADASTRO`. |
| `nome` | Nome e sobrenome, com letras; aceita acentos, hífen e apóstrofo. Remove espaços das extremidades e reduz espaços repetidos. |
| `dataNascimento` | Texto `AAAA-MM-DD`, data existente entre `1800-01-01` e `3000-01-01`, inclusive. Datas futuras são permitidas por decisão da equipe. |
| `email` | Texto com formato aceito pela expressão regular do projeto; remove espaços das extremidades. Não verifica existência da caixa postal. |
| `senha` | Texto com pelo menos 8 caracteres, uma letra, dois dígitos e um especial. Espaços e controles não contam como especiais. Preserva o conteúdo. |
| `perfil` | Número inteiro: `1` aluno, `2` professor. Não aceita texto numérico. |
| `anoEscolar` | Inteiro obrigatório para aluno: `0` Outro ou `1`, `2`, `3` do Ensino Médio. Omitir no cadastro de professor. |
| `codProfessor` | Texto de quatro dígitos ASCII, obrigatório para professor. Preserva zeros iniciais. Omitir para aluno. |
| `cadastroEducacional` | Booleano. Quando omitido, assume `true` para professor e `false` para aluno. Professor não pode informar `false`; JSON null explícito é inválido. |
| `codigoEscola` | Texto obrigatório quando educacional, com 1–80 caracteres após remover espaços das extremidades. Omitir sem vínculo educacional. |
| `termosAceitos` | Booleano obrigatório, exatamente `true`. |
| `codigoTurma` | Texto opcional somente para aluno educacional. Remove espaços das extremidades, converte para maiúsculas e exige 12 caracteres hexadecimais (`0–9`, `A–F`). |

Campos textuais com números, booleanos, listas ou objetos são rejeitados, sem conversão automática. A obrigatoriedade dos campos é verificada pelo pedido. O Node verifica regras dependentes dos bancos, incluindo escola/turma, duplicidade, credenciais e registro do aceite dos termos; o Java não acessa os bancos.

## Pedido de login

```json
{"tipo":"VALIDAR_LOGIN","email":"ana@example.com","senha":"Abcde12!"}
```

O e-mail segue a regra de formato do cadastro. A senha deve ser texto não vazio e é preservada; a regra de força do cadastro não é reaplicada no login. Aceitar os campos não autentica o usuário: o Node precisa conferir as credenciais.

## Java–Node por HTTP

| Operação | Requisição | Sucesso | Recusa tratada |
| --- | --- | --- | --- |
| Cadastro | `POST /api/auth/cadastro` | HTTP `201` | HTTP `409` |
| Login | `POST /api/auth/login` | HTTP `200` | HTTP `401` |

O Java envia `Content-Type: application/json`. O cadastro HTTP contém os campos normalizados da tabela, sem `tipo` e sem campos opcionais ausentes. Os campos exclusivos do perfil são selecionados pelo Java; `perfil` continua número `1` ou `2`, e `anoEscolar` continua número. O login HTTP contém somente `email` e `senha`.

Corpo de sucesso exigido nas duas operações:

```json
{"token":"token-da-sessao","usuario":{"id":"usuario-123","nome":"Ana Silva"}}
```

`token` deve ser texto não vazio/não composto só de espaços, e `usuario` deve ser objeto. O Java preserva o objeto completo em `dados`; não valida assinatura do token nem exige atributos específicos dentro de `usuario`. O Node define os campos públicos do usuário e não deve incluir hash ou senha. A sessão precisa estar no corpo JSON, não apenas em cookie HTTP.

Corpo das recusas HTTP 409 de cadastro ou 401 de login:

```json
{"erro":"Mensagem pública da recusa."}
```

O Java exige `erro` textual e não vazio. Respostas 5xx, falhas de conexão, timeout ou respostas fora do formato esperado resultam em `SERVICO_INDISPONIVEL`, sem repetição automática da operação. Atualmente, os demais status, inclusive 400, 403 e 429, ainda não têm tradução específica e também resultam em indisponibilidade; isso deve ser considerado no teste com o Node real.

## Resposta Java–Flutter

| Campo | Significado |
| --- | --- |
| `sucesso` | Booleano; `true` somente após confirmação do Node no formato esperado. |
| `codigo` | Identificador do resultado, conforme os exemplos abaixo. |
| `mensagem` | Mensagem pública para apresentação ao usuário. |
| `dados` | Objeto completo devolvido pelo Node no sucesso; JSON null nas recusas e falhas. |

Cadastro concluído:

```json
{"sucesso":true,"codigo":"CADASTRO_REALIZADO","mensagem":"Cadastro realizado.","dados":{"token":"token-da-sessao","usuario":{"id":"usuario-123","nome":"Ana Silva"}}}
```

Login concluído:

```json
{"sucesso":true,"codigo":"LOGIN_REALIZADO","mensagem":"Login realizado.","dados":{"token":"token-da-sessao","usuario":{"id":"usuario-123","nome":"Ana Silva"}}}
```

Entrada recusada pelo Java, sem chamada ao Node:

```json
{"sucesso":false,"codigo":"VALIDACAO_INVALIDA","mensagem":"Informe seu nome e sobrenome.","dados":null}
```

Credenciais recusadas pelo Node:

```json
{"sucesso":false,"codigo":"OPERACAO_RECUSADA","mensagem":"Email ou senha incorretos.","dados":null}
```

Serviço indisponível:

```json
{"sucesso":false,"codigo":"SERVICO_INDISPONIVEL","mensagem":"Servico indisponivel. Tente novamente.","dados":null}
```

O formato antigo `valido`/`mensagem` de `ResultadoValidacao` permanece em testes isolados, mas não é a resposta final da supervisora atual. O cliente não deve depender dele nem do antigo código `CADASTRO_INVALIDO`.

## Verificação com a equipe

Os testes locais usam Node simulado. Antes da entrega, verificar com Flutter, Node HTTP e bancos reais: aluno/professor, cadastro educacional, login, e-mail duplicado, credenciais incorretas, indisponibilidade e uma recusa seguida de um pedido válido. Esses testes conjuntos ainda não foram concluídos pelo Java nesta branch.
