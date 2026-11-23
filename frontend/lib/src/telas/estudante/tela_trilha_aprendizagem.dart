// Autoria de Lucas Soares Gonçalves RA 25009467
part of '../../telas_estudante.dart';

class LearningTrailScreen extends StatelessWidget {
  const LearningTrailScreen({super.key, this.active = true});
  final bool active;

  @override
  Widget build(BuildContext context) => UserTrailView(active: active);
}
