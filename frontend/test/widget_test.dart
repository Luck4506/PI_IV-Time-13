import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trilha/src/app.dart';
import 'package:trilha/src/telas_estudante.dart';

void main() {
  Future<void> abrir(
    WidgetTester tester, {
    bool professor = false,
    Size tamanho = const Size(390, 844),
  }) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TrilhaApp());
    await tester.pumpAndSettle();
    if (professor) {
      await tocar(tester, find.text('Professor'));
    }
    await tocar(tester, find.byKey(const Key('login-button')));
  }

  testWidgets('resumo semanal abre a aba de progresso', (tester) async {
    await abrir(tester);
    await tester.drag(
      find.descendant(
        of: find.byType(StudentHomeScreen),
        matching: find.byType(CustomScrollView),
      ),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    await tocar(tester, find.byKey(const Key('weekly-progress-card')));
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.text('Seu progresso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progresso abre detalhes da disciplina e do tópico', (
    tester,
  ) async {
    await abrir(tester);
    await tocar(tester, find.text('Progresso'));
    await tocar(tester, find.byKey(const Key('subject-chemistry')));
    expect(find.text('Estequiometria'), findsOneWidget);
    expect(find.text('Conceito de mol'), findsOneWidget);
    await tocar(tester, find.byKey(const Key('topic-stoichiometry')));
    expect(find.text('O que identificamos'), findsOneWidget);
    expect(find.text('37%'), findsOneWidget);
    expect(find.text('Priorizar na próxima atividade'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('área do estudante cabe em tela compacta', (tester) async {
    await abrir(tester, tamanho: const Size(320, 640));
    for (final aba in [
      'Trilha',
      'Progresso',
      'Conquistas',
      'Perfil',
      'Início',
    ]) {
      await tocar(tester, find.text(aba));
      expect(tester.takeException(), isNull, reason: aba);
    }
  });

  testWidgets('professor abre os dados do aluno selecionado', (tester) async {
    await abrir(tester, professor: true);
    await tocar(tester, find.text('Turmas'));
    await tocar(tester, find.text('3º A').first);
    await tocar(tester, find.text('João Souza'));
    expect(find.text('Detalhes do aluno'), findsOneWidget);
    expect(find.text('João Souza'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('Intervenção recomendada'), findsOneWidget);
    expect(find.text('Pausado · 1 de 4 etapas'), findsOneWidget);
    expect(find.text('Marina Costa'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}
