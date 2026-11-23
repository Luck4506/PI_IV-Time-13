import 'package:test/test.dart';

import 'api_test_support.dart';

void main() {
  test('Cliente Dart consulta saúde e executa o ciclo da conta via TCP',
      () async {
    final api = await ApiTeste.iniciar(modo: 'tcp');
    final saude = await api.enviarTcp('GET', '/health/live');
    expect(saude['status'], 200);
    expect(saude['corpo']['status'], 'ok');

    final cadastro =
        await api.enviarTcp('POST', '/api/auth/cadastro', dados: cadastroBase);
    expect(cadastro['status'], 201);
    final inicial = cadastro['corpo']['token'] as String;
    expect(cadastro['corpo']['usuario']['email'], cadastroBase['email']);
    expect(cadastro['corpo']['usuario']['senhaHash'], isNull);

    final login = await api.enviarTcp('POST', '/api/auth/login', dados: {
      'email': 'ALUNO@example.com',
      'senha': cadastroBase['senha'],
      'perfil': 'student',
    });
    expect(login['status'], 200);
    final token = login['corpo']['token'] as String;
    const perfil = '/api/usuarios/me';
    final antes = await api.enviarTcp('GET', perfil, token: token);
    expect(antes['corpo']['usuario']['nome'], 'Estudante Teste');
    final editado = await api.enviarTcp('PATCH', perfil,
        token: token, dados: {'nome': 'Nome Editado'});
    expect(editado['corpo']['usuario']['nome'], 'Nome Editado');
    expect(
        (await api.enviarTcp('POST', '/api/auth/logout',
            token: token))['status'],
        204);
    for (final sessao in [inicial, token]) {
      expect(
          (await api.enviarTcp('GET', perfil, token: sessao))['status'], 401);
    }
  });

  suiteNode('integracao-tcp-e2e.test.js');
}
