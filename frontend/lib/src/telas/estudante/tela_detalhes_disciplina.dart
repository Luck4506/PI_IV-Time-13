part of '../../telas_estudante.dart';

class SubjectDetailScreen extends StatelessWidget {
  const SubjectDetailScreen({super.key, required this.subject});

  final SubjectProgressData subject;

  @override
  Widget build(BuildContext context) {
    final priorityTopics = subject.topics
        .where((topic) => topic.mastery < .55)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageFrame(
            maxWidth: 760,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        subject.color,
                        subject.color.withValues(alpha: .72),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              subject.icon,
                              color: AppColors.white,
                              size: 29,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(subject.mastery * 100).round()}%',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Seu domínio em ${subject.name}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subject.schoolStage,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: .82),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ProgressBar(
                        value: subject.mastery,
                        color: AppColors.white,
                        backgroundColor: AppColors.white.withValues(alpha: .25),
                        height: 9,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SurfaceCard(
                  color: const Color(0xFFF0F3FF),
                  borderColor: const Color(0xFFDCE3FF),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Adaptação ativa',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              priorityTopics.isEmpty
                                  ? 'Nenhum tópico exige reforço intenso agora. A trilha manterá revisões espaçadas.'
                                  : '${priorityTopics.first.name} aparecerá com mais frequência nas próximas atividades, sem repetir conteúdos que você já domina.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Desempenho por tópico',
                  subtitle:
                      '${subject.topics.length} conteúdos avaliados individualmente',
                ),
                const SizedBox(height: 14),
                ...subject.topics.indexed.expand(
                  (entry) => [
                    _TopicProgressCard(
                      key: entry.$2.name == 'Estequiometria'
                          ? const Key('topic-stoichiometry')
                          : null,
                      topic: entry.$2,
                      subjectColor: subject.color,
                      onTap: () =>
                          _showTopicDetails(context, subject, entry.$2),
                    ),
                    if (entry.$1 < subject.topics.length - 1)
                      const SizedBox(height: 11),
                  ],
                ),
                const SizedBox(height: 28),
                const SectionHeader(title: 'Como sua trilha se adapta'),
                const SizedBox(height: 14),
                const SurfaceCard(
                  child: Column(
                    children: [
                      _AdaptationRow(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Mais prática onde há dificuldade',
                        detail: 'Tópicos abaixo de 55% recebem mais questões, exemplos e explicações.',
                        color: AppColors.coral,
                      ),
                      Divider(height: 25),
                      _AdaptationRow(
                        icon: Icons.trending_up_rounded,
                        title: 'Desafio gradual',
                        detail: 'A dificuldade aumenta quando seu desempenho melhora.',
                        color: AppColors.primary,
                      ),
                      Divider(height: 25),
                      _AdaptationRow(
                        icon: Icons.event_repeat_rounded,
                        title: 'Revisão no momento certo',
                        detail: 'Conteúdos dominados voltam em intervalos maiores para evitar esquecimento.',
                        color: AppColors.mint,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTopicDetails(
    BuildContext context,
    SubjectProgressData subject,
    TopicProgressData topic,
  ) {
    final status = _topicStatus(topic.mastery);
    final statusColor = _topicColor(topic.mastery, subject.color);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.fromLTRB(
          22,
          12,
          22,
          24 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 22),
            TagChip(label: status, color: statusColor),
            const SizedBox(height: 12),
            Text(
              topic.name,
              style: Theme.of(sheetContext).textTheme.headlineLarge,
            ),
            const SizedBox(height: 5),
            Text(
              topic.schoolStage,
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                StatPill(
                  icon: Icons.psychology_alt_rounded,
                  value: '${(topic.mastery * 100).round()}%',
                  label: 'domínio',
                  color: statusColor,
                ),
                const SizedBox(width: 10),
                StatPill(
                  icon: Icons.quiz_rounded,
                  value: '${topic.accuracy}%',
                  label: '${topic.questionsAnswered} questões',
                  color: subject.color,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'O que identificamos',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              topic.insight,
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Próximo passo',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              topic.nextStep,
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'A priorização de ${topic.name} estará disponível em uma próxima versão.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Priorizar na próxima atividade'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicProgressCard extends StatelessWidget {
  const _TopicProgressCard({
    super.key,
    required this.topic,
    required this.subjectColor,
    required this.onTap,
  });

  final TopicProgressData topic;
  final Color subjectColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _topicStatus(topic.mastery);
    final statusColor = _topicColor(topic.mastery, subjectColor);
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      topic.schoolStage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              TagChip(label: status, color: statusColor),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ProgressBar(
                  value: topic.mastery,
                  color: statusColor,
                  height: 8,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(topic.mastery * 100).round()}%',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdaptationRow extends StatelessWidget {
  const _AdaptationRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(detail, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

String _topicStatus(double mastery) {
  if (mastery < .55) return 'Prioridade';
  if (mastery < .75) return 'Em evolução';
  return 'Consolidado';
}

Color _topicColor(double mastery, Color subjectColor) {
  if (mastery < .55) return AppColors.coral;
  if (mastery < .75) return AppColors.amber;
  return mastery >= .8 ? AppColors.mint : subjectColor;
}
