import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trilha/src/graph_quiz_screen.dart';
import 'package:trilha/src/services/api_service.dart';
import 'package:trilha/src/services/tcp_client.dart';
import 'package:trilha/src/telas_autenticacao.dart';
import 'package:trilha/src/user_trail_view.dart';

void main() {
  testWidgets(
    'erro só recebe destaque após salvar, com correta e incorreta identificadas',
    (tester) async {
      var unavailable = true;
      ApiService.instance = ApiService(
        send: (request) async {
          if (request.method == 'POST' && unavailable) {
            return TcpResponse({'erro': 'Tente salvar novamente.'}, 503);
          }
          return TcpResponse({
            'trilha': {
              'id': 't1',
              'tipo': 'pratica',
              'modo': 'normal',
              'itens': [
                {
                  'questaoId': 'Q1',
                  'disciplina': 'Física',
                  'questao': {
                    'questao': 'Qual a resposta?',
                    'alternativaA': 'Correta',
                    'alternativaB': 'Incorreta',
                  },
                },
              ],
            },
            if (request.method == 'POST')
              'resposta': {'correta': false, 'gabarito': 'A'},
          }, 200);
        },
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: GraphQuizScreen(trailId: 't1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('B. Incorreta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wrong-answer-feedback')), findsNothing);
      expect(find.text('Tente salvar novamente.'), findsOneWidget);
      unavailable = false;
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('wrong-answer-feedback')), findsOneWidget);
      expect(
        find.text('Você marcou B. Alternativa correta: A.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      final wrong = tester.widget<OutlinedButton>(
        find.byKey(const Key('answer-option-B')),
      );
      final correct = tester.widget<OutlinedButton>(
        find.byKey(const Key('answer-option-A')),
      );
      expect(wrong.onPressed, isNull);
      expect(
        wrong.style!.backgroundColor!.resolve({WidgetState.disabled}),
        const Color(0xFFFFECE7),
      );
      expect(
        correct.style!.backgroundColor!.resolve({WidgetState.disabled}),
        const Color(0xFFE8F8F3),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mapa mostra revisão com base nos erros salvos ao reabrir', (
    tester,
  ) async {
    ApiService.instance = ApiService(
      send: (request) async => TcpResponse(
        Uri.parse(request.path).path.endsWith('/t1')
            ? {
                'trilha': {
                  'id': 't1',
                  'tipo': 'revisao',
                  'modo': 'normal',
                  'status': 'em_andamento',
                  'itens': [
                    {
                      'questaoId': 'Q1',
                      'resposta': {'correta': false},
                    },
                  ],
                  'etapas': [
                    {
                      'id': 'c1',
                      'nome': 'Queda livre',
                      'status': 'concluida',
                      'questaoIds': ['Q1'],
                    },
                    {
                      'id': 'c2',
                      'nome': 'Energia',
                      'status': 'disponivel',
                      'questaoIds': ['Q2'],
                    },
                  ],
                },
              }
            : {'trilhas': []},
        200,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: UserTrailView(initialTrailId: 't1')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Revisar · 1 erro'), 200);
    expect(
      find.descendant(
        of: find.byKey(const Key('content-node-c1')),
        matching: find.byIcon(Icons.replay_rounded),
      ),
      findsOneWidget,
    );
    expect(find.text('Revisar · 1 erro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('escola é condicional para aluno e obrigatória para professor', (
    tester,
  ) async {
    var attempts = 0;
    ApiService.instance = ApiService(
      send: (request) async {
        expect(Uri.parse(request.path).path, '/api/escolas');
        if (++attempts == 1) {
          return TcpResponse({'erro': 'Tente novamente.'}, 503);
        }
        return TcpResponse({
          'escolas': [
            {
              'codigo': 'ESCOLA-DEMO-001',
              'nome': 'Escola Horizonte — Demonstração',
            },
          ],
        }, 200);
      },
    );
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Escola'), findsNothing);
    expect(find.byKey(const Key('class-code-register')), findsNothing);
    await tester.tap(find.byKey(const Key('educational-registration')));
    await tester.pumpAndSettle();
    expect(find.text('Escola'), findsOneWidget);
    expect(find.byKey(const Key('class-code-register')), findsOneWidget);
    expect(find.text('Não foi possível carregar as escolas.'), findsOneWidget);
    await tester.tap(find.text('Recarregar escolas'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    await tester.tap(find.text('Escola'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escola Horizonte — Demonstração').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('educational-registration')));
    await tester.pumpAndSettle();
    expect(find.text('Escola Horizonte — Demonstração'), findsNothing);
    await tester.tap(find.text('Professor'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('educational-registration')), findsNothing);
    expect(
      find.text('Professores sempre usam uma conta educacional.'),
      findsOneWidget,
    );
    expect(find.text('Escola'), findsOneWidget);
    expect(find.text('Escola Horizonte — Demonstração'), findsNothing);
    final field = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(field.validator!(null), 'Selecione sua escola.');
    expect(tester.takeException(), isNull);
  });
}
