// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trilha/src/app.dart';
import 'package:trilha/src/telas_estudante.dart';
import 'package:trilha/src/services/classroom_api.dart';
import 'package:trilha/src/telas/professor/painel_quartis.dart';

import 'api_test_support.dart';

void main() {
  setUp(configureTestApi);
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
    await fillTestLogin(
      tester,
      email: professor ? 'professor@example.test' : 'teste@example.com',
    );
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
    await tocar(tester, find.text('Matemática'));
    expect(find.text('Porcentagens'), findsOneWidget);
    await tocar(tester, find.text('Porcentagens'));
    expect(find.text('25%'), findsOneWidget);
    expect(find.textContaining('Revise este conteúdo'), findsOneWidget);
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

  testWidgets('conquistas mostram o XP e a medalha da conta', (tester) async {
    await abrir(tester);
    await tocar(tester, find.text('Conquistas'));
    expect(find.text('25 XP'), findsOneWidget);
    expect(find.text('Primeiro passo'), findsOneWidget);
  });

  testWidgets('quartis mostram as questões que faltam para o mínimo', (
    tester,
  ) async {
    final report = ClassReport.fromJson({
      'turma': {
        'id': 'a',
        'nome': '3º A',
        'disciplina': 'Matemática',
        'codigo': 'ABCDEF012345',
        'podeConvidarProfessor': true,
      },
      'totalAlunos': 1,
      'respondidas': 6,
      'acertos': 4,
      'aproveitamento': 67,
      'minimoQuestoesPorAluno': 5,
      'minimoAlunosParaQuartis': 4,
      'abaixoDoMinimo': [
        {
          'id': 'student',
          'nome': 'João Souza',
          'respondidas': 6,
          'questoesDistintas': 2,
          'acertos': 4,
          'aproveitamento': 67,
        },
      ],
    });
    StudentScore? opened;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuartilePanel(
            report: report,
            onStudent: (student) => opened = student,
          ),
        ),
      ),
    );
    expect(find.textContaining('5 questões diferentes'), findsOneWidget);
    expect(find.text('Q1 · Menor desempenho'), findsNothing);

    await tocar(tester, find.text('Abaixo do mínimo de questões'));
    expect(find.text('2 de 5 questões diferentes'), findsOneWidget);
    await tocar(tester, find.text('João Souza'));
    expect(opened?.id, 'student');
  });

  testWidgets('professor abre os dados do aluno selecionado', (tester) async {
    await abrir(tester, professor: true);
    await tocar(tester, find.text('Turmas'));
    await tocar(tester, find.text('3º A').first);
    expect(
      find.image(const AssetImage('assets/images/turma_ilustracao.jpg')),
      findsOneWidget,
    );
    expect(find.text('Copiar código'), findsOneWidget);
    expect(find.text('Convidar professor'), findsOneWidget);
    expect(find.text('Renovar código'), findsOneWidget);
    expect(find.text('Copiar relatório CSV'), findsNothing);

    await tocar(tester, find.byTooltip('Ocultar código'));
    expect(find.text('Código para alunos'), findsOneWidget);
    expect(find.text('ABCDEF012345'), findsNothing);
    expect(find.text('Copiar código'), findsNothing);
    expect(find.text('Convidar professor'), findsNothing);
    expect(find.text('Renovar código'), findsNothing);

    await tocar(tester, find.byTooltip('Mostrar código'));
    expect(find.text('ABCDEF012345'), findsOneWidget);
    expect(find.text('Copiar código'), findsOneWidget);
    await tocar(tester, find.byTooltip('Ocultar código'));
    expect(find.text('Q1 · Menor desempenho'), findsOneWidget);
    expect(find.text('João Souza'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    final search = find.widgetWithText(TextField, 'Buscar aluno por nome');
    await tester.ensureVisible(search);
    await tester.enterText(search, 'nome inexistente');
    await tester.pumpAndSettle();
    expect(find.text('Nenhum aluno encontrado.'), findsOneWidget);
    expect(find.text('João Souza'), findsNothing);

    await tester.enterText(search, 'joao souza');
    await tester.pumpAndSettle();
    expect(find.text('Q1 · Menor desempenho'), findsOneWidget);
    expect(find.text('João Souza'), findsOneWidget);
    await tocar(tester, find.text('João Souza'));
    expect(find.text('Detalhes do aluno'), findsOneWidget);
    expect(find.text('João Souza'), findsOneWidget);
    expect(find.text('1 acertos em 5 respostas'), findsOneWidget);
    expect(find.text('Porcentagens'), findsOneWidget);
    expect(find.text('Marina Costa'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}
