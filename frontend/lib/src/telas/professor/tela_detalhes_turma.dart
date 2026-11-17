import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../remote_content.dart';
import '../../services/api_service.dart';
import '../../services/classroom_api.dart';
import '../../widgets.dart';
import 'tela_detalhes_estudante.dart';
import 'painel_quartis.dart';

class ClassReportLink extends StatelessWidget {
  const ClassReportLink({super.key, required this.classroom});

  final Classroom classroom;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.groups_outlined),
        title: Text(classroom.name),
        subtitle: Text(classroom.subject),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => ClassDetailScreen(classroom: classroom),
          ),
        ),
      ),
    );
  }
}

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({super.key, required this.classroom});

  final Classroom classroom;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final api = ClassroomApi();
  bool inviting = false;
  bool _renewingCode = false;
  bool _showClassCode = true;

  Future<void> _invite(String classId) async {
    if (inviting) return;

    setState(() => inviting = true);
    try {
      final code = await api.inviteTeacher(classId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Convite de professor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Envie para um professor da mesma escola. O código vale por 24 horas e pode ser usado uma vez.',
              ),
              SelectableText(
                code,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _copy(code, 'Convite copiado.'),
              child: const Text('Copiar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } on ApiException catch (failure) {
      _message(failure.message);
    } finally {
      if (mounted) setState(() => inviting = false);
    }
  }

  Future<void> _rotate(String classId, VoidCallback refresh) async {
    if (_renewingCode) return;
    setState(() => _renewingCode = true);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Renovar código da turma?'),
          content: const Text(
            'O código anterior deixará de funcionar para novas matrículas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Renovar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      await api.rotateStudentCode(classId);
      if (mounted) refresh();
    } on ApiException catch (failure) {
      _message(failure.message);
    } finally {
      if (mounted) setState(() => _renewingCode = false);
    }
  }

  Future<void> _copy(String text, String message) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      _message(message);
    } on PlatformException {
      _message('Não foi possível copiar. Tente novamente.');
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  String _summary(ClassReport report) {
    final students = report.totalStudents;
    final answers = report.score.answers;
    final studentsText = students == 1 ? '1 aluno' : '$students alunos';
    final answersText = answers == 1 ? '1 resposta' : '$answers respostas';
    return '$studentsText · $answersText · ${report.score.label}';
  }

  Widget _classCodeCard(Classroom classroom, VoidCallback refresh) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Código para alunos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: _showClassCode ? 'Ocultar código' : 'Mostrar código',
                icon: Icon(
                  _showClassCode ? Icons.expand_less : Icons.expand_more,
                ),
                onPressed: () => setState(() {
                  _showClassCode = !_showClassCode;
                }),
              ),
            ],
          ),
          if (_showClassCode) ...[
            const Text(
              'Compartilhe o código para que os alunos entrem na turma pelo próprio perfil.',
            ),
            SelectableText(classroom.code),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _copy(classroom.code, 'Código copiado.'),
                  child: const Text('Copiar código'),
                ),
                if (classroom.canInviteTeachers) ...[
                  TextButton(
                    onPressed: inviting ? null : () => _invite(classroom.id),
                    child: const Text('Convidar professor'),
                  ),
                  TextButton(
                    onPressed: _renewingCode
                        ? null
                        : () => _rotate(classroom.id, refresh),
                    child: const Text('Renovar código'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classroom = widget.classroom;
    return Scaffold(
      appBar: AppBar(title: Text(classroom.name)),
      body: RemoteContent<ClassReport>(
        load: () => api.report(classroom.id),
        builder: (context, report, refresh) => ScrollPage(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 3,
                child: Image.asset(
                  'assets/images/turma_ilustracao.jpg',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            SectionHeader(
              title: 'Desempenho em ${report.classroom.subject}',
              subtitle: _summary(report),
              action: IconButton(
                tooltip: 'Atualizar relatório',
                icon: const Icon(Icons.refresh),
                onPressed: refresh,
              ),
            ),
            _classCodeCard(report.classroom, refresh),
            QuartilePanel(
              report: report,
              onStudent: (student) => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentDetailScreen(
                    classroom: classroom,
                    studentId: student.id,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
