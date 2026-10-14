part of '../../telas_estudante.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageFrame(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppMark(compact: true),
              const SizedBox(height: 26),
              const SectionHeader(
                title: 'Seu progresso',
                subtitle: 'A evolução importa mais que uma nota isolada',
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  StatPill(
                    icon: Icons.task_alt_rounded,
                    value: '68%',
                    label: 'acertos',
                    color: AppColors.mint,
                  ),
                  SizedBox(width: 10),
                  StatPill(
                    icon: Icons.schedule_rounded,
                    value: '4h18',
                    label: 'tempo total',
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Evolução nas últimas semanas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const TagChip(label: '+12%', color: AppColors.mint),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _LineChartPlaceholder(),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Por disciplina',
                subtitle: 'O diagnóstico acompanha cada conteúdo separadamente',
              ),
              const SizedBox(height: 14),
              ...SubjectProfiles.all.indexed.expand(
                (entry) => [
                  _SubjectProgress(
                    key: entry.$2.name == SubjectProfiles.chemistry.name
                        ? const Key('subject-chemistry')
                        : null,
                    subject: entry.$2,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SubjectDetailScreen(subject: entry.$2),
                      ),
                    ),
                  ),
                  if (entry.$1 < SubjectProfiles.all.length - 1)
                    const SizedBox(height: 12),
                ],
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Revisões programadas'),
              const SizedBox(height: 14),
              SurfaceCard(
                child: Column(
                  children: const [
                    _ReviewRow(
                      day: 'HOJE',
                      title: 'Equações do 1º grau',
                      questions: '5 questões',
                      color: AppColors.coral,
                    ),
                    Divider(height: 24),
                    _ReviewRow(
                      day: 'TER',
                      title: 'Citologia',
                      questions: '7 questões',
                      color: AppColors.mint,
                    ),
                    Divider(height: 24),
                    _ReviewRow(
                      day: 'SEX',
                      title: 'Interpretação de texto',
                      questions: '6 questões',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineChartPlaceholder extends StatelessWidget {
  const _LineChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    const values = [.42, .48, .46, .57, .61, .68];
    return SizedBox(
      height: 145,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${(values[index] * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 95 * values[index],
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.sky],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'S${index + 1}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SubjectProgress extends StatelessWidget {
  const _SubjectProgress({
    super.key,
    required this.subject,
    required this.onTap,
  });
  final SubjectProgressData subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: subject.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(subject.icon, color: subject.color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subject.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${(subject.mastery * 100).round()}%',
                      style: TextStyle(
                        color: subject.color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subject.summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 9),
                ProgressBar(
                  value: subject.mastery,
                  color: subject.color,
                  height: 7,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.day,
    required this.title,
    required this.questions,
    required this.color,
  });
  final String day;
  final String title;
  final String questions;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            day,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(questions, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ],
    );
  }
}
