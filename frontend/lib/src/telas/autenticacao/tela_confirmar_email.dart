// Autoria de Lucas Soares Gonçalves RA 25009467
part of '../../telas_autenticacao.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.emailSent,
    this.afterSignup = false,
  });

  final String email;
  final bool? emailSent;
  final bool afterSignup;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final passwordKey = GlobalKey<FormFieldState<String>>();
  final codeKey = GlobalKey<FormFieldState<String>>();
  final password = TextEditingController();
  final code = TextEditingController();

  bool sending = false;
  bool sendFailed = false;
  String? message;

  @override
  void dispose() {
    password.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool resend}) async {
    if (sending || !passwordKey.currentState!.validate()) return;
    if (!resend && !codeKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      sending = true;
      message = null;
      sendFailed = false;
    });

    try {
      final api = ApiService.instance;
      if (resend) {
        await api.resendConfirmation(widget.email, password.text);
        if (!mounted) return;

        setState(() {
          message = 'Se a senha estiver correta, você receberá outro código. Aguarde um minuto entre pedidos.';
        });
      } else {
        await api.confirmEmail(code.text.trim(), password.text);
        if (mounted) _openLogin();
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          message = error.message;
          sendFailed = true;
        });
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _openLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: LoginScreen.route),
        builder: (_) => LoginScreen(
          initialEmail: widget.email,
          afterSignup: widget.afterSignup,
        ),
      ),
      (_) => false,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                const AppMark(compact: true),
                Text(
                  'Confirme seu e-mail',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(widget.email),
                Text(switch (widget.emailSent) {
                  true => 'Copie o código do e-mail e cole abaixo.',
                  false =>
                    'O envio falhou. Aguarde um minuto e peça outro código.',
                  null => 'Confira sua caixa de entrada. Se o código não chegar, aguarde um minuto e peça outro.',
                }),
                TextFormField(
                  key: codeKey,
                  controller: code,
                  enabled: !sending,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Código do e-mail',
                  ),
                  validator: (value) {
                    if (!RegExp(r'^[A-Za-z0-9_-]{43}$')
                        .hasMatch(value?.trim() ?? '')) {
                      return 'Cole o código completo recebido por e-mail.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  key: passwordKey,
                  controller: password,
                  obscureText: true,
                  enabled: !sending,
                  validator: validatePassword,
                  decoration: const InputDecoration(
                    labelText: 'Senha do cadastro',
                  ),
                ),
                FilledButton(
                  onPressed: sending ? null : () => _submit(resend: false),
                  child: Text(sending ? 'Aguarde…' : 'Confirmar e-mail'),
                ),
                OutlinedButton(
                  onPressed: sending ? null : () => _submit(resend: true),
                  child: const Text('Reenviar código'),
                ),
                TextButton(
                  onPressed: sending ? null : _openLogin,
                  child: const Text('Voltar para entrar'),
                ),
                if (message != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      message!,
                      style: TextStyle(
                        color: sendFailed
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
