part of '../../telas_professor.dart';

class ClassDetailScreen extends StatelessWidget {
  const ClassDetailScreen({
    super.key,
    this.classInfo = const ClassInfo('3º A', 31, 68),
  });
  final ClassInfo classInfo;

  static const route = '/professor/turma';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${classInfo.name} · Matemática'),
        actions: [
          IconButton(
            onPressed: () => showPendingFeature(context),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageFrame(
            maxWidth: 880,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatPill(
                      icon: Icons.groups_rounded,
                      value: '${classInfo.students}',
                      label: 'estudantes',
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 10),
                    StatPill(
                      icon: Icons.task_alt_rounded,
                      value: '${classInfo.average}%',
                      label: 'média',
                      color: AppColors.mint,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Mapa de aprendizagem',
                  subtitle: 'Domínio estimado por assunto',
                ),
                const SizedBox(height: 14),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HeatRow(
                        topic: 'Razão e proporção',
                        values: [.9, .7, .8, .9, .6, .8, .7],
                        color: AppColors.mint,
                      ),
                      const SizedBox(height: 14),
                      const _HeatRow(
                        topic: 'Equações',
                        values: [.3, .4, .7, .2, .6, .4, .3],
                        color: AppColors.coral,
                      ),
                      const SizedBox(height: 14),
                      const _HeatRow(
                        topic: 'Funções',
                        values: [.5, .6, .4, .7, .5, .6, .4],
                        color: AppColors.amber,
                      ),
                      const SizedBox(height: 14),
                      const _HeatRow(
                        topic: 'Gráficos',
                        values: [.7, .8, .6, .6, .7, .8, .6],
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            'menor domínio',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(width: 6),
                          _LegendDot(color: Color(0xFFEAF5F1)),
                          _LegendDot(color: Color(0xFF9DDCCB)),
                          _LegendDot(color: AppColors.mint),
                          SizedBox(width: 6),
                          Text(
                            'maior',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SectionHeader(
                  title: 'Estudantes',
                  subtitle: 'Exemplo de estudantes · ordenados por necessidade de apoio',
                  action: IconButton.outlined(
                    onPressed: () => showPendingFeature(context),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _StudentRow(
                        student: StudentProfiles.joao,
                        onTap: () => Navigator.pushNamed(
                          context,
                          StudentDetailScreen.route,
                          arguments: StudentProfiles.joao,
                        ),
                      ),
                      const Divider(height: 1, indent: 18, endIndent: 18),
                      _StudentRow(
                        student: StudentProfiles.marina,
                        onTap: () => Navigator.pushNamed(
                          context,
                          StudentDetailScreen.route,
                          arguments: StudentProfiles.marina,
                        ),
                      ),
                      const Divider(height: 1, indent: 18, endIndent: 18),
                      _StudentRow(
                        student: StudentProfiles.rafael,
                        onTap: () => Navigator.pushNamed(
                          context,
                          StudentDetailScreen.route,
                          arguments: StudentProfiles.rafael,
                        ),
                      ),
                      const Divider(height: 1, indent: 18, endIndent: 18),
                      _StudentRow(
                        student: StudentProfiles.beatriz,
                        onTap: () => Navigator.pushNamed(
                          context,
                          StudentDetailScreen.route,
                          arguments: StudentProfiles.beatriz,
                        ),
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
}

class _HeatRow extends StatelessWidget {
  const _HeatRow({
    required this.topic,
    required this.values,
    required this.color,
  });
  final String topic;
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          topic,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Row(
          children: values
              .map(
                (value) => Expanded(
                  child: Container(
                    height: 24,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .18 + value * .75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 15,
    height: 9,
    margin: const EdgeInsets.only(right: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, required this.onTap});
  final StudentProfileData student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: InitialAvatar(
        initials: student.initials,
        size: 42,
        color: student.accentColor,
      ),
      title: Text(student.name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(student.listDetail),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${student.accuracy}%',
            style: TextStyle(
              color: student.accentColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
