// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';

import '../../remote_content.dart';
import '../../services/classroom_api.dart';
import '../../widgets.dart';
import 'tela_detalhes_turma.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.classes});

  final List<Classroom> classes;

  @override
  Widget build(BuildContext context) {
    return ScrollPage(
      children: [
        const SectionHeader(
          title: 'Relatórios por turma',
          subtitle:
              'Consulte os quartis e os assuntos que precisam de revisão.',
        ),
        if (classes.isEmpty)
          const SurfaceCard(
            child: Text(
              'Os relatórios aparecem quando você entra em uma turma.',
            ),
          ),
        for (final classroom in classes) ClassReportLink(classroom: classroom),
      ],
    );
  }
}
