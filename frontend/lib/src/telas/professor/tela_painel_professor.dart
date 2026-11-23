// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';

import '../../remote_content.dart';
import '../../services/api_service.dart';
import '../../services/classroom_api.dart';
import '../../widgets.dart';
import 'tela_detalhes_turma.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({
    super.key,
    required this.data,
    required this.onOpenClasses,
    required this.onOpenReports,
  });

  final TeacherClasses data;
  final VoidCallback onOpenClasses;
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    final teacher = ApiService.instance.user;

    return ScrollPage(
      children: [
        const AppMark(compact: true),
        const SizedBox(height: 6),
        Text(
          'Olá, ${teacher?.firstName ?? 'professor'}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(data.subject ?? 'Defina sua disciplina para começar.'),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                data.classes.length == 1
                    ? '1 turma vinculada'
                    : '${data.classes.length} turmas vinculadas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'Veja os resultados da sua disciplina e abra os detalhes de cada aluno.',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                    onPressed: onOpenClasses,
                    child: const Text('Gerenciar turmas'),
                  ),
                  OutlinedButton(
                    onPressed: onOpenReports,
                    child: const Text('Ver relatórios'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (data.classes.isNotEmpty) const SectionHeader(title: 'Suas turmas'),
        for (final classroom in data.classes)
          ClassReportLink(classroom: classroom),
      ],
    );
  }
}
