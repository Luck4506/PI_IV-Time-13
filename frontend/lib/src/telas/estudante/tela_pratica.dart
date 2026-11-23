// Autoria de Lucas Soares Gonçalves RA 25009467
part of '../../telas_estudante.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});
  static const route = '/aluno/pratica';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sua trilha')),
    body: const UserTrailView(),
  );
}
