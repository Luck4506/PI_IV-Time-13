# Conexão do app com a API

O Flutter configura o endereço com `API_TCP_HOST` e `API_TCP_PORT` via `--dart-define`. No iPhone simulado, o padrão é `127.0.0.1:3002`.

`lib/src/services/api_service.dart` monta o pedido e mantém o token em memória. `tcp_client.dart` abre o socket e lê a resposta. `activity_api.dart` e `classroom_api.dart` tratam os dados das telas de aluno e professor.

O app abre os cadernos das questões no endereço fornecido pelo catálogo. A alternativa escolhida volta à API para ser corrigida e gravada na trilha. [Protocolo e rotas](../../backend/README.md)
