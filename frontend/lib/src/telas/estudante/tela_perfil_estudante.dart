part of '../../telas_estudante.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool reminders = true;
  bool weeklyReport = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageFrame(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          child: Column(
            children: [
              Row(
                children: [
                  const AppMark(compact: true),
                  const Spacer(),
                  IconButton(
                    onPressed: () => showPendingFeature(context),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              InitialAvatar(
                initials: ApiService.instance.user?.initials ?? 'U',
                size: 86,
              ),
              const SizedBox(height: 12),
              Text(
                ApiService.instance.user?.name ?? 'Estudante',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                ApiService.instance.user?.schoolYear ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  StatPill(
                    icon: Icons.stars_rounded,
                    value: '1.240',
                    label: 'XP total',
                    color: AppColors.amber,
                  ),
                  SizedBox(width: 10),
                  StatPill(
                    icon: Icons.emoji_events_rounded,
                    value: '4',
                    label: 'medalhas',
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Dados pessoais',
                      onTap: () => showPendingFeature(context),
                    ),
                    const Divider(height: 1, indent: 62),
                    _ProfileTile(
                      icon: Icons.flag_outlined,
                      title: 'Metas de estudo',
                      subtitle: '15 min por dia',
                      onTap: () => showPendingFeature(context),
                    ),
                    const Divider(height: 1, indent: 62),
                    _ProfileTile(
                      icon: Icons.palette_outlined,
                      title: 'Personalização',
                      subtitle: 'Avatar e preferências',
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
                    SwitchListTile(
                      value: reminders,
                      onChanged: (value) => setState(() => reminders = value),
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Lembretes de estudo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Às 19:00 em dias úteis'),
                    ),
                    const Divider(height: 1, indent: 62),
                    SwitchListTile(
                      value: weeklyReport,
                      onChanged: (value) =>
                          setState(() => weeklyReport = value),
                      secondary: const Icon(
                        Icons.summarize_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Resumo semanal',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Todo domingo por e-mail'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Ajuda e suporte',
                      onTap: () => showPendingFeature(context),
                    ),
                    const Divider(height: 1, indent: 62),
                    _ProfileTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacidade e dados',
                      onTap: () => showPendingFeature(context),
                    ),
                    const Divider(height: 1, indent: 62),
                    _ProfileTile(
                      icon: Icons.logout_rounded,
                      title: 'Sair',
                      color: AppColors.coral,
                      onTap: () async {
                        await ApiService.instance.logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen(
                              initialRole: UserRole.student,
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color = AppColors.ink,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

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
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color == AppColors.coral ? AppColors.coral : AppColors.muted,
      ),
    );
  }
}
