part of '../../telas_professor.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageFrame(
          maxWidth: 840,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppMark(compact: true),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Relatórios',
                action: IconButton.outlined(
                  onPressed: () => showPendingFeature(context),
                  icon: const Icon(Icons.download_rounded),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  TagChip(label: '3º A', icon: Icons.groups_rounded),
                  TagChip(
                    label: 'Últimos 30 dias',
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.mint,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Evolução da turma',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const TagChip(label: '+9%', color: AppColors.mint),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Média de acertos por semana',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                    const _TeacherBarChart(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Domínio por assunto',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              const _TopicMastery(
                name: 'Razão e proporção',
                value: .81,
                students: '25 dominam',
                color: AppColors.mint,
              ),
              const SizedBox(height: 11),
              const _TopicMastery(
                name: 'Interpretação de gráficos',
                value: .72,
                students: '21 dominam',
                color: AppColors.primary,
              ),
              const SizedBox(height: 11),
              const _TopicMastery(
                name: 'Equações do 1º grau',
                value: .48,
                students: '14 precisam de apoio',
                color: AppColors.coral,
              ),
              const SizedBox(height: 11),
              const _TopicMastery(
                name: 'Funções',
                value: .57,
                students: '11 precisam de apoio',
                color: AppColors.amber,
              ),
              const SizedBox(height: 26),
              SurfaceCard(
                color: const Color(0xFFEFF3FF),
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
                            'Insight pedagógico',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Uma revisão coletiva de equações pode ajudar 45% da turma. Depois, a plataforma mantém trilhas individuais para quem ainda precisar.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.primaryDark),
                          ),
                        ],
                      ),
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

class _TeacherBarChart extends StatelessWidget {
  const _TeacherBarChart();

  @override
  Widget build(BuildContext context) {
    const values = [.58, .63, .66, .68];
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          values.length,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${(values[index] * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: values[index] * 115,
                    decoration: BoxDecoration(
                      color: index == values.length - 1
                          ? AppColors.primary
                          : const Color(0xFFDCE3FF),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'S${index + 1}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicMastery extends StatelessWidget {
  const _TopicMastery({
    required this.name,
    required this.value,
    required this.students,
    required this.color,
  });
  final String name;
  final double value;
  final String students;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      students,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(value: value, color: color, height: 8),
        ],
      ),
    );
  }
}
