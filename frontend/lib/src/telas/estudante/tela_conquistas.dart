part of '../../telas_estudante.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RemoteContent<StudyActivity>(
      load: ActivityApi().activity,
      builder: (context, activity, refresh) => ScrollPage(
        children: [
          SectionHeader(
            title: 'Suas conquistas',
            subtitle:
                '${activity.earnedMedals} de ${activity.medals.length} medalhas',
            action: IconButton(
              tooltip: 'Atualizar conquistas',
              onPressed: refresh,
              icon: const Icon(Icons.refresh),
            ),
          ),
          SurfaceCard(
            color: AppColors.amberSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  '${activity.xp} XP',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Text(
                  '5 XP por resposta, mais 5 por acerto e 25 por trilha de conteúdos concluída.',
                ),
              ],
            ),
          ),
          for (final medal in activity.medals) _MedalCard(medal: medal),
        ],
      ),
    );
  }
}

class _MedalCard extends StatelessWidget {
  const _MedalCard({required this.medal});

  final Medal medal;

  @override
  Widget build(BuildContext context) {
    final date = medal.earnedAt;
    final color = date == null ? AppColors.muted : AppColors.amber;

    return SurfaceCard(
      child: Row(
        spacing: 14,
        children: [
          Icon(
            date == null ? Icons.lock_outline : Icons.emoji_events,
            color: color,
            size: 34,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  medal.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(medal.description),
                if (date == null) ...[
                  ProgressBar(
                    value: medal.progress / medal.goal,
                    color: AppColors.primary,
                  ),
                  Text('${medal.progress} de ${medal.goal}'),
                ] else
                  Text(
                    'Conquistada em ${MaterialLocalizations.of(context).formatCompactDate(date.toLocal())}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
