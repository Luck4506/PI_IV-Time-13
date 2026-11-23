// Autoria de Lucas Soares Gonçalves RA 25009467
part of '../../telas_autenticacao.dart';

class DiagnosticQuizScreen extends StatelessWidget {
  const DiagnosticQuizScreen({super.key});
  static const route = '/diagnostico/questoes';

  @override
  Widget build(BuildContext context) => const GraphQuizScreen(diagnostic: true);
}
