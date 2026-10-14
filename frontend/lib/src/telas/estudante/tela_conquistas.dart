part of '../../telas_estudante.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

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
                title: 'Conquistas',
                subtitle: 'Celebre a constância e cada habilidade construída',
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC857), Color(0xFFF39A3C)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: const BoxDecoration(
                            color: Color(0x36FFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Nível 8',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Exploradora',
                                style: TextStyle(
                                  color: Color(0xE8FFFFFF),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '1.240 XP',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const ProgressBar(
                      value: .62,
                      color: AppColors.white,
                      backgroundColor: Color(0x35FFFFFF),
                      height: 9,
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '760 XP para o nível 9',
                        style: TextStyle(
                          color: Color(0xE8FFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Missões da semana',
                subtitle: '2 de 3 concluídas',
              ),
              const SizedBox(height: 14),
              const _MissionCard(
                title: 'Estude em 4 dias diferentes',
                detail: '3 de 4 dias',
                icon: Icons.calendar_month_rounded,
                value: .75,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              const _MissionCard(
                title: 'Acerte 20 questões',
                detail: 'Concluída · +100 XP',
                icon: Icons.task_alt_rounded,
                value: 1,
                color: AppColors.mint,
              ),
              const SizedBox(height: 12),
              const _MissionCard(
                title: 'Faça uma revisão programada',
                detail: 'Concluída · +50 XP',
                icon: Icons.replay_rounded,
                value: 1,
                color: AppColors.mint,
              ),
              const SizedBox(height: 28),
              const SectionHeader(
                title: 'Suas medalhas',
                subtitle: '4 de 12 desbloqueadas',
              ),
              const SizedBox(height: 14),
              GridView.extent(
                maxCrossAxisExtent: 160,
                mainAxisExtent: 150,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: const [
                  _Medal(
                    icon: Icons.local_fire_department_rounded,
                    name: 'Em ritmo',
                    color: AppColors.coral,
                    unlocked: true,
                  ),
                  _Medal(
                    icon: Icons.psychology_alt_rounded,
                    name: 'Curiosa',
                    color: AppColors.primary,
                    unlocked: true,
                  ),
                  _Medal(
                    icon: Icons.track_changes_rounded,
                    name: 'Na mira',
                    color: AppColors.mint,
                    unlocked: true,
                  ),
                  _Medal(
                    icon: Icons.bolt_rounded,
                    name: 'Sem parar',
                    color: AppColors.amber,
                    unlocked: true,
                  ),
                  _Medal(
                    icon: Icons.nights_stay_rounded,
                    name: 'Coruja',
                    color: AppColors.primary,
                    unlocked: false,
                  ),
                  _Medal(
                    icon: Icons.diamond_outlined,
                    name: 'Imbatível',
                    color: AppColors.mint,
                    unlocked: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.title,
    required this.detail,
    required this.icon,
    required this.value,
    required this.color,
  });
  final String title;
  final String detail;
  final IconData icon;
  final double value;
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
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 9),
                ProgressBar(value: value, color: color, height: 7),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  const _Medal({
    required this.icon,
    required this.name,
    required this.color,
    required this.unlocked,
  });
  final IconData icon;
  final String name;
  final Color color;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : .38,
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .13),
                shape: BoxShape.circle,
              ),
              child: Icon(
                unlocked ? icon : Icons.lock_outline_rounded,
                color: color,
                size: 27,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
