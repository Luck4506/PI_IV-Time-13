import 'package:test/test.dart';

import 'api_test_support.dart';

void main() {
  final campos = <String, List<(Object?, int)>>{
    'nome': [
      ('', 400),
      ('A', 400),
      ('Al', 201),
      ('Ana', 201),
      ('Maria da Silva', 201),
      ('a' * 119, 201),
      ('a' * 120, 201),
      ('a' * 121, 400),
      ('     ', 400),
      (' A ', 400),
    ],
    'senha': [
      ('', 400),
      ('1234567', 400),
      ('12345678', 201),
      ('123456789', 201),
      ('x' * 127, 201),
      ('x' * 128, 201),
      ('x' * 129, 400),
      (12345678, 400),
    ],
    'email': [
      ('a@b.co', 201),
      ('  USER@Example.COM ', 201),
      ('usuario.example.com', 400),
      ('usuario@', 400),
      ('@example.com', 400),
      ('a@b.c', 400),
      ('', 400),
    ],
    'dataNascimento': [
      ('2008-02-29', 201),
      ('2007-02-29', 400),
      ('2000-01-01', 201),
      ('2008-13-01', 400),
      ('2008-00-10', 400),
      ('2008-04-31', 400),
      ('08/02/2008', 400),
      ('abc', 400),
      ('', 400),
    ],
    'termosAceitos': [
      (true, 201),
      (false, 400),
      ('true', 400),
      (1, 400),
      (null, 400)
    ],
  };

  for (final campo in campos.entries) {
    group(campo.key, () {
      for (final (indice, caso) in campo.value.indexed) {
        final (valor, esperado) = caso;
        test('caso ${indice + 1} espera $esperado', () async {
          final api = await ApiTeste.iniciar();
          final resposta = await api.chamar(
            '/api/auth/cadastro',
            metodo: 'POST',
            corpo: {...cadastroBase, campo.key: valor},
          );
          expect(resposta['status'], esperado, reason: 'Valor: $valor');
          if (esperado == 400 && ['nome', 'senha'].contains(campo.key)) {
            final erros = resposta['dados']['campos'] as List;
            expect(erros.map((erro) => erro['campo']), contains(campo.key));
          }
        });
      }
    });
  }

  suiteNode('caixa-preta-cadastro.test.js');
}
