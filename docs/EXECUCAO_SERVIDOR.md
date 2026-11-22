# Execução do servidor Java

O Java recebe cadastro e login por TCP, valida os campos e encaminha os pedidos válidos ao Node por HTTP. O Node continua responsável por autenticação, sessão e bancos. O formato das mensagens está em [CONTRATO_SERVIDOR.md](CONTRATO_SERVIDOR.md).

## Requisitos

- JDK 25, conforme o `pom.xml`.
- Maven ou o Maven integrado ao IntelliJ IDEA.
- Para integração real: Node com os endpoints HTTP do contrato e acesso aos bancos configurado pelo responsável pelo backend.

## Testes

Na raiz do projeto:

```sh
mvn clean test
```

Para executar somente os testes da supervisora:

```sh
mvn -Dtest=SupervisoraDeConexaoTest test
```

No IntelliJ, também é possível executar os testes pelo botão ao lado das classes ou pela janela Maven. Na máquina de desenvolvimento de Henrique, o executável Maven está em `/opt/intellij/plugins/maven-plugin/lib/maven3/bin/mvn`, caso `mvn` não esteja no PATH.

Os testes não exigem Node, Flutter nem bancos reais. Alguns abrem servidores TCP/HTTP locais em portas disponíveis escolhidas pelo sistema; o ambiente precisa permitir sockets locais. Eles verificam o contrato simulado, não a integração do aplicativo com os bancos.

## Iniciar pelo IntelliJ

1. Abra o `pom.xml` como projeto Maven e selecione o JDK 25.
2. Crie uma configuração de execução para `br.com.puccampinas.trilhas.Servidor`.
3. Em **VM options**, informe o endereço HTTP do Node:

   ```text
   -Dnode.url=http://127.0.0.1:3001
   ```

4. Em **Program arguments**, informe a porta TCP do Java, por exemplo `3000`. Sem argumento, o padrão também é `3000`.
5. Inicie o Node HTTP para testar operações reais e execute o Java, mantendo seu console aberto.

| Parâmetro | Padrão | Como alterar |
| --- | --- | --- |
| Porta TCP do Java | `3000` | Argumento da classe `Servidor` |
| Endereço HTTP do Node | `http://127.0.0.1:3001` | Propriedade de JVM `node.url` |
| Timeout de conexão HTTP | 5 segundos | Fixo em `ClienteNode` |
| Timeout de requisição HTTP | 10 segundos | Fixo em `ClienteNode` |

Use portas distintas para Java e Node no mesmo endereço. `node.url` é a base HTTP; o Java acrescenta `/api/auth/cadastro` ou `/api/auth/login`. Não inclua credenciais nessa URL.

## Cliente e demonstração

Execute `br.com.puccampinas.trilhas.ClienteTest` em outra configuração do IntelliJ. Esse cliente temporário conecta a `localhost:3000`; mantenha o Java nessa porta ao usá-lo. Cole um pedido compacto de uma linha, conforme os exemplos do contrato, e pressione Enter.

- Um login com e-mail inválido deve retornar `VALIDACAO_INVALIDA`, mesmo sem Node disponível.
- Um pedido válido precisa do Node HTTP para concluir a operação; sem ele, deve retornar `SERVICO_INDISPONIVEL`.
- Com Node e bancos reais, conferir cadastro, login, e-mail duplicado e credenciais incorretas.
- Digite `sair` no cliente para fechar a conexão. Para encerrar o Java, digite `desativar` no console do servidor, conforme o esqueleto do professor.

No Flutter móvel, use o endereço do computador servidor alcançável pelo aparelho e a porta TCP do Java. `localhost` no celular aponta para o próprio celular. O responsável pelo Flutter deve configurar o endereço adequado ao emulador ou aparelho físico.

## Estado da integração

O Java implementa cadastro e login com testes simulados. O Node precisa disponibilizar o contrato HTTP e o Flutter precisa apontar ao Java para a verificação real. O frontend presente nesta branch não comprova que esse redirecionamento já foi feito. A partida e a configuração dos bancos do Node devem seguir as instruções da branch de backend escolhida pela equipe.
