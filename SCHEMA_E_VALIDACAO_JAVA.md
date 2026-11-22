# Contrato do validador Java

> Registro do fluxo anterior usado na demonstração. Para a integração atual, consulte o [contrato do servidor](docs/CONTRATO_SERVIDOR.md) e o [README do projeto](README.md).

O Flutter se comunica com o Node. O Node solicita ao validador Java externo a validação do cadastro e do login em `127.0.0.1:3001` por padrão. A porta pode ser alterada em `JAVA_VALIDATOR_PORT`.

Cada pedido é um objeto JSON em UTF-8 encerrado por quebra de linha. O Node espera até três segundos por uma linha de resposta com `valido` (booleano) e `mensagem` (texto).

## Login

O Node envia `tipo` com valor `VALIDAR_LOGIN`, além de `email` e `senha` em texto. Se o validador aprovar os campos, o Node verifica a senha e o perfil da conta e emite a sessão.

## Cadastro

| Campo | Tipo no JSON | Valor no pedido |
| --- | --- | --- |
| `tipo` | `VALIDAR_CADASTRO` | Identifica o pedido |
| `nome` | Texto | Nome informado no cadastro |
| `email` | Texto | Endereço de e-mail normalizado pelo Node |
| `senha` | Texto | Senha informada no cadastro |
| `dataNascimento` | Texto | Data no formato `AAAA-MM-DD` |
| `perfil` | Inteiro | `1` para aluno ou `2` para professor |
| `anoEscolar` | Inteiro enviado para aluno | `1`, `2` ou `3` para os anos do Ensino Médio e `0` para **Outro** |
| `codProfessor` | Texto enviado para professor | Quatro algarismos. O texto preserva zeros à esquerda |

Os campos de vínculo e consentimento (`cadastroEducacional`, `codigoEscola`, `codigoTurma` e `termosAceitos`) são tratados no Node. O Node também protege a senha com scrypt antes de salvar e grava o aceite em `termosAceitosEm`.

O Node retorna a mensagem do validador ao recusar dados com `valido: false`. Se o serviço estiver indisponível ou a resposta for inválida, o cadastro e o login retornam status `503`.
