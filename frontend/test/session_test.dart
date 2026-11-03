import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trilha/src/app.dart';
import 'package:trilha/src/services/api_service.dart';

const student = {
  'id': 'u1',
  'nome': 'Conta Existente',
  'email': 'conta@example.com',
  'perfil': 'student',
  'anoEscolar': '3º ano do Ensino Médio',
};
http.Response jsonResponse(Object data, [int status = 200]) =>
    http.Response(jsonEncode(data), status);

void main() {
  testWidgets('restaura a conta existente ao abrir sem pedir senha', (
    tester,
  ) async {
    var restores = 0;
    ApiService.instance = ApiService(
      client: MockClient((req) async {
        expect(req.url.path, '/api/usuarios/me');
        restores++;
        return jsonResponse({'usuario': student});
      }),
    );
    await tester.pumpWidget(const TrilhaApp());
    await tester.pumpAndSettle();
    expect(find.text('Olá, Conta!'), findsOneWidget);
    expect(find.text('Que bom ter você de volta'), findsNothing);
    expect(restores, 1);
    expect(ApiService.instance.user?.id, 'u1');
  });

  testWidgets('sem sessão um link privado exige login', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/aluno';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    ApiService.instance = ApiService(
      client: MockClient(
        (_) async => jsonResponse({'erro': 'Sessão expirada.'}, 401),
      ),
    );
    await tester.pumpWidget(const TrilhaApp());
    await tester.pumpAndSettle();
    expect(find.text('Que bom ter você de volta'), findsOneWidget);
    expect(find.text('Olá, Conta!'), findsNothing);
  });

  testWidgets('estudante não acessa a área do professor por URL', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/professor';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    ApiService.instance = ApiService(
      client: MockClient((_) async => jsonResponse({'usuario': student})),
    );
    await tester.pumpWidget(const TrilhaApp());
    await tester.pumpAndSettle();
    expect(find.text('Sua conta não tem acesso a esta área.'), findsOneWidget);
    expect(find.text('Olá, Conta!'), findsNothing);
    await tester.tap(find.text('Ir para minha área'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Conta!'), findsOneWidget);
  });

  testWidgets('401 encerra a sessão e remove as telas privadas da navegação', (
    tester,
  ) async {
    ApiService.instance = ApiService(
      client: MockClient(
        (req) async => req.url.path == '/api/usuarios/me'
            ? jsonResponse({'usuario': student})
            : jsonResponse({'erro': 'Sessão encerrada.'}, 401),
      ),
    );
    await tester.pumpWidget(const TrilhaApp());
    await tester.pumpAndSettle();
    await expectLater(
      ApiService.instance.questions(),
      throwsA(isA<ApiException>()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Que bom ter você de volta'), findsOneWidget);
    expect(find.text('Olá, Conta!'), findsNothing);
    expect(
      Navigator.of(tester.element(find.byKey(const Key('login-button'))))
          .canPop(),
      false,
    );
  });

  testWidgets(
    'indisponibilidade ao restaurar permite tentar novamente sem fingir autenticação',
    (tester) async {
      var attempts = 0;
      ApiService.instance = ApiService(
        client: MockClient(
          (_) async => ++attempts == 1
              ? jsonResponse({'erro': 'Serviço indisponível.'}, 503)
              : jsonResponse({'usuario': student}),
        ),
      );
      await tester.pumpWidget(const TrilhaApp());
      await tester.pumpAndSettle();
      expect(
        find.text('Não foi possível confirmar sua sessão.'),
        findsOneWidget,
      );
      expect(find.text('Olá, Conta!'), findsNothing);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Olá, Conta!'), findsOneWidget);
    },
  );

  test('logout indisponível não informa que a sessão foi revogada', () async {
    final api = ApiService(
      client: MockClient(
        (req) async => req.url.path == '/api/usuarios/me'
            ? jsonResponse({'usuario': student})
            : jsonResponse({'erro': 'Sem conexão.'}, 503),
      ),
    );
    await api.restoreSession();
    await expectLater(api.logout(), throwsA(isA<ApiException>()));
    expect(api.user?.id, 'u1');
  });
  test('resposta não objeto da API é tratada como erro recuperável', () async {
    final api = ApiService(
      client: MockClient((_) async => http.Response('[]', 200)),
    );
    await expectLater(api.restoreSession(), throwsA(isA<ApiException>()));
    expect(api.user, isNull);
  });

  test('401 sem JSON também encerra a sessão', () async {
    final api = ApiService(
      client: MockClient(
        (req) async => req.url.path == '/api/usuarios/me'
            ? jsonResponse({'usuario': student})
            : http.Response('Unauthorized', 401),
      ),
    );
    await api.restoreSession();
    await expectLater(api.questions(), throwsA(isA<ApiException>()));
    expect(api.user, isNull);
  });

  test(
    'resposta atrasada de sessão anterior não encerra um novo login',
    () async {
      final pending = Completer<http.Response>();
      final api = ApiService(
        client: MockClient((req) async {
          if (req.url.path == '/api/questoes') return pending.future;
          return jsonResponse({'usuario': student, 'token': 'token-atual'});
        }),
      );
      await api.restoreSession();
      final oldRequest = api.questions();
      final oldResult = expectLater(oldRequest, throwsA(isA<ApiException>()));
      await api.login(
        email: 'conta@example.com',
        password: 'SenhaTeste123!',
        role: 'student',
      );
      pending.complete(jsonResponse({'erro': 'Sessão antiga expirada.'}, 401));
      await oldResult;
      expect(api.user?.id, 'u1');
    },
  );
  test(
    'dados de conta incompletos ou perfil desconhecido não autenticam',
    () async {
      for (final payload in [
        null,
        {...student, 'perfil': 'admin'},
      ]) {
        final api = ApiService(
          client: MockClient((_) async => jsonResponse({'usuario': payload})),
        );
        await expectLater(api.restoreSession(), throwsA(isA<ApiException>()));
        expect(api.user, isNull);
      }
    },
  );
}
