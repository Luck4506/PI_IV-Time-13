// Autoria de Lucas Soares Gonçalves RA 25009467
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
    final user = ApiService.instance.user;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageFrame(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  Row(
                    spacing: 10,
                    children: [
                      InitialAvatar(initials: user?.initials ?? 'U'),
                      Expanded(
                        child: Text(
                          'Olá, ${user?.firstName ?? 'estudante'}!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Notificações',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          NotificationsScreen.route,
                        ),
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    ],
                  ),
                  SurfaceCard(
                    color: AppColors.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        const Text(
                          'Sua trilha de aprendizagem',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Estude um conteúdo, pratique e avance para a próxima etapa.',
                          style: TextStyle(color: Colors.white),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                          ),
                          onPressed: onOpenTrail,
                          child: const Text('Abrir minha trilha'),
                        ),
                      ],
                    ),
                  ),
                  RemoteContent<StudyActivity>(
                    load: ActivityApi().activity,
                    builder: (context, activity, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 14,
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            StatPill(
                              icon: Icons.local_fire_department,
                              value: '${activity.streak}',
                              label: 'dias seguidos',
                              color: AppColors.coral,
                            ),
                            StatPill(
                              icon: Icons.stars,
                              value: '${activity.xp}',
                              label: 'pontos XP',
                              color: AppColors.amber,
                            ),
                          ],
                        ),
                        SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              const SectionHeader(title: 'Meta de hoje'),
                              Text(
                                '${activity.today} de 5 questões respondidas',
                              ),
                              ProgressBar(
                                value: (activity.today / 5).clamp(0.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                        SurfaceCard(
                          key: const Key('weekly-progress-card'),
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            title: const Text('Seus últimos 7 dias'),
                            subtitle: Text(
                              '${activity.weeklyAnswers} questões respondidas',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: onOpenProgress,
                          ),
                        ),
                      ],
                    ),
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
