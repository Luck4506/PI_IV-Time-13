import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trilha/src/services/tcp_client.dart';

void main() {
  test('envia os campos do pedido e lê uma resposta UTF-8 em partes', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    final received = server.first.then((socket) async {
      try {
        final line = await socket
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .first;

        final reply = utf8.encode('{"status":200,"corpo":{"nome":"João"}}\n');
        final split = reply.indexOf(0xc3) + 1;

        // Divide a resposta no meio do caractere acentuado.
        socket.add(reply.sublist(0, split));
        await socket.flush();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        socket.add(reply.sublist(split));
        await socket.flush();

        return jsonDecode(line);
      } finally {
        socket.destroy();
      }
    });

    final client = TcpClient(server.address.address, server.port);
    final response = await client.send(
      const TcpRequest(
        'PATCH',
        '/api/usuarios/me',
        data: {'nome': 'João'},
        token: 'sessao-de-teste',
      ),
    );

    expect(await received, {
      'metodo': 'PATCH',
      'caminho': '/api/usuarios/me',
      'token': 'sessao-de-teste',
      'dados': {'nome': 'João'},
    });
    expect(response.status, 200);
    expect(response.body, {'nome': 'João'});
  });

  test('recusa um pedido acima do limite em bytes antes de conectar', () async {
    const client = TcpClient('127.0.0.1', 0);
    final response = await client.send(
      TcpRequest('PATCH', '/api/usuarios/me', data: {'nome': 'á' * 32768}),
    );

    expect(response.status, 413);
  });

  test('recusa uma resposta que termina sem quebra de linha', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    final sent = server.first.then((socket) async {
      try {
        await socket.first;
        socket.write('{"status":200,"corpo":{}}');
        await socket.flush();
      } finally {
        socket.destroy();
      }
    });

    final client = TcpClient(server.address.address, server.port);
    await expectLater(
      client.send(const TcpRequest('GET', '/api/usuarios/me')),
      throwsA(isA<SocketException>()),
    );
    await sent;
  });
}
