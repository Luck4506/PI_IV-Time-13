import 'package:flutter/material.dart';

import 'telas_autenticacao.dart';
import 'telas_estudante.dart';
import 'telas_professor.dart';
import 'theme.dart';

class TrilhaApp extends StatelessWidget {
  const TrilhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trilha',
      debugShowCheckedModeBanner: false,
      theme: buildTrilhaTheme(),
      initialRoute: LoginScreen.route,
      routes: {
        RegisterScreen.route: (_) => const RegisterScreen(),
        DiagnosticIntroScreen.route: (_) => const DiagnosticIntroScreen(),
        DiagnosticQuizScreen.route: (_) => const DiagnosticQuizScreen(),
        DiagnosticResultScreen.route: (_) => const DiagnosticResultScreen(),
        StudentShell.route: (_) => const StudentShell(),
        TeacherShell.route: (_) => const TeacherShell(),
        NotificationsScreen.route: (_) => const NotificationsScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case LoginScreen.route:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => LoginScreen(
                initialRole:
                    settings.arguments as UserRole? ?? UserRole.student,
              ),
            );
          case PracticeScreen.route:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const PracticeScreen(),
              fullscreenDialog: true,
            );
          case MaterialDetailScreen.route:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const MaterialDetailScreen(),
            );
          case ClassDetailScreen.route:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ClassDetailScreen(
                classInfo: settings.arguments is ClassInfo
                    ? settings.arguments as ClassInfo
                    : ClassInfo.samples.first,
              ),
            );
          case StudentDetailScreen.route:
            final student = settings.arguments;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => StudentDetailScreen(
                student: student is StudentProfileData
                    ? student
                    : StudentProfiles.marina,
              ),
            );
        }
        return null;
      },
    );
  }
}
