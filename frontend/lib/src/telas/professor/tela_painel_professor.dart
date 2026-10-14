part of '../../telas_professor.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key, required this.onOpenClasses});

  final VoidCallback onOpenClasses;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageFrame(
          maxWidth: 960,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const InitialAvatar(initials: 'PA', color: AppColors.mint),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, professora Ana',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Text(
                          'Aqui está o pulso das suas turmas.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () =>
                        Navigator.pushNamed(context, NotificationsScreen.route),
                    icon: const Badge(
                      smallSize: 7,
                      child: Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const SectionHeader(
                title: 'Visão geral',
                subtitle: 'Últimos 7 dias',
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    const _TeacherMetric(
                      icon: Icons.groups_rounded,
                      value: '92',
                      label: 'alunos ativos',
                      trend: '+6%',
                      color: AppColors.primary,
                    ),
                    const _TeacherMetric(
                      icon: Icons.task_alt_rounded,
                      value: '71%',
                      label: 'média de acertos',
                      trend: '+4%',
                      color: AppColors.mint,
                    ),
                    const _TeacherMetric(
                      icon: Icons.schedule_rounded,
                      value: '18 min',
                      label: 'tempo médio',
                      trend: '+2 min',
                      color: AppColors.amber,
                    ),
                  ];
                  if (constraints.maxWidth >= 760) {
                    return Row(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          Expanded(child: cards[i]),
                          if (i < cards.length - 1) const SizedBox(width: 12),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i < cards.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'Precisa de atenção',
                subtitle: 'Sinais gerados pelo desempenho recente',
                action: TextButton(
                  onPressed: onOpenClasses,
                  child: const Text('Ver turmas'),
                ),
              ),
              const SizedBox(height: 14),
              _InsightCard(
                icon: Icons.warning_amber_rounded,
                color: AppColors.coral,
                title: 'Equações do 1º grau',
                detail: '14 alunos do 3º A ficaram abaixo de 50% nas últimas atividades.',
                action: 'Ver análise da turma',
                onTap: () =>
                    Navigator.pushNamed(context, ClassDetailScreen.route),
              ),
              const SizedBox(height: 12),
              _InsightCard(
                icon: Icons.person_search_rounded,
                color: AppColors.amber,
                title: '3 alunos reduziram o ritmo',
                detail: 'Eles não realizaram atividades há 7 dias ou mais.',
                action: 'Ver estudantes',
                onTap: () => Navigator.pushNamed(
                  context,
                  StudentDetailScreen.route,
                  arguments: StudentProfiles.joao,
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Desempenho por turma'),
              const SizedBox(height: 14),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ClassSummary(
                      name: '3º A · Ensino Médio',
                      students: '31 alunos',
                      activity: '84% ativos',
                      value: .68,
                      color: AppColors.primary,
                      onTap: () => Navigator.pushNamed(
                        context,
                        ClassDetailScreen.route,
                        arguments: ClassInfo.samples[0],
                      ),
                    ),
                    const Divider(height: 1, indent: 18, endIndent: 18),
                    _ClassSummary(
                      name: '3º B · Ensino Médio',
                      students: '29 alunos',
                      activity: '79% ativos',
                      value: .73,
                      color: AppColors.mint,
                      onTap: () => Navigator.pushNamed(
                        context,
                        ClassDetailScreen.route,
                        arguments: ClassInfo.samples[1],
                      ),
                    ),
                    const Divider(height: 1, indent: 18, endIndent: 18),
                    _ClassSummary(
                      name: '2º A · Ensino Médio',
                      students: '32 alunos',
                      activity: '88% ativos',
                      value: .77,
                      color: AppColors.amber,
                      onTap: () => Navigator.pushNamed(
                        context,
                        ClassDetailScreen.route,
                        arguments: ClassInfo.samples[2],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Atividade recente'),
              const SizedBox(height: 14),
              const SurfaceCard(
                child: Column(
                  children: [
                    _ActivityRow(
                      initials: 'MC',
                      name: 'Marina Costa',
                      action: 'concluiu Equações do 1º grau',
                      time: 'há 8 min',
                      color: AppColors.primary,
                    ),
                    Divider(height: 24),
                    _ActivityRow(
                      initials: 'RL',
                      name: 'Rafael Lima',
                      action: 'avançou para o nível 6',
                      time: 'há 22 min',
                      color: AppColors.mint,
                    ),
                    Divider(height: 24),
                    _ActivityRow(
                      initials: 'JS',
                      name: 'João Souza',
                      action: 'precisa revisar Funções',
                      time: 'há 1 h',
                      color: AppColors.coral,
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

class _TeacherMetric extends StatelessWidget {
  const _TeacherMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.trend,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final String trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          TagChip(label: trend, color: AppColors.mint),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  action,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _ClassSummary extends StatelessWidget {
  const _ClassSummary({
    required this.name,
    required this.students,
    required this.activity,
    required this.value,
    required this.color,
    required this.onTap,
  });
  final String name;
  final String students;
  final String activity;
  final double value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      title: Text(name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text('$students · $activity'),
      ),
      trailing: SizedBox(
        width: 88,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            ProgressBar(value: value, color: color, height: 6),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.initials,
    required this.name,
    required this.action,
    required this.time,
    required this.color,
  });
  final String initials;
  final String name;
  final String action;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InitialAvatar(initials: initials, size: 40, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$name ',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: action),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    );
  }
}
