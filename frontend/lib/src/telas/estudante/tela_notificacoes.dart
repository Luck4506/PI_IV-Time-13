part of '../../telas_estudante.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const route = '/notificacoes';
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool allRead = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          TextButton(
            onPressed: allRead ? null : () => setState(() => allRead = true),
            child: const Text('Marcar como lidas'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            _NotificationTile(
              icon: Icons.replay_rounded,
              color: AppColors.primary,
              title: 'Sua revisão está pronta',
              detail:
                  '5 questões de equações para fortalecer o que você aprendeu.',
              time: 'Agora',
              unread: !allRead,
            ),
            SizedBox(height: 12),
            _NotificationTile(
              icon: Icons.emoji_events_rounded,
              color: AppColors.amber,
              title: 'Nova medalha desbloqueada!',
              detail: 'Você ganhou “Em ritmo” por estudar durante 7 dias.',
              time: 'Ontem',
              unread: !allRead,
            ),
            SizedBox(height: 12),
            _NotificationTile(
              icon: Icons.trending_up_rounded,
              color: AppColors.mint,
              title: 'Seu resumo semanal chegou',
              detail: 'Você evoluiu 12% e manteve uma ótima consistência.',
              time: 'Domingo',
              unread: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.time,
    required this.unread,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String time;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: unread ? const Color(0xFFF4F6FF) : AppColors.white,
      borderColor: unread ? const Color(0xFFDCE3FF) : AppColors.border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
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
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(left: 7, top: 4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
