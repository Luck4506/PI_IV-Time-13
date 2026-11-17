part of '../../telas_estudante.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const route = '/notificacoes';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final api = ActivityApi();
  bool saving = false;

  Future<void> _markRead(VoidCallback refresh) async {
    setState(() => saving = true);
    try {
      await api.markRead();
      if (mounted) refresh();
    } on ApiException catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: RemoteContent<List<StudyNotice>>(
        load: api.notices,
        builder: (context, notices, refresh) => ScrollPage(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: saving || notices.every((notice) => notice.read)
                    ? null
                    : () => _markRead(refresh),
                child: const Text('Marcar como lidas'),
              ),
            ),
            if (notices.isEmpty)
              const SurfaceCard(
                child: Text('Você ainda não tem notificações.'),
              ),
            for (final notice in notices)
              SurfaceCard(
                color: notice.read ? AppColors.white : AppColors.amberSoft,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: Text(notice.title),
                  subtitle: Text(
                    MaterialLocalizations.of(context)
                        .formatCompactDate(notice.date.toLocal()),
                  ),
                  trailing: notice.read
                      ? null
                      : const Icon(
                          Icons.circle,
                          size: 9,
                          color: AppColors.primary,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
