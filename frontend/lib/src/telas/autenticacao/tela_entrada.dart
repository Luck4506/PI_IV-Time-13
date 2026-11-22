// Autoria de Lucas Soares Gonçalves RA 25009467
part of '../../telas_autenticacao.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.initialEmail = '',
    this.afterSignup = false,
  });

  static const route = '/login';
  final String initialEmail;
  final bool afterSignup;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool hidePassword = true;
  final formKey = GlobalKey<FormState>();
  late final emailController = TextEditingController(text: widget.initialEmail);
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final user = await ApiService.instance.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        user.role == 'teacher'
            ? TeacherShell.route
            : widget.afterSignup
            ? DiagnosticIntroScreen.route
            : StudentShell.route,
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'EMAIL_NAO_CONFIRMADO') {
        final email = emailController.text.trim().toLowerCase();
        passwordController.clear();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => EmailVerificationScreen(
              email: email,
              afterSignup: widget.afterSignup,
            ),
          ),
        );
      } else {
        setState(() => error = e.message);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openPasswordRecovery() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) =>
            PasswordRecoveryScreen(initialEmail: emailController.text.trim()),
      ),
    );
    if (!mounted || email == null) return;

    emailController.text = email;
    passwordController.clear();
    setState(() => error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Senha redefinida. Entre com a nova senha.'),
      ),
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
                    'Que bom ver você de volta!',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Entre com o e-mail e a senha da sua conta.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 26),

                  const Text(
                    'E-mail',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    validator: validateEmail,
                    controller: emailController,
                    enabled: !loading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Digite seu e-mail',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Senha',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: passwordController,
                    enabled: !loading,
                    validator: (value) =>
                        (value ?? '').isEmpty ? 'Informe sua senha.' : null,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      hintText: 'Digite sua senha',
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

                  // Esqueci minha senha - Sofia de Sousa
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading ? null : _openPasswordRecovery,
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),

                  const SizedBox(height: 26),

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
                    key: const Key('login-button'),
                    onPressed: loading ? null : _continue,
                    child: Text(loading ? 'Entrando…' : 'Entrar'),
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, RegisterScreen.route),
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
