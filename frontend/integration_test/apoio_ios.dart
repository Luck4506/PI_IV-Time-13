// Autoria de Lucas Soares Gonçalves RA 25009467
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const saveScreenshots = bool.fromEnvironment('TRILHA_QA_SCREENSHOTS');

Future<void> screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  if (!saveScreenshots) return;

  final folder = Directory('${Directory.systemTemp.path}/trilha-qa');
  await folder.create(recursive: true);
  final image = await binding.takeScreenshot(name);
  await File('${folder.path}/$name.png').writeAsBytes(image);
}

Future<void> signIn(WidgetTester tester, String email, String password) async {
  expect(
    email,
    isNotEmpty,
    reason: 'Informe as contas de teste no arquivo de configuração.',
  );
  final fields = find.byType(TextFormField);
  await waitFor(tester, fields);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tap(tester, find.byKey(const Key('login-button')));
}

Future<void> tap(WidgetTester tester, Finder target) async {
  await reveal(tester, target);
  await tester.tap(target.hitTestable().first);
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.pumpAndSettle();

  // O iPhone tem menos espaço que a janela do teste de widgets. Alguns
  // botões só entram na árvore quando a gente rola a tela.
  for (var attempt = 0; attempt < 8; attempt++) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pumpAndSettle();
      if (target.hitTestable().evaluate().isNotEmpty) return;
    }

    final scroll = find.byType(Scrollable).hitTestable();
    if (scroll.evaluate().isEmpty) break;
    await tester.drag(scroll.first, const Offset(0, -240));
    await tester.pumpAndSettle();
  }

  await waitFor(tester, target.hitTestable());
}

Future<void> waitFor(WidgetTester tester, Finder target) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (target.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  expect(target, findsWidgets);
}
