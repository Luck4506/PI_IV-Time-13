// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trilha/src/exam_question_source.dart';

void main() {
  testWidgets('mostra a fonte de uma questão sem oferecer um link externo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExamQuestionSource(
            question: {
              'banca': 'ENEM',
              'ano': 2024,
              'numero': 137,
              'caderno': '2º dia · Caderno 7 azul',
              'creditoFonte': 'Fonte: Inep',
              'provaUrl': 'https://example.test/prova.pdf',
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('ENEM 2024 · Questão 137'), findsOneWidget);
    expect(find.textContaining('Fonte: Inep'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
