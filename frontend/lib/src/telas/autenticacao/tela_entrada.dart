part of '../../telas_autenticacao.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.initialRole});

  static const route = '/login';
  final UserRole initialRole;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late UserRole role = widget.initialRole;
  bool hidePassword = true;
  final formKey = GlobalKey<FormState>();

  void _continue() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      role == UserRole.student ? StudentShell.route : TeacherShell.route,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageFrame(
            maxWidth: 520,
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppMark(compact: true),
                  const SizedBox(height: 30),
                  Text(
                    'Que bom ter você de volta',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acesso local com dados de exemplo. Suas alterações ainda não são salvas.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 26),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.student,
                        icon: Icon(Icons.school_outlined),
                        label: Text('Estudante'),
                      ),
                      ButtonSegment(
                        value: UserRole.teacher,
                        icon: Icon(Icons.co_present_outlined),
                        label: Text('Professor'),
                      ),
                    ],
                    selected: {role},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        setState(() => role = value.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.comfortable,
                      side: WidgetStateProperty.all(
                        const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'E-mail',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ValueKey('email-${role.name}'),
                    validator: validateEmail,
                    initialValue: role == UserRole.student
                        ? 'marina@exemplo.com'
                        : 'prof.ana@escola.com',
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Senha',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () => showPendingFeature(context),
                        child: const Text('Esqueci minha senha'),
                      ),
                    ],
                  ),
                  TextFormField(
                    initialValue: '12345678',
                    validator: validatePassword,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => hidePassword = !hidePassword),
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  FilledButton(
                    key: const Key('login-button'),
                    onPressed: _continue,
                    child: const Text('Entrar'),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => showPendingFeature(context),
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Continuar com Google'),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RegisterScreen.route,
                        arguments: role,
                      ),
                      child: const Text('Ainda não tenho uma conta'),
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
