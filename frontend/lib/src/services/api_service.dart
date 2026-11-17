import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'tcp_client.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;
  @override
  String toString() => message;
}

class RegistrationResult {
  const RegistrationResult({this.user, this.emailSent = false});

  final AppUser? user;
  final bool emailSent;
  bool get needsVerification => user == null;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.schoolYear,
    this.schoolCode,
  });
  factory AppUser.fromJson(Map<String, dynamic> data) {
    if (['id', 'nome', 'email', 'perfil'].any(
          (key) => data[key] is! String || (data[key] as String).trim().isEmpty,
        ) ||
        !['student', 'teacher'].contains(data['perfil']) ||
        (data['anoEscolar'] != null && data['anoEscolar'] is! String) ||
        (data['codigoEscola'] != null && data['codigoEscola'] is! String)) {
      throw const ApiException(
        'O serviço retornou dados de conta inválidos. Tente novamente.',
      );
    }
    return AppUser(
      id: data['id'] as String,
      name: data['nome'] as String,
      email: data['email'] as String,
      role: data['perfil'] as String,
      schoolYear: data['anoEscolar'] as String?,
      schoolCode: data['codigoEscola'] as String?,
    );
  }

  final String id, name, email, role;
  final String? schoolYear, schoolCode;
  String get firstName => name.split(' ').first;
  String get initials => name
      .split(' ')
      .where((x) => x.isNotEmpty)
      .take(2)
      .map((x) => x[0])
      .join()
      .toUpperCase();
}

class ApiService extends ChangeNotifier {
  ApiService({Future<TcpResponse> Function(TcpRequest)? send})
    : _send =
          send ??
          const TcpClient(
            String.fromEnvironment('API_TCP_HOST', defaultValue: '127.0.0.1'),
            int.fromEnvironment('API_TCP_PORT', defaultValue: 3002),
          ).send;

  static ApiService instance = ApiService();

  final Future<TcpResponse> Function(TcpRequest) _send;
  String? _token;
  int _sessionVersion = 0;
  AppUser? user;

  static const schoolYears = [
    '1º ano do Ensino Médio',
    '2º ano do Ensino Médio',
    '3º ano do Ensino Médio',
    'Outro',
  ];

  static String requestKey() {
    final random = Random.secure();
    final bytes = List.generate(24, (_) => random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<Map<String, dynamic>> getContentStage(
    String trailId,
    String stageId,
  ) => request(
    'GET',
    '/api/trilhas/${Uri.encodeComponent(trailId)}/etapas/${Uri.encodeComponent(stageId)}',
  );
  Future<Map<String, dynamic>> completeContentReading(
    String trailId,
    String stageId,
  ) => request(
    'POST',
    '/api/trilhas/${Uri.encodeComponent(trailId)}/etapas/${Uri.encodeComponent(stageId)}/leitura',
    {},
  );
  Future<Map<String, dynamic>> startTrail({
    required bool diagnostic,
    required String key,
    String? subject,
  }) => request('POST', '/api/trilhas', {
    'tipo': diagnostic ? 'diagnostico' : 'pratica',
    'modo': 'normal',
    'chave': key,
    'disciplina': ?subject,
  });
  Future<Map<String, dynamic>> getTrail(String id) async {
    final data = await request(
      'GET',
      '/api/trilhas/${Uri.encodeComponent(id)}',
    );
    final trail = data['trilha'];
    // Um link antigo pode apontar para uma trilha fora do histórico do app.
    if (trail is Map && trail['modo'] != null && trail['modo'] != 'normal') {
      throw const ApiException('Esta trilha está indisponível.');
    }
    return data;
  }

  Future<Map<String, dynamic>> currentTrail() =>
      request('GET', '/api/trilhas/atual?modo=normal');

  Future<Map<String, dynamic>> trailHistory() =>
      request('GET', '/api/trilhas?modo=normal');

  Future<Map<String, dynamic>> answerTrail(
    String id,
    String questionId,
    String alternative,
  ) => request('POST', '/api/trilhas/${Uri.encodeComponent(id)}/respostas', {
    'questaoId': questionId,
    'alternativa': alternative,
  });
  Future<Map<String, dynamic>> generateTrail(String id) =>
      request('POST', '/api/trilhas/${Uri.encodeComponent(id)}/gerar', {});

  Future<Map<String, String>> schoolOptions() async {
    final data = await request('GET', '/api/escolas');
    final rows = data['escolas'];
    if (rows is! List) {
      throw const ApiException('Não foi possível carregar as escolas.');
    }

    final options = <String, String>{};
    for (final school in rows.whereType<Map<String, dynamic>>()) {
      if (school['demonstracao'] == true) continue;
      final code = school['codigo'];
      final name = school['nome'];
      if (code is String && name is String) options[code] = name;
    }
    return options;
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    final sessionVersion = _sessionVersion;
    try {
      final response = await _send(
        TcpRequest(method, path, data: data, token: _token),
      );
      final body = response.body;

      if (response.status == 401) {
        if (sessionVersion == _sessionVersion) _clearSession();
        final message = body is Map && body['erro'] is String
            ? body['erro'] as String
            : 'Sessão inválida ou expirada. Entre novamente.';
        throw ApiException(message, statusCode: 401);
      }

      if (body is! Map<String, dynamic>) throw const FormatException();
      final decoded = body;
      if (response.status >= 400) {
        throw ApiException(
          decoded['erro'] is String
              ? decoded['erro'] as String
              : 'Não foi possível concluir.',
          statusCode: response.status,
          code: decoded['codigo'] is String
              ? decoded['codigo'] as String
              : null,
        );
      }

      return decoded;
    } on TimeoutException {
      throw const ApiException('A conexão demorou. Tente novamente.');
    } on SocketException {
      throw const ApiException(
        'Não foi possível conectar. Confira sua conexão e tente novamente.',
      );
    } on FormatException {
      throw const ApiException('O serviço retornou uma resposta inválida.');
    }
  }

  Future<AppUser> login({
    required String email,
    required String password,
    required String role,
  }) async {
    return _saveSession(
      await request('POST', '/api/auth/login', {
        'email': email,
        'senha': password,
        'perfil': role,
      }),
    );
  }

  Future<RegistrationResult> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolField,
    required String birthDate,
    bool? educational,
    String? schoolCode,
    String? classCode,
    String? teacherCode,
  }) async {
    final data = await request('POST', '/api/auth/cadastro', {
      'nome': name,
      'email': email,
      'senha': password,
      'perfil': role,
      if (role == 'student') 'anoEscolar': schoolField,
      if (educational != null)
        'cadastroEducacional': role == 'teacher' || educational,
      if (schoolCode != null && (role == 'teacher' || educational == true))
        'codigoEscola': schoolCode,
      if (schoolCode == null &&
          role == 'teacher' &&
          schoolField.trim().isNotEmpty)
        'codigoEscola': schoolField,
      'codigoTurma': ?classCode,
      'dataNascimento': birthDate,
      'codProfessor': ?teacherCode,
      'termosAceitos': true,
    });
    if (data['verificacaoPendente'] == true) {
      return RegistrationResult(emailSent: data['emailEnviado'] == true);
    }
    return RegistrationResult(user: _saveSession(data));
  }

