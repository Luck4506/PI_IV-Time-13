import 'dart:convert';

import 'package:test/test.dart';

import 'api_test_support.dart';

Json _lerParte(String parte) =>
    jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parte))))
        as Json;

void main() {
  test('JWT contém os campos de sessão esperados', () async {
    final api = await ApiTeste.iniciar();
    final cadastro = await api.chamar('/api/auth/cadastro',
        metodo: 'POST', corpo: cadastroBase);
    expect(cadastro['status'], 201);
    final dados = cadastro['dados'] as Json;
    final partes = (dados['token'] as String).split('.');
    expect(partes, hasLength(3));
    final header = _lerParte(partes[0]);
    final payload = _lerParte(partes[1]);
    expect(header['alg'], 'HS256');
    expect(payload['iss'], 'trilha-api');
    expect(payload['aud'], 'trilha-app');
    expect(payload['sub'], dados['usuario']['id']);
    expect((payload['exp'] as int) - (payload['iat'] as int), 12 * 3600);
    expect(payload['v'], 0);
  });

  suiteNode('seguranca-sessao.test.js');
}
