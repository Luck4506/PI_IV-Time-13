import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trilha/src/services/api_service.dart';

void configureTestApi() {
  ApiService.instance = ApiService(
    client: MockClient((request) async {
      if (request.url.path == '/api/auth/logout') return http.Response('', 204);
      final data = jsonDecode(request.body) as Map<String, dynamic>;
      final teacher = data['perfil'] == 'teacher';
      return http.Response(
        jsonEncode({
          'token': 'test-session',
          'usuario': {
            'id': 'test-user',
            'nome': data['nome'] ?? (teacher ? 'Ana Ribeiro' : 'Marina Costa'),
            'email': data['email'],
            'perfil': teacher ? 'teacher' : 'student',
            if (!teacher) 'anoEscolar': data['anoEscolar'] ?? '3º ano',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
}

Future<void> fillTestLogin(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'teste@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'SenhaTeste123!');
}
