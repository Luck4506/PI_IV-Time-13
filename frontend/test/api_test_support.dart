// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trilha/src/services/api_service.dart';
import 'package:trilha/src/services/tcp_client.dart';

void configureTestApi() {
  ApiService.instance = ApiService(send: createTestTransport());
}

Future<TcpResponse> Function(TcpRequest) createTestTransport() {
  var noticesRead = false;
  return (request) async {
    if (Uri.parse(request.path).path == '/api/usuarios/me') {
      return TcpResponse({'erro': 'Entre na sua conta para continuar.'}, 401);
    }
    final path = Uri.parse(request.path).path;
    if (path == '/api/aluno/notificacoes/lidas') {
      noticesRead = true;
      return TcpResponse(<String, dynamic>{}, 204);
    }
    if (request.method == 'GET') {
      return TcpResponse(switch (path) {
        '/api/aluno/atividade' => _activity,
        '/api/aluno/turma' => {'turma': null},
        '/api/aluno/notificacoes' => {
          'notificacoes': [
            {
              'titulo': 'Nova conquista: Primeiro passo',
              'data': '2026-11-10T10:00:00Z',
              'lida': noticesRead,
            },
          ],
        },
        '/api/professor/turmas' => {
          'turmas': [_classA, _classB],
          'disciplina': 'Matemática',
        },
        '/api/professor/turmas/a' => _report(_classA),
        '/api/professor/turmas/b' => _report(_classB),
        '/api/professor/turmas/a/alunos/student' ||
        '/api/professor/turmas/b/alunos/student' => {
          'disciplina': 'Matemática',
          'aluno': {
            ..._score,
            'topicos': [_topic],
          },
        },
        _ => path.endsWith('/atual') ? {'trilha': null} : {'trilhas': []},
      }, 200);
    }
    if (Uri.parse(request.path).path == '/api/auth/logout') {
      return TcpResponse(<String, dynamic>{}, 204);
    }
    final data = request.data!;
    final isLogin = request.path == '/api/auth/login';
    final teacher = isLogin
        ? data['email'] == 'professor@example.test'
        : data['perfil'] == 'teacher';
    return TcpResponse({
      'token': 'test-session',
      'usuario': {
        'id': 'test-user',
        'nome': data['nome'] ?? (teacher ? 'Ana Ribeiro' : 'Marina Costa'),
        'email': data['email'],
        'perfil': teacher ? 'teacher' : 'student',
        if (!teacher) 'anoEscolar': data['anoEscolar'] ?? '3º ano',
        if (teacher) 'codigoEscola': 'ESCOLA-DEMO-001',
      },
    }, 200);
  };
}

Future<void> fillTestLogin(
  WidgetTester tester, {
  String email = 'teste@example.com',
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), 'SenhaTeste123!');
}

const _topic = {
  'nome': 'Porcentagens',
  'respondidas': 4,
  'acertos': 1,
  'aproveitamento': 25,
};
const _score = {
  'id': 'student',
  'nome': 'João Souza',
  'respondidas': 5,
  'questoesDistintas': 5,
  'acertos': 1,
  'aproveitamento': 20,
};
const _classA = {
  'id': 'a',
  'nome': '3º A',
  'disciplina': 'Matemática',
  'codigo': 'ABCDEF012345',
  'podeConvidarProfessor': true,
};
final _classB = {..._classA, 'id': 'b', 'nome': '3º B'};

Map<String, dynamic> _report(Map<String, dynamic> classroom) => {
  'turma': classroom,
  'totalAlunos': 4,
  'respondidas': 20,
  'acertos': 12,
  'aproveitamento': 60,
  'minimoQuestoesPorAluno': 5,
  'minimoAlunosParaQuartis': 4,
  'quartis': [
    {
      'numero': 1,
      'nome': 'Q1 · Menor desempenho',
      'alunos': [_score],
    },
    {'numero': 2, 'nome': 'Q2 · Faixa intermediária inferior', 'alunos': []},
    {'numero': 3, 'nome': 'Q3 · Faixa intermediária superior', 'alunos': []},
    {'numero': 4, 'nome': 'Q4 · Maior desempenho', 'alunos': []},
  ],
  'semRespostas': [],
  'amostraInsuficiente': [],
};

const _activity = {
  'xp': 25,
  'sequencia': 1,
  'respondidas': 4,
  'acertos': 1,
  'trilhas': 0,
  'porDisciplina': [
    {
      'nome': 'Matemática',
      'respondidas': 4,
      'acertos': 1,
      'aproveitamento': 25,
      'topicos': [_topic],
    },
  ],
  'conquistas': [
    {
      'id': 'primeiro-passo',
      'nome': 'Primeiro passo',
      'descricao': 'Responda uma questão.',
      'meta': 1,
      'progresso': 1,
      'conquistadaEm': '2026-11-10T10:00:00Z',
    },
  ],
};
