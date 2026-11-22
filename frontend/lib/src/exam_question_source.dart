// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';

class ExamQuestionSource extends StatelessWidget {
  const ExamQuestionSource({super.key, required this.question});

  final Map<String, dynamic> question;

  @override
  Widget build(BuildContext context) {
    final board = question['banca'];
    final year = question['ano'];
    final number = question['numero'];
    final booklet = question['caderno'];
    final credit = question['creditoFonte'];
    if (board is! String || year is! int || number is! int) {
      return const SizedBox.shrink();
    }

    final reference = [
      '$board $year · Questão $number',
      if (booklet is String && booklet.isNotEmpty) booklet,
      if (credit is String && credit.isNotEmpty) credit,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        reference.join('\n'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
