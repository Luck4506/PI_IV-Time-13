import 'package:flutter_test/flutter_test.dart';

import 'node_bridge_test_support.dart';

Future<String> _registrar(ApiTeste api, Json corpo) async {
  final resposta =
      await api.chamar('/api/auth/cadastro', metodo: 'POST', corpo: corpo);
  expect(resposta['status'], 201);
  return resposta['dados']['token'] as String;
}

void main() {
  test('Professor cria turma e aluno entra e sai', () async {
    final api = await ApiTeste.iniciar(modo: 'turmas');
    final professor = await _registrar(
        api,
        {
          ...cadastroBase,
          'perfil': 'teacher',
          'email': 'prof@example.com',
          'cadastroEducacional': true,
          'codigoEscola': 'ESCOLA-ATIVA',
          'codProfessor': '1234',
        }..remove('anoEscolar'));
    final aluno = await _registrar(api, {
      ...cadastroBase,
      'cadastroEducacional': true,
      'codigoEscola': 'ESCOLA-ATIVA',
    });

    Future<Json> criarTurma() => api.chamar(
          '/api/professor/turmas',
          metodo: 'POST',
          token: professor,
          corpo: {'nome': '3º B'},
        );
    expect((await criarTurma())['status'], 409);
    final disciplina = await api.chamar(
      '/api/professor/disciplina',
      metodo: 'PUT',
      token: professor,
      corpo: {'disciplina': 'Matemática'},
    );
    expect(disciplina['dados'], {'disciplina': 'Matemática'});
    final criada = await criarTurma();
    expect(criada['status'], 201);
    final turma = criada['dados']['turma'] as Json;
    expect(turma['codigo'], matches(r'^[A-F0-9]{12}$'));

    const caminho = '/api/aluno/turma';
    final entrou = await api.chamar(caminho,
        metodo: 'POST', token: aluno, corpo: {'codigo': turma['codigo']});
    expect(entrou['status'], 200);
    expect((await api.chamar(caminho, token: aluno))['dados']['turma']['nome'],
        '3º B');
    final saiu = await api.chamar("$caminho/${turma['id']}",
        metodo: 'DELETE', token: aluno);
    expect(saiu['status'], 204);
    expect((await api.chamar(caminho, token: aluno))['dados']['turma'], isNull);
  }, skip: motivoParaPularPonteNode());

  suiteNode('e2e-professor-aluno.test.js');
}

