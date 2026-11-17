import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class TcpRequest {
  const TcpRequest(this.method, this.path, {this.data, this.token});

  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final String? token;
}

class TcpResponse {
  const TcpResponse(this.body, this.status);

  final Object? body;
  final int status;
}

class TcpClient {
  const TcpClient(this.host, this.port);

  static const _requestLimit = 64 * 1024;
  static const _responseLimit = 8 * 1024 * 1024;
  static const _connectionTimeout = Duration(seconds: 5);
  static const _responseTimeout = Duration(seconds: 22);

  final String host;
  final int port;

  Future<TcpResponse> send(TcpRequest request) async {
    final pedido = {
      'metodo': request.method,
      'caminho': request.path,
      if (request.token != null) 'token': request.token,
      if (request.data != null) 'dados': request.data,
    };
    final bytes = utf8.encode('${jsonEncode(pedido)}\n');

    if (bytes.length - 1 > _requestLimit) {
      return const TcpResponse({'erro': 'Pedido muito grande.'}, 413);
    }

    final socket = await Socket.connect(
      host,
      port,
      timeout: _connectionTimeout,
    );

    try {
      // Cada conexão carrega um pedido e uma resposta. O byte da quebra de
      // linha marca o fim da mensagem, mesmo se ela chegar em várias partes.
      socket.add(bytes);
      await socket.flush().timeout(_connectionTimeout);

      final line = await _readLine(socket).timeout(_responseTimeout);
      final data = jsonDecode(utf8.decode(line));
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Resposta TCP inválida.');
      }

      final status = data['status'];
      final body = data['corpo'];
      if (status is! int ||
          status < 200 ||
          status > 599 ||
          body is! Map<String, dynamic>) {
        throw const FormatException('Resposta TCP inválida.');
      }

      return TcpResponse(body, status);
    } finally {
      socket.destroy();
    }
  }

  Future<Uint8List> _readLine(Socket socket) async {
    final buffer = BytesBuilder(copy: false);

    // Medimos em bytes e só decodificamos a linha completa. Um acento pode
    // ocupar mais de um byte e chegar dividido entre duas leituras.
    await for (final part in socket) {
      final end = part.indexOf(10);
      final length = end < 0 ? part.length : end;

      if (buffer.length + length > _responseLimit) {
        throw const FormatException('Resposta TCP muito grande.');
      }

      buffer.add(end < 0 ? part : Uint8List.sublistView(part, 0, end));
      if (end >= 0) return buffer.takeBytes();
    }

    throw const SocketException('A conexão fechou antes da resposta.');
  }
}
