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
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final schoolController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    for (final controller in [
      nameController,
      emailController,
      schoolController,
      passwordController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!accepted || !formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final user = await ApiService.instance.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        role: role.name,
        schoolField: schoolController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        user.role == 'student'
            ? DiagnosticIntroScreen.route
            : TeacherShell.route,
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

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
                    onSelectionChanged: loading
                        ? null
                        : (value) => setState(() => role = value.first),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: nameController,
                    enabled: !loading,
                    validator: validateRequired,
                    decoration: InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailController,
                    enabled: !loading,
                    validator: validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: schoolController,
                    enabled: !loading,
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
                    controller: passwordController,
                    enabled: !loading,
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
                    onChanged: loading
                        ? null
                        : (value) => setState(() => accepted = value ?? false),
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
                  if (error != null) ...[
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: accepted && !loading ? _register : null,
                    child: Text(
                      loading
                          ? 'Criando conta…'
                          : role == UserRole.student
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
