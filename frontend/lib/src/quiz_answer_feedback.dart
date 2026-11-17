import 'package:flutter/material.dart';

const _green = Color(0xFF13795B);
const _red = Color(0xFFB42318);
const _greenBackground = Color(0xFFE8F8F3);
const _redBackground = Color(0xFFFFECE7);

class QuizAnswerOption extends StatelessWidget {
  const QuizAnswerOption({
    super.key,
    required this.letter,
    required this.label,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onPressed,
  });

  final String letter;
  final String label;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = correct
        ? _green
        : wrong
        ? _red
        : null;
    final background = correct
        ? _greenBackground
        : wrong
        ? _redBackground
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        key: Key('answer-option-$letter'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: color,
          disabledForegroundColor: color,
          backgroundColor:
              background ??
              (selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null),
          disabledBackgroundColor: background,
          side: color == null ? null : BorderSide(color: color, width: 2),
          padding: const EdgeInsets.all(16),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            if (correct || wrong) ...[
              const SizedBox(width: 10),
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
                semanticLabel: correct
                    ? 'Alternativa correta'
                    : 'Sua resposta incorreta',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class QuizAnswerFeedback extends StatelessWidget {
  const QuizAnswerFeedback({
    super.key,
    required this.correct,
    required this.selected,
    required this.answerKey,
  });

  final bool correct;
  final String? selected;
  final String answerKey;

  @override
  Widget build(BuildContext context) {
    final color = correct ? _green : _red;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(correct ? 'correct-answer-feedback' : 'wrong-answer-feedback'),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: correct ? _greenBackground : _redBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              correct
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: color,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correct ? 'Resposta correta!' : 'Ainda não foi desta vez',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  if (!correct) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Você marcou $selected. Alternativa correta: $answerKey.',
                      style: TextStyle(color: color),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Releia o conteúdo com calma e siga praticando.',
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text('Resposta salva.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
