// Autoria de Lucas Soares Gonçalves RA 25009467
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
    final heading = find.text('Que bom ver você de volta!');
    expect(heading, findsOneWidget);
    await tap(tester, find.byTooltip('Mostrar senha'));
    expect(find.byTooltip('Ocultar senha'), findsOneWidget);
    await tap(tester, find.byTooltip('Ocultar senha'));
    expect(find.text('Gabariteii'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/gabariteii_logo.png')),
      findsOneWidget,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'Gabariteii',
    );
    expect(
      Localizations.localeOf(tester.element(heading)),
      const Locale('pt', 'BR'),
    );
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
    await tap(tester, find.byType(BackButton));
    await tap(tester, find.text('Perfil'));
    await tap(tester, find.text('Sair'));
    expect(find.text('Que bom ver você de volta!'), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byKey(const Key('login-button'))))
          .canPop(),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('professor acessa a turma selecionada', (tester) async {
    await start(tester);
    expect(find.text('Professor'), findsNothing);
    await fillTestLogin(tester, email: 'professor@example.test');
    await tap(tester, find.byKey(const Key('login-button')));
    expect(find.text('Olá, Ana'), findsOneWidget);
    await tap(tester, find.text('Turmas'));
    await tester.enterText(find.byType(TextField), '3º B');
    await tester.pumpAndSettle();
    expect(find.text('3º A'), findsNothing);
    await tap(tester, find.text('3º B').last);
    expect(find.text('Desempenho em Matemática'), findsOneWidget);
    expect(
      find.textContaining('4 alunos · 20 respostas · 60%'),
      findsOneWidget,
    );
    expect(find.text('Q1 · Menor desempenho'), findsOneWidget);
    await tap(tester, find.text('João Souza'));
    expect(find.text('Detalhes do aluno'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cadastro exige campos e mantém perfil escolhido', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, find.text('Ainda não tenho uma conta'));
    await tap(tester, find.text('Professor'));
    expect(find.text('Escola'), findsOneWidget);
    expect(
      find.text('Professores sempre usam uma conta educacional.'),
      findsOneWidget,
    );
    await tap(tester, find.byType(CheckboxListTile));
    await tap(tester, find.text('Continuar'));
    expect(find.text('Preencha este campo.'), findsOneWidget);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
    expect(find.text('Selecione sua escola.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
