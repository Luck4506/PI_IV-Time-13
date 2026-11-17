import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'text_form_dialog.dart';
import 'widgets.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService.instance;

    return ListenableBuilder(
      listenable: api,
      builder: (context, _) {
        final user = api.user;
        if (user == null) return const SizedBox.shrink();

        return SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              InitialAvatar(initials: user.initials),
              Text(user.name, style: Theme.of(context).textTheme.titleLarge),
              Text(user.email),
              if (user.schoolCode case final code?)
                Text('Código da escola $code'),
              if (user.schoolYear case final year?) Text(year),
              OutlinedButton.icon(
                onPressed: () => showTextForm(
                  context,
                  title: 'Editar dados pessoais',
                  field: 'Nome completo',
                  button: 'Salvar',
                  initialValue: user.name,
                  validate: (value) {
                    final length = value?.trim().length ?? 0;
                    return length >= 2 && length <= 120
                        ? null
                        : 'Use de 2 a 120 caracteres.';
                  },
                  submit: (name) => api.updateProfile(name: name),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar nome'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LogoutButton extends StatefulWidget {
  const LogoutButton({super.key});

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool leaving = false;

  Future<void> _logout() async {
    setState(() => leaving = true);
    try {
      // O app observa o encerramento da sessão e volta ao login.
      await ApiService.instance.logout();
    } on ApiException catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      setState(() => leaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: leaving ? null : _logout,
      icon: const Icon(Icons.logout),
      label: Text(leaving ? 'Saindo…' : 'Sair'),
    );
  }
}
