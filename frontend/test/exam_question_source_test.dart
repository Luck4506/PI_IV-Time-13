import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trilha/src/exam_question_source.dart';

const question = <String, dynamic>{
  'banca': 'ENEM',
  'ano': 2024,
  'caderno': '2º dia · Caderno 7 azul',
  'numero': 137,
  'nome': 'Médias e leitura de dados',
  'paginaProva': 16,
  'provaUrl': 'https://download.inep.gov.br/enem/provas_e_gabaritos/2024_PV_impresso_D2_CD7.pdf',
};

void main() {
  test('a referência aponta para a página física do PDF', () {
    expect(ExamQuestionSource.bookletUrl(question)?.fragment, 'page=16');
    expect(
      ExamQuestionSource.bookletUrl({...question, 'paginaProva': 0}),
      isNull,
    );
    expect(
      ExamQuestionSource.bookletUrl({
        ...question,
        'provaUrl': 'javascript:alert(1)',
      }),
      isNull,
    );
  });

  testWidgets('a questão identifica banca, edição, caderno e página', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ExamQuestionSource(question: question)),
      ),
    );

    expect(find.text('ENEM 2024 · Questão 137'), findsOneWidget);
    expect(find.textContaining('Página 16 do PDF'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Abrir questão no caderno'),
      findsOneWidget,
    );
  });
}
