// Autoria de Lucas Soares Gonçalves RA 25009467
part of '../../telas_estudante.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollPage(
      children: [
        const SectionHeader(title: 'Seu perfil'),
        const AccountCard(),
        const _MyClass(),
        const Align(alignment: Alignment.centerLeft, child: LogoutButton()),
      ],
    );
  }
}

class _MyClass extends StatefulWidget {
  const _MyClass();

  @override
  State<_MyClass> createState() => _MyClassState();
}

class _MyClassState extends State<_MyClass> {
  final api = ClassroomApi();

  Future<void> _join(VoidCallback refresh) async {
    final saved = await showTextForm(
      context,
      title: 'Entrar na sua turma',
      field: 'Código da turma',
      button: 'Entrar',
      submit: api.joinAsStudent,
      validate: validateClassCode,
      codeField: true,
    );
    if (saved && mounted) refresh();
  }

  Future<void> _leave(Enrollment enrollment, VoidCallback refresh) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sair de ${enrollment.name}?'),
        content: const Text(
          'Seu progresso de estudo fica na sua conta. A turma deixa de ver seus resultados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair da turma'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await api.leaveClass(enrollment.id);
      if (mounted) refresh();
    } on ApiException catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: RemoteContent<Enrollment?>(
        load: api.myClass,
        builder: (context, enrollment, refresh) => Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Minha turma'),
            if (enrollment == null) ...[
              const Text('Entre com o código da sua turma.'),
              FilledButton(
                onPressed: () => _join(refresh),
                child: const Text('Usar código da turma'),
              ),
            ] else ...[
              Text(
                enrollment.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(enrollment.subjects.join(' · ')),
              OutlinedButton(
                onPressed: () => _leave(enrollment, refresh),
                child: const Text('Sair da turma'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
