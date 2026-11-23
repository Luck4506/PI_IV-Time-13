// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';

import 'services/api_service.dart';

Future<bool> showTextForm(
  BuildContext context, {
  required String title,
  required String field,
  required String button,
  required Future<void> Function(String) submit,
  required String? Function(String?) validate,
  TextInputType? keyboardType,
  String? initialValue,
  bool codeField = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => _TextFormDialog(
          title: title,
          field: field,
          button: button,
          submit: submit,
          validate: validate,
          keyboardType: keyboardType,
          initialValue: initialValue,
          codeField: codeField,
        ),
      ) ??
      false;
}

class _TextFormDialog extends StatefulWidget {
  const _TextFormDialog({
    required this.title,
    required this.field,
    required this.button,
    required this.submit,
    required this.validate,
    this.keyboardType,
    this.initialValue,
    required this.codeField,
  });

  final String title;
  final String field;
  final String button;
  final Future<void> Function(String) submit;
  final String? Function(String?) validate;
  final TextInputType? keyboardType;
  final String? initialValue;
  final bool codeField;

  @override
  State<_TextFormDialog> createState() => _TextFormDialogState();
}

class _TextFormDialogState extends State<_TextFormDialog> {
  final form = GlobalKey<FormState>();
  late final controller = TextEditingController(text: widget.initialValue);
  bool saving = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (saving || !form.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      saving = true;
      error = null;
    });

    try {
      await widget.submit(controller.text.trim());
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (failure) {
      if (mounted) {
        setState(() {
          error = failure.message;
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !saving,
      child: AlertDialog(
        scrollable: true,
        title: Text(widget.title),
        content: Form(
          key: form,
          child: TextFormField(
            controller: controller,
            enabled: !saving,
            autofocus: true,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.codeField
                ? TextCapitalization.characters
                : TextCapitalization.none,
            autocorrect: !widget.codeField,
            enableSuggestions: !widget.codeField,
            validator: widget.validate,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: widget.field,
              errorText: error,
              errorMaxLines: 3,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: saving ? null : _submit,
            child: Text(saving ? 'Salvando…' : widget.button),
          ),
        ],
      ),
    );
  }
}

String? validateClassName(String? text) {
  final length = text?.trim().length ?? 0;
  return length < 2 || length > 80 ? 'Use de 2 a 80 caracteres.' : null;
}

String? validateClassCode(String? text) {
  return RegExp(r'^[A-Fa-f0-9]{12}$').hasMatch(text?.trim() ?? '')
      ? null
      : 'Informe os 12 caracteres do código.';
}
