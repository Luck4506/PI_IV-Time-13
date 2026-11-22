// Autoria de Lucas Soares Gonçalves RA 25009467
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trilha/src/services/java_auth_client.dart';
import 'package:trilha/src/services/tcp_client.dart';

void main() {
  const cadastro = {
    'nome': 'Ana Gonçalves',
    'email': 'ana@example.com',
    'senha': 'Senha123!',
    'dataNascimento': '2008-05-15',
    'termosAceitos': true,
  };

  test('envia cadastro de aluno com ano numérico e código de turma', () async {
    final (response, received) = await exchange(
      TcpRequest(
        'POST',
        JavaAuthClient.registrationPath,
        data: {
          ...cadastro,
          'perfil': 'student',
          'anoEscolar': 'Outro',
          'cadastroEducacional': true,
          'codigoEscola': 'ESCOLA-01',
          'codigoTurma': '012345ABCDEF',
        },
      ),
      {
        'sucesso': true,
        'codigo': 'CADASTRO_REALIZADO',
        'mensagem': 'Cadastro realizado.',
        'dados': {
          'token': 'teste',
          'usuario': {'nome': 'Ana Gonçalves'},
        },
      },
    );

    expect(received, {
      ...cadastro,
      'tipo': 'VALIDAR_CADASTRO',
      'perfil': 1,
      'anoEscolar': 0,
      'cadastroEducacional': true,
      'codigoEscola': 'ESCOLA-01',
      'codigoTurma': '012345ABCDEF',
    });
    expect(response.status, 201);
    expect((response.body as Map)['token'], 'teste');
  });

  test(
    'preserva o zero no código de professor e confirma e-mail sem sessão',
    () async {
      final (response, received) = await exchange(
        TcpRequest(
          'POST',
          JavaAuthClient.registrationPath,
          data: {
            ...cadastro,
            'perfil': 'teacher',
            'codProfessor': '0042',
            'codigoEscola': 'ESCOLA-01',
          },
        ),
        {
          'sucesso': false,
          'codigo': 'OPERACAO_RECUSADA',
          'mensagem': '[EMAIL_CONFIRMACAO_ENVIADA] Confirme seu e-mail.',
          'dados': null,
        },
      );

      expect(received, {
        ...cadastro,
        'tipo': 'VALIDAR_CADASTRO',
        'perfil': 2,
        'codProfessor': '0042',
        'cadastroEducacional': true,
        'codigoEscola': 'ESCOLA-01',
      });
      expect(response.body, {
        'verificacaoPendente': true,
        'emailEnviado': true,
      });
    },
  );

  test(
    'login envia apenas e-mail e senha, e distingue recusa por confirmação',
    () async {
      final (response, received) = await exchange(
        const TcpRequest(
          'POST',
          JavaAuthClient.loginPath,
          data: {
            'email': 'ana@example.com',
            'senha': ' abc ',
            'perfil': 'teacher',
          },
          token: 'sessao-anterior',
        ),
        {
          'sucesso': false,
          'codigo': 'OPERACAO_RECUSADA',
          'mensagem': '[EMAIL_NAO_CONFIRMADO] Confirme seu e-mail para entrar.',
          'dados': null,
        },
      );

      expect(received, {
        'tipo': 'VALIDAR_LOGIN',
        'email': 'ana@example.com',
        'senha': ' abc ',
      });
      expect(response.status, 403);
      expect(response.body, {
        'codigo': 'EMAIL_NAO_CONFIRMADO',
        'erro': 'Confirme seu e-mail para entrar.',
      });
    },
  );
}

Future<(TcpResponse, Object?)> exchange(
  TcpRequest request,
  Map<String, dynamic> reply,
) async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(server.close);

  final received = server.first.then((socket) async {
    try {
      final line = await socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;
      socket.add(utf8.encode('${jsonEncode(reply)}\n'));
      await socket.flush();
      return jsonDecode(line);
    } finally {
      socket.destroy();
    }
  });

  final client = JavaAuthClient(TcpClient(server.address.address, server.port));
  final response = await client.send(request);
  return (response, await received);
}
