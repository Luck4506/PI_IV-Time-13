// Autoria de Lucas Soares Gonçalves RA 25009467
import 'api_service.dart';
import 'classroom_api.dart';

class StudyActivity {
  const StudyActivity({
    required this.xp,
    required this.streak,
    required this.answered,
    required this.correct,
    required this.trails,
    required this.medals,
    required this.subjects,
    required this.week,
  });

  factory StudyActivity.fromJson(Map<String, dynamic> json) => StudyActivity(
    xp: json['xp'] as int? ?? 0,
    streak: json['sequencia'] as int? ?? 0,
    answered: json['respondidas'] as int? ?? 0,
    correct: json['acertos'] as int? ?? 0,
    trails: json['trilhas'] as int? ?? 0,
    medals: readRows(json, 'conquistas', Medal.fromJson),
    subjects: readRows(json, 'porDisciplina', SubjectActivity.fromJson),
    week: readRows(json, 'semana', StudyDay.fromJson),
  );

  final int xp;
  final int streak;
  final int answered;
  final int correct;
  final int trails;
  final List<Medal> medals;
  final List<SubjectActivity> subjects;
  final List<StudyDay> week;

  int get today => week.lastOrNull?.answers ?? 0;
  int get weeklyAnswers => week.fold(0, (total, day) => total + day.answers);
  int get earnedMedals =>
      medals.where((medal) => medal.earnedAt != null).length;
}

class Medal {
  const Medal(
    this.id,
    this.name,
    this.description,
    this.goal,
    this.progress,
    this.earnedAt,
  );

  factory Medal.fromJson(Map<String, dynamic> json) => Medal(
    json['id'] as String,
    json['nome'] as String,
    json['descricao'] as String,
    json['meta'] as int,
    json['progresso'] as int,
    DateTime.tryParse(json['conquistadaEm'] as String? ?? ''),
  );

  final String id;
  final String name;
  final String description;
  final int goal;
  final int progress;
  final DateTime? earnedAt;
}

class SubjectActivity {
  const SubjectActivity(this.score, this.topics);

  factory SubjectActivity.fromJson(Map<String, dynamic> json) =>
      SubjectActivity(
        Score.fromJson(json),
        readRows(json, 'topicos', Score.fromJson),
      );

  final Score score;
  final List<Score> topics;
}

class StudyDay {
  const StudyDay(this.date, this.answers);

  factory StudyDay.fromJson(Map<String, dynamic> json) => StudyDay(
    DateTime.parse(json['data'] as String),
    json['respondidas'] as int,
  );

  final DateTime date;
  final int answers;
}

class StudyNotice {
  const StudyNotice(this.title, this.date, this.read);

  factory StudyNotice.fromJson(Map<String, dynamic> json) => StudyNotice(
    json['titulo'] as String,
    DateTime.parse(json['data'] as String),
    json['lida'] == true,
  );

  final String title;
  final DateTime date;
  final bool read;
}

class ActivityApi {
  final api = ApiService.instance;

  Future<StudyActivity> activity() async {
    final data = await api.request('GET', '/api/aluno/atividade');
    return StudyActivity.fromJson(data);
  }

  Future<List<StudyNotice>> notices() async {
    final data = await api.request('GET', '/api/aluno/notificacoes');
    return readRows(data, 'notificacoes', StudyNotice.fromJson);
  }

  Future<void> markRead() async {
    await api.request('PUT', '/api/aluno/notificacoes/lidas');
  }
}
