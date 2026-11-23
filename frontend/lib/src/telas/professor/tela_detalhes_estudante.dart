// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';

import '../../remote_content.dart';
import '../../services/classroom_api.dart';
import '../../widgets.dart';

class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({
    super.key,
    required this.classroom,
    required this.studentId,
  });

  final Classroom classroom;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final api = ClassroomApi();
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do aluno')),
      body: RemoteContent<StudentScore>(
        load: () => api.student(classroom.id, studentId),
        builder: (context, student, _) => ScrollPage(
          children: [
            SectionHeader(
              title: student.score.name,
              subtitle: '${classroom.name} · ${classroom.subject}',
            ),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    student.score.label,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '${student.score.correct} acertos em ${student.score.answers} respostas',
                  ),
                  if (student.lastAnswer case final date?)
                    Text(
                      'Última resposta: ${MaterialLocalizations.of(context).formatCompactDate(date.toLocal())}',
                    ),
                ],
              ),
            ),
            const SectionHeader(title: 'Resultados por conteúdo'),
            if (student.topics.isEmpty)
              const SurfaceCard(
                child: Text('Ainda não há respostas nesta disciplina.'),
              ),
            for (final topic in student.topics)
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  title: Text(topic.name),
                  subtitle: Text(
                    '${topic.correct} de ${topic.answers} acertos',
                  ),
                  trailing: Text(topic.label),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
