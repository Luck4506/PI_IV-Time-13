import 'package:flutter/material.dart';

import '../../remote_content.dart';
import '../../services/api_service.dart';
import '../../services/classroom_api.dart';
import '../../widgets.dart';
import '../../text_form_dialog.dart';
import 'tela_detalhes_turma.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key, required this.data, required this.refresh});

  final TeacherClasses data;
  final VoidCallback refresh;

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final api = ClassroomApi();
  String search = '';

  Future<void> _classForm({required bool join}) async {
    final saved = await showTextForm(
      context,
      title: join ? 'Entrar em uma turma' : 'Criar turma',
      field: join ? 'Código do convite' : 'Nome da turma',
      button: join ? 'Entrar' : 'Criar',
      submit: join ? api.joinAsTeacher : api.createClass,
      validate: join ? validateClassCode : validateClassName,
      codeField: join,
    );

    if (saved && mounted) widget.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final visible = data.classes.where(
      (row) => row.name.toLowerCase().contains(search),
    );

    return ScrollPage(
      children: [
        const SectionHeader(title: 'Minhas turmas'),
        if (data.subject == null)
          _SubjectSetup(onSaved: widget.refresh)
        else ...[
          Text('Disciplina: ${data.subject}'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _classForm(join: false),
                icon: const Icon(Icons.add),
                label: const Text('Criar turma'),
              ),
              OutlinedButton(
                onPressed: () => _classForm(join: true),
                child: const Text('Usar convite de professor'),
              ),
            ],
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar turma',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) =>
                setState(() => search = value.trim().toLowerCase()),
          ),
          if (visible.isEmpty)
            SurfaceCard(
              child: Text(
                data.classes.isEmpty
                    ? 'Crie uma turma ou use um convite de professor.'
                    : 'Nenhuma turma encontrada.',
              ),
            ),
          for (final classroom in visible)
            ClassReportLink(classroom: classroom),
        ],
      ],
    );
  }
}

class _SubjectSetup extends StatefulWidget {
  const _SubjectSetup({required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<_SubjectSetup> createState() => _SubjectSetupState();
}

class _SubjectSetupState extends State<_SubjectSetup> {
  final api = ClassroomApi();
  String? selected;
  String? error;
  bool saving = false;

  Future<void> _save() async {
    final subject = selected;
    if (subject == null) return;

    setState(() {
      saving = true;
      error = null;
    });
    try {
      await api.chooseSubject(subject);
      if (mounted) widget.onSaved();
    } on ApiException catch (failure) {
      if (mounted) {
        setState(() {
          saving = false;
          error = failure.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: RemoteContent<List<String>>(
        load: api.subjects,
        builder: (context, subjects, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            const Text(
              'Escolha a disciplina que você leciona. Esta escolha define os dados que você poderá consultar nas turmas.',
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selected,
              decoration: const InputDecoration(labelText: 'Disciplina'),
              items: [
                for (final subject in subjects)
                  DropdownMenuItem(value: subject, child: Text(subject)),
              ],
              onChanged: saving
                  ? null
                  : (value) => setState(() => selected = value),
            ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              onPressed: saving || selected == null ? null : _save,
              child: Text(saving ? 'Salvando…' : 'Definir disciplina'),
            ),
          ],
        ),
      ),
    );
  }
}
