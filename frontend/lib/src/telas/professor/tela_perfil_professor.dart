part of '../../telas_professor.dart';

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageFrame(
          maxWidth: 720,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          child: Column(
            children: [
              const AppMark(compact: true),
              const SizedBox(height: 28),
              InitialAvatar(
                initials: ApiService.instance.user?.initials ?? 'P',
                size: 86,
                color: AppColors.mint,
              ),
              const SizedBox(height: 12),
              Text(
                ApiService.instance.user?.name ?? 'Professor',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                ApiService.instance.user?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              TagChip(
                label:
                    ApiService.instance.user?.schoolCode ??
                    'Escola não informada',
                icon: Icons.apartment_rounded,
                color: AppColors.mint,
              ),
              const SizedBox(height: 28),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _TeacherProfileTile(
                      icon: Icons.person_outline,
                      title: 'Dados pessoais',
                      onTap: () => showPendingFeature(context),
                    ),
                    const Divider(height: 1, indent: 62),
                    _TeacherProfileTile(
                      icon: Icons.apartment_outlined,
                      title: 'Vínculo escolar',
                      onTap: () => showPendingFeature(context),
                    ),
                    const Divider(height: 1, indent: 62),
                    _TeacherProfileTile(
                      icon: Icons.notifications_outlined,
                      title: 'Preferências de avisos',
                      onTap: () => showPendingFeature(context),
                    ),
                    const Divider(height: 1, indent: 62),
                    _TeacherProfileTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacidade dos estudantes',
                      onTap: () => showPendingFeature(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _TeacherProfileTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Central de ajuda',
                      onTap: () => showPendingFeature(context),
                    ),
                    const Divider(height: 1, indent: 62),
                    _TeacherProfileTile(
                      icon: Icons.logout_rounded,
                      title: 'Sair',
                      color: AppColors.coral,
                      onTap: () async {
                        try {
                          await ApiService.instance.logout();
                        } on ApiException catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Não foi possível sair. ${error.message}',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen(
                              initialRole: UserRole.teacher,
                            ),
                          ),
                          (_) => false,
                        );
                      },
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

class _TeacherProfileTile extends StatelessWidget {
  const _TeacherProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = AppColors.ink,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color == AppColors.coral ? AppColors.coral : AppColors.muted,
      ),
    );
  }
}
