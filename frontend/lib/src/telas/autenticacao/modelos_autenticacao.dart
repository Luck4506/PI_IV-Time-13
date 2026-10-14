part of '../../telas_autenticacao.dart';

enum UserRole { student, teacher }

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
      ? null
      : 'Informe um e-mail válido.';
}

String? validatePassword(String? value) =>
    (value?.length ?? 0) >= 8 ? null : 'Use pelo menos 8 caracteres.';

String? validateRequired(String? value) =>
    (value?.trim().isEmpty ?? true) ? 'Preencha este campo.' : null;
