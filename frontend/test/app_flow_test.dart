import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trilha/main.dart';

import 'api_test_support.dart';

void main() {
  setUp(configureTestApi);
  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TrilhaApp());
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('inicia no login e rejeita e-mail inválido', (tester) async {
    await start(tester);
    expect(find.text('Que bom ter você de volta'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'invalido');
    await tap(tester, find.byKey(const Key('login-button')));
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Olá, Marina!'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('estudante navega, lê notificações e sai sem voltar ao painel', (
    tester,
  ) async {
    await start(tester);
    await fillTestLogin(tester);
    await tap(tester, find.byKey(const Key('login-button')));
    expect(find.text('Olá, Marina!'), findsOneWidget);
    await tap(tester, find.byIcon(Icons.notifications_none_rounded));
    await tap(tester, find.text('Marcar como lidas'));
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Marcar como lidas'),
          )
          .onPressed,
      isNull,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, find.text('Perfil'));
    await tap(tester, find.text('Sair'));
    expect(find.text('Que bom ter você de volta'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byKey(const Key('login-button'))))
          .canPop(),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('professor acessa a turma selecionada', (tester) async {
    await start(tester);
    await tap(tester, find.text('Professor'));
    await fillTestLogin(tester);
    await tap(tester, find.byKey(const Key('login-button')));
    expect(find.text('Olá, Ana'), findsOneWidget);
    await tap(tester, find.text('Turmas'));
    await tester.enterText(find.byType(TextField), '3º B');
    await tester.pumpAndSettle();
    expect(find.text('3º A'), findsNothing);
    await tap(tester, find.text('3º B').last);
    expect(find.text('3º B · Matemática'), findsOneWidget);
    expect(find.text('29'), findsOneWidget);
    expect(find.text('73%'), findsOneWidget);
    await tap(tester, find.text('João Souza'));
    expect(find.text('Detalhes do aluno'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cadastro exige campos e mantém perfil escolhido', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, find.text('Professor'));
    await tap(tester, find.text('Ainda não tenho uma conta'));
    expect(find.text('Código da escola (opcional)'), findsOneWidget);
    await tap(tester, find.byType(CheckboxListTile));
    await tap(tester, find.text('Continuar'));
    expect(find.text('Preencha este campo.'), findsOneWidget);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
