// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';

import '../../account_card.dart';
import '../../remote_content.dart';
import '../../services/classroom_api.dart';
import '../../widgets.dart';

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollPage(
      children: [
        const SectionHeader(title: 'Perfil do professor'),
        const AccountCard(),
        RemoteContent<TeacherClasses>(
          load: ClassroomApi().teacherClasses,
          builder: (context, data, _) => SurfaceCard(
            child: Text(
              data.subject == null
                  ? 'Defina sua disciplina na aba Turmas.'
                  : 'Disciplina vinculada: ${data.subject}',
            ),
          ),
        ),
        const Align(alignment: Alignment.centerLeft, child: LogoutButton()),
      ],
    );
  }
}