  Future<void> resendConfirmation(String email, String password) async {
    await request('POST', '/api/auth/reenviar-confirmacao', {
      'email': email,
      'senha': password,
    });
  }

  Future<void> confirmEmail(String code, String password) async {
    await request('POST', '/api/auth/confirmar-email', {
      'codigo': code,
      'senha': password,
    });
  }

  AppUser _saveSession(Map<String, dynamic> data) {
    final nextUser = _sessionUser(data);
    if (data['token'] is! String || (data['token'] as String).isEmpty) {
      throw const ApiException(
        'O serviço retornou uma sessão inválida. Tente novamente.',
      );
    }
    _sessionVersion++;
    _token = data['token'] as String;
    user = nextUser;
    notifyListeners();
    return nextUser;
  }

  void _clearSession() {
    _sessionVersion++;
    final changed = user != null || _token != null;
    _token = null;
    user = null;
    if (changed) notifyListeners();
  }

  AppUser _sessionUser(Map<String, dynamic> data) {
    final value = data['usuario'];
    if (value is! Map<String, dynamic>) {
      throw const ApiException(
        'O serviço retornou dados de conta inválidos. Tente novamente.',
      );
    }
    return AppUser.fromJson(value);
  }

  Future<void> restoreSession() async {
    final sessionVersion = _sessionVersion;
    try {
      final data = await request('GET', '/api/usuarios/me');
      if (sessionVersion != _sessionVersion) return;
      user = _sessionUser(data);
      notifyListeners();
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
    }
  }

  Future<void> updateProfile({required String name}) async {
    final version = _sessionVersion;
    final data = await request('PATCH', '/api/usuarios/me', {'nome': name});
    if (version != _sessionVersion) return;
    user = _sessionUser(data);
    notifyListeners();
  }

  Future<void> logout() async {
    final version = _sessionVersion;
    try {
      await request('POST', '/api/auth/logout');
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
    }
    // Uma resposta atrasada só pode encerrar a sessão que iniciou o pedido.
    if (version == _sessionVersion) _clearSession();
  }

  Future<List<Map<String, dynamic>>> questions({
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await request(
      'GET',
      '/api/questoes?limit=$limit&offset=$offset',
    );
    return (data['questoes'] as List).cast<Map<String, dynamic>>();
  }
}
