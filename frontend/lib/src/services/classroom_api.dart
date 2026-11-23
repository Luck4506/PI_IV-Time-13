// Autoria de Lucas Soares Gonçalves RA 25009467
import 'api_service.dart';

class Classroom {
  const Classroom({
    required this.id,
    required this.name,
    required this.code,
    required this.subject,
    required this.canInviteTeachers,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) => Classroom(
    id: json['id'] as String,
    name: json['nome'] as String,
    code: json['codigo'] as String,
    subject: json['disciplina'] as String,
    canInviteTeachers: json['podeConvidarProfessor'] == true,
  );

  final String id;
  final String name;
  final String code;
  final String subject;
  final bool canInviteTeachers;
}

class Enrollment {
  const Enrollment(this.id, this.name, this.subjects);

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
    json['id'] as String,
    json['nome'] as String,
    (json['disciplinas'] as List).cast<String>(),
  );

  final String id;
  final String name;
  final List<String> subjects;
}

class TeacherClasses {
  const TeacherClasses(this.subject, this.classes);

  final String? subject;
  final List<Classroom> classes;
}

class Score {
  const Score({
    required this.name,
    required this.answers,
    required this.correct,
    required this.percent,
  });

  factory Score.fromJson(Map<String, dynamic> json) => Score(
    name: json['nome'] as String? ?? '',
    answers: json['respondidas'] as int? ?? 0,
    correct: json['acertos'] as int? ?? 0,
    percent: json['aproveitamento'] as int?,
  );

  final String name;
  final int answers;
  final int correct;
  final int? percent;

  String get label => percent == null ? 'Sem respostas' : '$percent%';
}

class StudentScore {
  const StudentScore(
    this.id,
    this.score,
    this.distinctQuestions,
    this.lastAnswer,
    this.topics,
  );

  factory StudentScore.fromJson(Map<String, dynamic> json) {
    final score = Score.fromJson(json);
    final lastAnswer = json['ultimaRespostaEm'] as String?;

    return StudentScore(
      json['id'] as String,
      score,
      json['questoesDistintas'] as int? ?? score.answers,
      lastAnswer == null ? null : DateTime.tryParse(lastAnswer),
      readRows(json, 'topicos', Score.fromJson),
    );
  }

  final String id;
  final Score score;
  final int distinctQuestions;
  final DateTime? lastAnswer;
  final List<Score> topics;
}

class Quartile {
  const Quartile(this.number, this.label, this.students);

  factory Quartile.fromJson(Map<String, dynamic> json) => Quartile(
    json['numero'] as int,
    json['nome'] as String,
    readRows(json, 'alunos', StudentScore.fromJson),
  );

  final int number;
  final String label;
  final List<StudentScore> students;
}

class ClassReport {
  const ClassReport({
    required this.classroom,
    required this.totalStudents,
    required this.score,
    required this.quartiles,
    required this.withoutAnswers,
    required this.belowMinimum,
    required this.insufficientSample,
    required this.minimumQuestions,
    required this.minimumStudents,
  });

  factory ClassReport.fromJson(Map<String, dynamic> json) => ClassReport(
    classroom: Classroom.fromJson(json['turma'] as Map<String, dynamic>),
    totalStudents: json['totalAlunos'] as int,
    score: Score.fromJson(json),
    quartiles: readRows(json, 'quartis', Quartile.fromJson),
    withoutAnswers: readRows(json, 'semRespostas', StudentScore.fromJson),
    belowMinimum: readRows(json, 'abaixoDoMinimo', StudentScore.fromJson),
    minimumQuestions: json['minimoQuestoesPorAluno'] as int? ?? 1,
    minimumStudents: json['minimoAlunosParaQuartis'] as int? ?? 4,
    insufficientSample: readRows(
      json,
      'amostraInsuficiente',
      StudentScore.fromJson,
    ),
  );

  final Classroom classroom;
  final int totalStudents;
  final Score score;
  final List<Quartile> quartiles;
  final List<StudentScore> withoutAnswers;
  final List<StudentScore> belowMinimum;
  final List<StudentScore> insufficientSample;
  final int minimumQuestions;
  final int minimumStudents;
}

List<T> readRows<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) convert,
) => ((json[key] as List?) ?? [])
    .cast<Map<String, dynamic>>()
    .map(convert)
    .toList();

class ClassroomApi {
  final ApiService api = ApiService.instance;

  Future<TeacherClasses> teacherClasses() async {
    final data = await api.request('GET', '/api/professor/turmas');
    return TeacherClasses(
      data['disciplina'] as String?,
      readRows(data, 'turmas', Classroom.fromJson),
    );
  }

  Future<List<String>> subjects() async {
    final data = await api.request('GET', '/api/disciplinas');
    return readRows(
      data,
      'disciplinas',
      (row) => row['nome'] as String,
    ).toSet().toList();
  }

  Future<void> chooseSubject(String name) async {
    await api.request('PUT', '/api/professor/disciplina', {'disciplina': name});
  }

  Future<void> createClass(String name) async {
    await api.request('POST', '/api/professor/turmas', {'nome': name});
  }

  Future<void> joinAsTeacher(String code) async {
    await api.request('POST', '/api/professor/turmas/entrar', {'codigo': code});
  }

  Future<ClassReport> report(String id) async {
    final data = await api.request('GET', _classPath(id));
    return ClassReport.fromJson(data);
  }

  Future<StudentScore> student(String classId, String id) async {
    final data = await api.request(
      'GET',
      '${_classPath(classId)}/alunos/${Uri.encodeComponent(id)}',
    );
    return StudentScore.fromJson(data['aluno'] as Map<String, dynamic>);
  }

  Future<String> inviteTeacher(String classId) async {
    final data = await api.request('POST', '${_classPath(classId)}/convite');
    return data['codigo'] as String;
  }

  Future<void> rotateStudentCode(String classId) async {
    await api.request('POST', '${_classPath(classId)}/codigo');
  }

  Future<Enrollment?> myClass() async {
    final data = await api.request('GET', '/api/aluno/turma');
    final row = data['turma'] as Map<String, dynamic>?;
    return row == null ? null : Enrollment.fromJson(row);
  }

  Future<void> joinAsStudent(String code) async {
    await api.request('POST', '/api/aluno/turma', {'codigo': code});
  }

  Future<void> leaveClass(String id) async {
    await api.request('DELETE', '/api/aluno/turma/${Uri.encodeComponent(id)}');
  }

  String _classPath(String id) =>
      '/api/professor/turmas/${Uri.encodeComponent(id)}';
}
