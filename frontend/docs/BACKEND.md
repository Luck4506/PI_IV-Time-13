# Conexão do app com a API

O Flutter usa `JAVA_TCP_HOST` e `JAVA_TCP_PORT` para cadastro e login no Java, com porta padrão `3000`. As demais operações usam `API_TCP_HOST` e `API_TCP_PORT` para falar com o Node na porta padrão `3002`. Configure esses valores via `--dart-define`. No iPhone simulado, o host padrão é `127.0.0.1`.

`lib/src/services/api_service.dart` escolhe o destino e mantém o token em memória. `java_auth_client.dart` converte cadastro e login para o formato do Java. `tcp_client.dart` envia e lê JSON por linha nas duas conexões. [Contrato de cadastro e login](../../docs/CONTRATO_SERVIDOR.md)

O app abre os cadernos das questões no endereço fornecido pelo catálogo. A alternativa escolhida volta à API para ser corrigida e gravada na trilha. [Protocolo e rotas](../../backend/README.md)
