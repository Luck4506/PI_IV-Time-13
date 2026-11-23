// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';

import 'remote_content.dart';
import 'services/api_service.dart';
import 'services/classroom_api.dart';

class PracticeSubjectButton extends StatefulWidget {
  const PracticeSubjectButton({super.key, required this.onStarted});

  final ValueChanged<String> onStarted;

  @override
  State<PracticeSubjectButton> createState() => _PracticeSubjectButtonState();
}

class _PracticeSubjectButtonState extends State<PracticeSubjectButton> {
  final classroomApi = ClassroomApi();
  bool starting = false;
  String? previousSubject;
  String? requestKey;

  Future<void> _pick() async {
    final subject = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Praticar por disciplina'),
        content: SizedBox(
          height: 290,
          width: 360,
          child: RemoteContent<List<String>>(
            load: classroomApi.subjects,
            builder: (context, subjects, _) => subjects.isEmpty
                ? const Center(child: Text('Nenhuma disciplina disponível.'))
                : ListView(
                    children: [
                      for (final subject in subjects)
                        ListTile(
                          title: Text(subject),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, subject),
                        ),
                    ],
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (subject == null || !mounted) return;

    if (previousSubject != subject) requestKey = null;
    previousSubject = subject;
    requestKey ??= ApiService.requestKey();
    setState(() => starting = true);

    try {
      final result = await ApiService.instance.startTrail(
        diagnostic: false,
        subject: subject,
        key: requestKey!,
      );
      final trail = result['trilha'] as Map<String, dynamic>;
      requestKey = null;
      if (mounted) widget.onStarted(trail['id'] as String);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: starting ? null : _pick,
        icon: const Icon(Icons.menu_book_outlined),
        label: Text(starting ? 'Criando prática…' : 'Praticar por disciplina'),
      ),
    );
  }
}
