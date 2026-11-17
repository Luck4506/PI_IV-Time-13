import 'package:flutter/material.dart';

import '../../remote_content.dart';
import '../../services/classroom_api.dart';
import 'tela_painel_professor.dart';
import 'tela_perfil_professor.dart';
import 'tela_relatorios.dart';
import 'tela_turmas.dart';

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  static const route = '/professor';

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  final api = ClassroomApi();
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: index == 3
          ? const TeacherProfileScreen()
          : RemoteContent<TeacherClasses>(
              load: api.teacherClasses,
              builder: (context, data, refresh) => switch (index) {
                1 => ClassesScreen(data: data, refresh: refresh),
                2 => ReportsScreen(classes: data.classes),
                _ => TeacherDashboardScreen(
                  data: data,
                  onOpenClasses: () => setState(() => index = 1),
                  onOpenReports: () => setState(() => index = 2),
                ),
              },
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Painel',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'Turmas',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: 'Relatórios',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
