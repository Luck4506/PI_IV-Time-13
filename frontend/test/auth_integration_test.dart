import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trilha/src/app.dart';
import 'package:trilha/src/services/api_service.dart';
import 'package:trilha/src/graph_quiz_screen.dart';

void main() {
  testWidgets(
    'login rejeitado permanece no formulário e mostra erro do servidor',
    (tester) async {
      ApiService.instance = ApiService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'erro': 'E-mail, senha ou perfil incorretos.'}),
            401,
          ),
        ),
      );
      await tester.pumpWidget(const TrilhaApp());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'teste@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'SenhaIncorreta123',
      );
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('E-mail, senha ou perfil incorretos.'), findsOneWidget);
      expect(find.text('Que bom ter você de volta'), findsOneWidget);
      expect(ApiService.instance.user, isNull);
    },
  );

  testWidgets('cadastro envia dados e só avança após confirmação da API', (
    tester,
  ) async {
    Map<String, dynamic>? received;
    ApiService.instance = ApiService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/auth/cadastro');
        received = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'token': 'test-token',
            'usuario': {
              'id': '1',
              'nome': received!['nome'],
              'email': received!['email'],
              'perfil': received!['perfil'],
              'anoEscolar': received!['anoEscolar'],
            },
          }),
          201,
        );
      }),
    );
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TrilhaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ainda não tenho uma conta'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    for (final entry in [
      'Teste Integrado',
      'teste@example.com',
      '3º ano',
      'SenhaTeste123!',
    ].asMap().entries) {
      await tester.enterText(fields.at(entry.key), entry.value);
    }
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuar e personalizar'));
    await tester.tap(find.text('Continuar e personalizar'));
    await tester.pumpAndSettle();
    expect(received!['termosAceitos'], true);
    expect(received!['anoEscolar'], '3º ano');
    expect(
      find.text('Vamos descobrir o melhor ponto de partida?'),
      findsOneWidget,
    );
    expect(ApiService.instance.user?.name, 'Teste Integrado');
  });

  testWidgets(
    'atividade mostra questão do grafo e trata ausência de gabarito',
    (tester) async {
      ApiService.instance = ApiService(
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'questoes': [
                  {
                    'id': 'REAL-01',
                    'questao': 'Questão recebida da API',
                    'alternativaA': 'Alternativa da API',
                  },
                ],
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'corrigida': false,
              'mensagem': 'Esta questão ainda não tem gabarito cadastrado.',
            }),
            200,
          );
        }),
      );
      await tester.pumpWidget(const MaterialApp(home: GraphQuizScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Questão recebida da API'), findsOneWidget);
      await tester.tap(find.text('A. Alternativa da API'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();
      expect(
        find.text('Esta questão ainda não tem gabarito cadastrado.'),
        findsOneWidget,
      );
      expect(find.text('Resposta correta!'), findsNothing);
    },
  );
}
