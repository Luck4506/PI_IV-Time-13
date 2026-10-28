part of '../../telas_estudante.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({
    super.key,
    required this.onOpenTrail,
    required this.onOpenProgress,
  });

  final VoidCallback onOpenTrail;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageFrame(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      InitialAvatar(
                        initials: ApiService.instance.user?.initials ?? 'U',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, ${ApiService.instance.user?.firstName ?? 'estudante'}!',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Text(
                              'Seu próximo passo está pronto.',
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
                        tooltip: 'Notificações',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          NotificationsScreen.route,
                        ),
                        icon: const Badge(
                          smallSize: 7,
                          child: Icon(Icons.notifications_none_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: const [
                      StatPill(
                        icon: Icons.local_fire_department_rounded,
                        value: '7 dias',
                        label: 'sequência',
                        color: AppColors.coral,
                      ),
                      SizedBox(width: 10),
                      StatPill(
                        icon: Icons.stars_rounded,
                        value: '1.240',
                        label: 'pontos XP',
                        color: AppColors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _DailyMissionCard(onOpenTrail: onOpenTrail),
                  const SizedBox(height: 28),
                  SectionHeader(
                    title: 'Recomendado para você',
                    subtitle: 'Com base nos seus últimos resultados',
                    action: TextButton(
                      onPressed: onOpenTrail,
                      child: const Text('Ver trilha'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _RecommendationCard(
                    title: 'Equações do 1º grau',
                    detail: 'Prática guiada · 8 questões',
                    reason: 'Prioridade alta',
                    icon: Icons.calculate_outlined,
                    color: AppColors.coral,
                    buttonLabel: 'Praticar agora',
                    onTap: () =>
                        Navigator.pushNamed(context, PracticeScreen.route),
                  ),
                  const SizedBox(height: 12),
                  _RecommendationCard(
                    title: 'Funções: ideia geral',
                    detail: 'Resumo visual · 6 min',
                    reason: 'Material de apoio',
                    icon: Icons.play_lesson_outlined,
                    color: AppColors.primary,
                    buttonLabel: 'Abrir resumo',
                    onTap: () => Navigator.pushNamed(
                      context,
                      MaterialDetailScreen.route,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SectionHeader(
                    title: 'Sua semana',
                    subtitle: 'Consistência vale mais que pressa',
                  ),
                  const SizedBox(height: 14),
                  _WeeklyCard(
                    key: const Key('weekly-progress-card'),
                    onTap: onOpenProgress,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyMissionCard extends StatelessWidget {
  const _DailyMissionCard({required this.onOpenTrail});

  final VoidCallback onOpenTrail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33315EF5),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const TagChip(
                label: 'META DO DIA',
                icon: Icons.flag_rounded,
                color: AppColors.white,
                backgroundColor: Color(0x2EFFFFFF),
              ),
              Text(
                '1 de 3',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .8),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Mais 12 minutos e você conclui sua meta',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Continue pela atividade mais importante da sua trilha.',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: .76),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ProgressBar(
            value: .36,
            color: AppColors.mint,
            backgroundColor: AppColors.white.withValues(alpha: .2),
            height: 9,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, PracticeScreen.route),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Continuar estudando'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.title,
    required this.detail,
    required this.reason,
    required this.icon,
    required this.color,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String detail;
  final String reason;
  final IconData icon;
  final Color color;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 62,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TagChip(label: reason, color: color),
                const SizedBox(height: 7),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const values = [.45, .72, .28, .84, .60, .18, 0.0];
    const days = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: AppColors.mint),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '1h42 de foco',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Text(
                '+18%',
                style: TextStyle(
                  color: AppColors.mint,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: values[index] == 0
                                ? .05
                                : values[index],
                            child: Container(
                              decoration: BoxDecoration(
                                color: index == 4
                                    ? AppColors.primary
                                    : const Color(0xFFDCE3FF),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          days[index],
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
