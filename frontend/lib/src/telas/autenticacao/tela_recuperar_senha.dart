// Autoria de Lucas Soares Gonçalves RA 25009467
part of '../../telas_autenticacao.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key, required this.initialEmail});

  final String initialEmail;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final form = GlobalKey<FormState>();
  late final email = TextEditingController(text: widget.initialEmail);
  final code = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();

  bool codeRequested = false;
  bool busy = false;
  bool requestedAgain = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool requestCode}) async {
    if (busy) return;
    final resend = codeRequested && requestCode;
    if (!resend && !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });

    try {
      final api = ApiService.instance;
      if (requestCode) {
        await api.requestPasswordReset(email.text.trim());
        if (mounted) {
          setState(() {
            codeRequested = true;
            requestedAgain = resend;
          });
        }
      } else {
        await api.resetPassword(code.text.trim(), password.text);
        if (mounted) Navigator.pop(context, email.text.trim());
      }
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  const AppMark(compact: true),
                  Text(
                    codeRequested
                        ? 'Redefina sua senha'
                        : 'Esqueci minha senha',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (!codeRequested) ...[
                    const Text('Informe o e-mail da sua conta.'),
                    TextFormField(
                      key: const Key('password-recovery-email'),
                      controller: email,
                      enabled: !busy,
                      validator: validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                    ),
                  ] else ...[
                    Text(
                      'Se ${email.text.trim()} estiver cadastrado, você receberá um código válido por 30 minutos.',
                    ),
                    if (requestedAgain)
                      Semantics(
                        liveRegion: true,
                        child: const Text(
                          'Pedido recebido. Aguarde um minuto entre envios.',
                        ),
                      ),
                    TextFormField(
                      key: const Key('password-recovery-code'),
                      controller: code,
                      enabled: !busy,
                      autocorrect: false,
                      enableSuggestions: false,
                      validator: (value) =>
                          RegExp(r'^[A-Za-z0-9_-]{43}$')
                              .hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Cole o código completo recebido por e-mail.',
                      decoration: const InputDecoration(
                        labelText: 'Código de recuperação',
                      ),
                    ),
                    TextFormField(
                      key: const Key('password-recovery-new-password'),
                      controller: password,
                      enabled: !busy,
                      obscureText: true,
                      validator: (value) =>
                          validatePassword(value) ??
                          ((value?.length ?? 0) > 128
                              ? 'Use até 128 caracteres.'
                              : null),
                      decoration: const InputDecoration(
                        labelText: 'Nova senha',
                        helperText: 'Use 8 caracteres ou mais, com 1 letra, 2 números e 1 símbolo.',
                        helperMaxLines: 2,
                      ),
                    ),
                    TextFormField(
                      key: const Key('password-recovery-confirm-password'),
                      controller: confirmation,
                      enabled: !busy,
                      obscureText: true,
                      validator: (value) => value == password.text
                          ? null
                          : 'As senhas precisam ser iguais.',
                      decoration: const InputDecoration(
                        labelText: 'Repita a nova senha',
                      ),
                    ),
                  ],
                  if (error != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => _submit(requestCode: !codeRequested),
                    child: Text(
                      busy
                          ? 'Aguarde…'
                          : codeRequested
                          ? 'Salvar nova senha'
                          : 'Enviar código',
                    ),
                  ),
                  if (codeRequested)
                    OutlinedButton(
                      onPressed: busy ? null : () => _submit(requestCode: true),
                      child: const Text('Reenviar código'),
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
