part of '../../telas_estudante.dart';

class SubjectDetailScreen extends StatelessWidget {
  const SubjectDetailScreen({super.key, required this.subject});

  final SubjectActivity subject;

  @override
  Widget build(BuildContext context) {
    final sorted = [...subject.topics]
      ..sort((a, b) => (a.percent ?? 0).compareTo(b.percent ?? 0));

    return Scaffold(
      appBar: AppBar(title: Text(subject.score.name)),
      body: ScrollPage(
        children: [
          const SectionHeader(title: 'Resultados por conteúdo'),
          for (final topic in sorted)
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: ExpansionTile(
                title: Text(topic.name),
                subtitle: Text('${topic.correct} de ${topic.answers} acertos'),
                trailing: Text(topic.label),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                    child: Text(
                      topic.percent == 100
                          ? 'Você acertou todas as respostas registradas neste conteúdo.'
                          : 'Revise este conteúdo e volte à prática para acompanhar sua evolução.',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
