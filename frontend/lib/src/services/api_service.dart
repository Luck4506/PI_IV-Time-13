import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'http_client.dart' if (dart.library.js_interop) 'http_client_web.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
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
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? createHttpClient(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://127.0.0.1:3000',
          );

  static ApiService instance = ApiService();
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
  final http.Client _client;
  final String baseUrl;
  String? _token;
  int _sessionVersion = 0;
  AppUser? user;
  static const schoolYears = [
    '6º ano do Ensino Fundamental',
    '7º ano do Ensino Fundamental',
    '8º ano do Ensino Fundamental',
    '9º ano do Ensino Fundamental',
    '1º ano do Ensino Médio',
    '2º ano do Ensino Médio',
    '3º ano do Ensino Médio',
    'Outro',
  ];

  static String requestKey() => List.generate(
    24,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  Future<Map<String, dynamic>> startTrail({
    required bool diagnostic,
    bool example = false,
    required String key,
  }) => request('POST', '/api/trilhas', {
    'tipo': diagnostic ? 'diagnostico' : 'pratica',
    'modo': example ? 'exemplo' : 'normal',
    'chave': key,
  });
  Future<Map<String, dynamic>> getTrail(String id) =>
      request('GET', '/api/trilhas/${Uri.encodeComponent(id)}');
  Future<Map<String, dynamic>> currentTrail(String mode) =>
      request('GET', '/api/trilhas/atual?modo=$mode');
  Future<Map<String, dynamic>> trailHistory(String mode) =>
      request('GET', '/api/trilhas?modo=$mode');
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

  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    final sessionVersion = _sessionVersion;
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers['Content-Type'] = 'application/json';
      request.headers['X-Trilha-Client'] = 'app';
      if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
      if (data != null) request.body = jsonEncode(data);
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) {
        if (sessionVersion == _sessionVersion) _clearSession();
        String message = 'Sessão inválida ou expirada. Entre novamente.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['erro'] is String) {
            message = body['erro'] as String;
          }
        } on FormatException {
          /* A proxy may return a plain-text 401. */
        }
        throw ApiException(message, statusCode: 401);
      }
      final Object? body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (body is! Map<String, dynamic>) throw const FormatException();
      final decoded = body;
      if (response.statusCode >= 400) {
        throw ApiException(
          decoded['erro'] is String
              ? decoded['erro'] as String
              : 'Não foi possível concluir.',
          statusCode: response.statusCode,
        );
      }

      return decoded;
    } on TimeoutException {
      throw const ApiException('A conexão demorou. Tente novamente.');
    } on http.ClientException {
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

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolField,
    bool? educational,
    String? schoolCode,
  }) async {
    return _saveSession(
      await request('POST', '/api/auth/cadastro', {
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
        'termosAceitos': true,
      }),
    );
  }

  AppUser _saveSession(Map<String, dynamic> data) {
    final nextUser = _sessionUser(data);
    if (!kIsWeb &&
        (data['token'] is! String || (data['token'] as String).isEmpty)) {
      throw const ApiException(
        'O serviço retornou uma sessão inválida. Tente novamente.',
      );
    }
    _sessionVersion++;
    _token = kIsWeb ? null : data['token'] as String;
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

  Future<void> logout() async {
    try {
      await request('POST', '/api/auth/logout');
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
    }
    _clearSession();
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
