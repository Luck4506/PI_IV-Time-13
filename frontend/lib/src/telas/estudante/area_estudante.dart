// Autoria de Lucas Soares Gonçalves RA 25009467
part of '../../telas_estudante.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  static const route = '/aluno';

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ao voltar da trilha, a página consulta o histórico de novo.
      // Assim o XP e as medalhas já refletem as respostas que acabaram de chegar.
      body: switch (index) {
        1 => const LearningTrailScreen(),
        2 => const ProgressScreen(),
        3 => const RewardsScreen(),
        4 => const StudentProfileScreen(),
        _ => StudentHomeScreen(
          onOpenTrail: () => setState(() => index = 1),
          onOpenProgress: () => setState(() => index = 2),
        ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route_rounded),
            label: 'Trilha',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Progresso',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Conquistas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
