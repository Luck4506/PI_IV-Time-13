// Autoria de Lucas Soares Gonçalves RA 25009467
part of '../../telas_estudante.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RemoteContent<StudyActivity>(
      load: ActivityApi().activity,
      builder: (context, activity, refresh) => ScrollPage(
        children: [
          SectionHeader(
            title: 'Seu progresso',
            subtitle:
                '${activity.correct} acertos em ${activity.answered} respostas',
            action: IconButton(
              tooltip: 'Atualizar progresso',
              icon: const Icon(Icons.refresh),
              onPressed: refresh,
            ),
          ),
          _WeekActivity(days: activity.week),
          const SectionHeader(title: 'Por disciplina'),
          if (activity.subjects.isEmpty)
            const SurfaceCard(
              child: Text(
                'Responda uma questão da sua trilha para ver seu progresso aqui.',
              ),
            ),
          for (final subject in activity.subjects)
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text(subject.score.name),
                subtitle: Text(
                  '${subject.score.correct} de ${subject.score.answers} acertos',
                ),
                trailing: Text(subject.score.label),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubjectDetailScreen(subject: subject),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekActivity extends StatelessWidget {
  const _WeekActivity({required this.days});

  final List<StudyDay> days;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const SectionHeader(title: 'Questões nos últimos 7 dias'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in days)
                Semantics(
                  label: 'Dia ${day.date.day}: ${day.answers} respostas',
                  child: Column(
                    spacing: 5,
                    children: [
                      Text(
                        '${day.answers}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${day.date.day}/${day.date.month}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
