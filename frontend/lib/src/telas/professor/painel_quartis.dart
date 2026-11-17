import 'package:flutter/material.dart';

import '../../services/classroom_api.dart';
import '../../theme.dart';
import '../../widgets.dart';

class QuartilePanel extends StatefulWidget {
  const QuartilePanel({
    super.key,
    required this.report,
    required this.onStudent,
  });

  final ClassReport report;
  final ValueChanged<StudentScore> onStudent;

  @override
  State<QuartilePanel> createState() => _QuartilePanelState();
}

class _QuartilePanelState extends State<QuartilePanel> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normalize(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final onStudent = widget.onStudent;
    final query = _search.text.trim();
    final searching = query.isNotEmpty;
    final terms = _normalize(query).split(RegExp(r'\s+'));

    List<StudentScore> matching(List<StudentScore> students) {
      if (!searching) return students;
      return students.where((student) {
        final name = _normalize(student.score.name);
        return terms.every(name.contains);
      }).toList();
    }

    final quartiles = [...report.quartiles]
      ..sort((first, second) => first.number.compareTo(second.number));
    final hasQuartiles = quartiles.any(
      (quartile) => quartile.students.isNotEmpty,
    );
    final visibleByQuartile = {
      for (final group in quartiles) group.number: matching(group.students),
    };
    final insufficientSample = matching(report.insufficientSample);
    final belowMinimum = matching(report.belowMinimum);
    final withoutAnswers = matching(report.withoutAnswers);
    final noMatches =
        searching &&
        visibleByQuartile.values.every((students) => students.isEmpty) &&
        insufficientSample.isEmpty &&
        belowMinimum.isEmpty &&
        withoutAnswers.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SectionHeader(
          title: 'Quartis da turma',
          subtitle:
              'Cada aluno precisa responder ${report.minimumQuestions} questões diferentes nesta matéria. '
              'O relatório divide a turma em quartis quando pelo menos ${report.minimumStudents} alunos atingem esse mínimo.',
        ),
        if (report.totalStudents > 0)
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Buscar aluno por nome',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_search.clear),
                    ),
            ),
          ),
        if (noMatches)
          const SurfaceCard(child: Text('Nenhum aluno encontrado.'))
        else if (hasQuartiles)
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final width = constraints.maxWidth;
              // No celular, cada grupo ocupa a largura inteira para os nomes caberem.
              final cardWidth = width < 560 ? width : (width - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final quartile in quartiles)
                    SizedBox(
                      width: cardWidth,
                      child: _QuartileCard(
                        key: ValueKey('quartil-${quartile.number}'),
                        quartile: quartile,
                        students: visibleByQuartile[quartile.number]!,
                        searching: searching,
                        onStudent: onStudent,
                      ),
                    ),
                ],
              );
            },
          )
        else if (report.totalStudents == 0)
          const SurfaceCard(child: Text('Ainda não há alunos nesta turma.')),
        if (insufficientSample.isNotEmpty)
          _PendingStudentGroup(
            key: ValueKey('amostra-$searching'),
            title: 'Amostra insuficiente',
            description:
                'Atingiram o mínimo individual e aguardam outros alunos.',
            color: AppColors.primary,
            students: insufficientSample,
            expanded: searching,
            onStudent: onStudent,
          ),
        if (belowMinimum.isNotEmpty)
          _PendingStudentGroup(
            key: ValueKey('minimo-$searching'),
            title: 'Abaixo do mínimo de questões',
            color: AppColors.amber,
            students: belowMinimum,
            expanded: searching,
            onStudent: onStudent,
            minimumQuestions: report.minimumQuestions,
          ),
        if (withoutAnswers.isNotEmpty)
          _PendingStudentGroup(
            key: ValueKey('sem-respostas-$searching'),
            title: 'Sem respostas na disciplina',
            color: AppColors.muted,
            students: withoutAnswers,
            expanded: searching,
            onStudent: onStudent,
          ),
      ],
    );
  }
}

class _QuartileCard extends StatelessWidget {
  const _QuartileCard({
    super.key,
    required this.quartile,
    required this.students,
    required this.searching,
    required this.onStudent,
  });

  final Quartile quartile;
  final List<StudentScore> students;
  final bool searching;
  final ValueChanged<StudentScore> onStudent;

  Color get _color => switch (quartile.number) {
    1 => const Color(0xFFBD432D),
    2 => const Color(0xFF946200),
    3 => AppColors.primary,
    4 => const Color(0xFF08765F),
    _ => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = _color;
    final total = _studentCount(quartile.students.length);
    final count = searching ? '${students.length} de $total' : total;

    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  quartile.label,
                  style: text.titleMedium?.copyWith(color: color),
                ),
                Text(count, style: text.bodySmall),
              ],
            ),
          ),
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                searching
                    ? 'Nenhum resultado neste quartil.'
                    : 'Nenhum aluno neste quartil.',
              ),
            )
          else
            for (final student in students)
              _QuartileStudent(
                student: student,
                color: color,
                onTap: () => onStudent(student),
              ),
        ],
      ),
    );
  }
}

class _QuartileStudent extends StatelessWidget {
  const _QuartileStudent({
    required this.student,
    required this.color,
    required this.onTap,
  });

  final StudentScore student;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final percent = student.score.percent;

    // O servidor já calculou o quartil. A barra mostra apenas os acertos do aluno.
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(student.score.name, style: text.titleMedium),
      subtitle: percent == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: percent.clamp(0, 100) / 100,
                  color: color,
                  backgroundColor: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(6),
                  minHeight: 6,
                ),
              ),
            ),
      trailing: Text(student.score.label, style: text.titleMedium),
      onTap: onTap,
    );
  }
}

class _PendingStudentGroup extends StatelessWidget {
  const _PendingStudentGroup({
    super.key,
    required this.title,
    required this.color,
    required this.students,
    required this.expanded,
    required this.onStudent,
    this.description,
    this.minimumQuestions,
  });

  final String title;
  final Color color;
  final List<StudentScore> students;
  final bool expanded;
  final ValueChanged<StudentScore> onStudent;
  final String? description;
  final int? minimumQuestions;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: expanded,
        leading: Icon(Icons.circle, color: color, size: 16),
        title: Text(title),
        subtitle: Text(description ?? _studentCount(students.length)),
        children: [
          for (final student in students)
            ListTile(
              title: Text(student.score.name),
              subtitle: Text(
                minimumQuestions == null
                    ? '${student.score.answers} respostas'
                    : '${student.distinctQuestions} de $minimumQuestions questões diferentes',
              ),
              trailing: Text(student.score.label),
              onTap: () => onStudent(student),
            ),
        ],
      ),
    );
  }
}

String _studentCount(int count) => count == 1 ? '1 aluno' : '$count alunos';
