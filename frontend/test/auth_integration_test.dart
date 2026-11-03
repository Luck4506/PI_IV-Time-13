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
        if (request.url.path == '/api/usuarios/me') {
          return http.Response(
            jsonEncode({'erro': 'Entre na sua conta.'}),
            401,
          );
        }
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
      'SenhaTeste123!',
    ].asMap().entries) {
      await tester.enterText(fields.at(entry.key), entry.value);
    }
    await tester.tap(find.byKey(const Key('school-year-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6º ano do Ensino Fundamental').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('educational-registration')),
    );
    await tester.tap(find.byKey(const Key('educational-registration')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Escola'));
    await tester.tap(find.text('Escola'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escola Horizonte — Demonstração').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuar e personalizar'));
    await tester.tap(find.text('Continuar e personalizar'));
    await tester.pumpAndSettle();
    expect(received!['termosAceitos'], true);
    expect(received!['anoEscolar'], '6º ano do Ensino Fundamental');
    expect(received!['cadastroEducacional'], true);
    expect(received!['codigoEscola'], 'ESCOLA-DEMO-001');
    expect(
      find.text('Vamos descobrir o melhor ponto de partida?'),
      findsOneWidget,
    );
    expect(ApiService.instance.user?.name, 'Teste Integrado');
  });

  testWidgets(
    'atividade retoma trilha e salva resposta antes de mostrar resultado',
    (tester) async {
      var saved = false;
      final item = {
        'questaoId': 'REAL-01',
        'nome': 'Questão real',
        'disciplina': 'Física',
        'motivo': {'descricao': 'Reforço de tema'},
        'questao': {
          'id': 'REAL-01',
          'questao': 'Questão recebida da API',
          'alternativaA': 'Alternativa da API',
        },
      };
      Map<String, dynamic> trail() => {
        'id': 'TRILHA-1',
        'modo': 'normal',
        'tipo': 'pratica',
        'status': saved ? 'concluida' : 'em_andamento',
        'acertos': saved ? 1 : 0,
        'erros': 0,
        'total': 1,
        'respondidas': saved ? 1 : 0,
        'itens': [item],
      };
      ApiService.instance = ApiService(
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(jsonEncode({'trilha': trail()}), 200);
          }
          expect(request.url.path, '/api/trilhas/TRILHA-1/respostas');
          expect(jsonDecode(request.body)['alternativa'], 'A');
          saved = true;
          return http.Response(
            jsonEncode({
              'trilha': trail(),
              'resposta': {'correta': true, 'gabarito': 'A'},
              'proximaTrilha': {
                'id': 'TRILHA-2',
                'tipo': 'exploracao',
                'etapas': [
                  {
                    'nome': 'Novo assunto',
                    'disciplina': 'Física',
                    'motivo': {'descricao': 'Assunto sorteado'},
                  },
                ],
              },
            }),
            200,
          );
        }),
      );
      Object? openedTrailArguments;
      await tester.pumpWidget(
        MaterialApp(
          home: const GraphQuizScreen(),
          onGenerateRoute: (settings) {
            openedTrailArguments = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Trilha aberta')),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Questão recebida da API'), findsOneWidget);
      await tester.tap(find.text('A. Alternativa da API'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();
      expect(saved, true);
      expect(find.text('Resposta salva.'), findsOneWidget);
      await tester.tap(find.text('Ver resultado e trilha'));
      await tester.pumpAndSettle();
      expect(
        find.text('Você acertou todas! Vamos explorar novos assuntos.'),
        findsOneWidget,
      );
      expect(find.text('Novo assunto'), findsOneWidget);
      await tester.tap(find.text('Abrir minha trilha'));
      await tester.pumpAndSettle();
      expect(openedTrailArguments, {'modo': 'normal', 'trilhaId': 'TRILHA-2'});
    },
  );
}
