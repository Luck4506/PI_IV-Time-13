import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
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
  factory AppUser.fromJson(Map<String, dynamic> data) => AppUser(
    id: data['id'] as String,
    name: data['nome'] as String,
    email: data['email'] as String,
    role: data['perfil'] as String,
    schoolYear: data['anoEscolar'] as String?,
    schoolCode: data['codigoEscola'] as String?,
  );
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

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://127.0.0.1:3000',
          );

  static ApiService instance = ApiService();
  final http.Client _client;
  final String baseUrl;
  String? _token;
  AppUser? user;

  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers['Content-Type'] = 'application/json';
      if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
      if (data != null) request.body = jsonEncode(data);
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      ).timeout(const Duration(seconds: 20));
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        if (response.statusCode == 401) {
          _token = null;
          user = null;
        }
        throw ApiException(
          decoded['erro'] as String? ?? 'Não foi possível concluir.',
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
  }) async {
    return _saveSession(
      await request('POST', '/api/auth/cadastro', {
        'nome': name,
        'email': email,
        'senha': password,
        'perfil': role,
        if (role == 'student') 'anoEscolar': schoolField,
        if (role == 'teacher' && schoolField.trim().isNotEmpty)
          'codigoEscola': schoolField,
        'termosAceitos': true,
      }),
    );
  }

  AppUser _saveSession(Map<String, dynamic> data) {
    final nextUser = AppUser.fromJson(data['usuario'] as Map<String, dynamic>);
    _token = data['token'] as String;
    user = nextUser;
    return nextUser;
  }

  Future<void> logout() async {
    try {
      if (_token != null) await request('POST', '/api/auth/logout');
    } on ApiException {
      /* Local session always ends, even while offline. */
    } finally {
      _token = null;
      user = null;
    }
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
