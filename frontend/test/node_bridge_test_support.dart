import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

typedef Json = Map<String, dynamic>;
const cadastroBase = <String, Object?>{
  'nome': 'Estudante Teste',
  'email': 'aluno@example.com',
  'senha': 'SenhaTeste123!',
  'perfil': 'student',
  'anoEscolar': '3º ano do Ensino Médio',
  'termosAceitos': true,
};
const _prazo = Duration(seconds: 10);
const _diretorioPonte = 'test/dart_bridge';

String? motivoParaPularPonteNode([String arquivo = 'fixture.mjs']) {
  final pasta = Platform.environment['BACKEND_DIR'];
  if (pasta == null || pasta.isEmpty) {
    return 'Defina BACKEND_DIR com o caminho da pasta backend.';
  }
  if (!File('$pasta/$_diretorioPonte/$arquivo').existsSync()) {
    return 'Arquivo de apoio ausente: $_diretorioPonte/$arquivo.';
  }
  return null;
}

String get _backend {
  final pasta = Platform.environment['BACKEND_DIR'];
  if (pasta == null || pasta.isEmpty) {
    throw StateError('Defina BACKEND_DIR com o caminho da pasta backend.');
  }
  return Directory(pasta).absolute.path;
}

Future<Process> _node(List<String> argumentos) => Process.start(
  Platform.environment['NODE_BIN'] ?? 'node',
  argumentos,
  workingDirectory: _backend,
);

void suiteNode(String arquivo) {
  test(
    'Suíte original do backend',
    () async {
      final processo = await _node(['--test', '$_diretorioPonte/$arquivo']);
      try {
        final logs = await Future.wait([
          processo.stdout.transform(utf8.decoder).join(),
          processo.stderr.transform(utf8.decoder).join(),
        ]).timeout(const Duration(minutes: 1));
        expect(await processo.exitCode, 0, reason: logs.join('\n'));
        if (arquivo == 'contrato-app-servidor.test.js' &&
            !Directory('$_backend/../frontend/lib/src/services').existsSync()) {
          markTestSkipped('A pasta frontend/lib/src/services está ausente.');
        }
      } finally {
        processo.kill();
      }
    },
    skip: motivoParaPularPonteNode(arquivo),
    timeout: const Timeout(Duration(seconds: 75)),
  );
}

final class ApiTeste {
  ApiTeste._(this._processo, this._linhas, this._logs);

  final Process _processo;
  final StreamIterator<String> _linhas;
  final StringBuffer _logs;
  int? porta;

  static Future<ApiTeste> iniciar({String modo = 'api'}) async {
    final processo = await _node(['$_diretorioPonte/fixture.mjs', modo]);
    final logs = StringBuffer();
    processo.stderr.transform(utf8.decoder).listen(logs.write);
    final linhas = StreamIterator(
      processo.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((linha) => linha.startsWith('DART ')),
    );
    final api = ApiTeste._(processo, linhas, logs);
    addTearDown(() async {
      processo.kill();
      await linhas.cancel();
      await processo.exitCode.timeout(_prazo);
    });
    api.porta = (await api._ler())['porta'] as int?;
    return api;
  }

  Future<Json> _ler() async {
    if (!await _linhas.moveNext().timeout(_prazo)) {
      throw StateError('A ponte Node encerrou sem resposta.\n$_logs');
    }
    final resposta = jsonDecode(_linhas.current.substring(5)) as Json;
    if (resposta.containsKey('falha')) {
      throw StateError(resposta['falha'].toString());
    }
    return resposta;
  }

  Future<Json> chamar(
    String caminho, {
    String metodo = 'GET',
    Json? corpo,
    String? token,
  }) async {
    _processo.stdin.writeln(
      jsonEncode({
        'caminho': caminho,
        'metodo': metodo,
        'corpo': ?corpo,
        'token': ?token,
      }),
    );
    await _processo.stdin.flush();
    return _ler();
  }

  Future<Json> enviarTcp(
    String metodo,
    String caminho, {
    Json? dados,
    String? token,
  }) async {
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      porta!,
      timeout: _prazo,
    );
    try {
      socket.writeln(
        jsonEncode({
          'metodo': metodo,
          'caminho': caminho,
          'dados': ?dados,
          'token': ?token,
        }),
      );
      await socket.flush();
      final linha = await socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(_prazo);
      return jsonDecode(linha) as Json;
    } finally {
      socket.destroy();
    }
  }
}
