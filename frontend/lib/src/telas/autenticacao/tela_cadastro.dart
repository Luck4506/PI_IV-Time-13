part of '../../telas_autenticacao.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const route = '/cadastro';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  UserRole role = UserRole.student;
  bool accepted = false;
  final formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initialRole = ModalRoute.of(context)?.settings.arguments;
    if (!_initialized && initialRole is UserRole) role = initialRole;
    _initialized = true;
  }

  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageFrame(
            maxWidth: 540,
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crie sua conta',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leva menos de dois minutos.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.student,
                        label: Text('Estudante'),
                      ),
                      ButtonSegment(
                        value: UserRole.teacher,
                        label: Text('Professor'),
                      ),
                    ],
                    selected: {role},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        setState(() => role = value.first),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    validator: validateRequired,
                    decoration: InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    validator: validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    validator: role == UserRole.student
                        ? validateRequired
                        : null,
                    keyboardType: role == UserRole.student
                        ? TextInputType.number
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: role == UserRole.student
                          ? 'Ano escolar'
                          : 'Código da escola (opcional)',
                      prefixIcon: Icon(
                        role == UserRole.student
                            ? Icons.calendar_today_outlined
                            : Icons.apartment_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    validator: validatePassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Crie uma senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    value: accepted,
                    onChanged: (value) =>
                        setState(() => accepted = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Li e aceito os termos de uso e a política de privacidade.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: accepted
                        ? () {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              role == UserRole.student
                                  ? DiagnosticIntroScreen.route
                                  : TeacherShell.route,
                              (route) => false,
                            );
                          }
                        : null,
                    child: Text(
                      role == UserRole.student
                          ? 'Continuar e personalizar'
                          : 'Continuar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
