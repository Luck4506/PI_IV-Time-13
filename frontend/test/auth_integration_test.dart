// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trilha/src/app.dart';
import 'package:trilha/src/services/api_service.dart';
import 'package:trilha/src/services/tcp_client.dart';
import 'package:trilha/src/graph_quiz_screen.dart';

void main() {
  testWidgets('conta pendente pode pedir outro código e confirmar no app', (
    tester,
  ) async {
    Map<String, dynamic>? resendBody;
    Map<String, dynamic>? confirmBody;
    ApiService.instance = ApiService(
      send: (request) async {
        if (Uri.parse(request.path).path.endsWith('/reenviar-confirmacao')) {
          resendBody = request.data;
          return TcpResponse(<String, dynamic>{}, 202);
        }
        if (request.path.endsWith('/confirmar-email')) {
          confirmBody = request.data;
          return TcpResponse(<String, dynamic>{}, 200);
        }
        if (Uri.parse(request.path).path.endsWith('/login')) {
          return TcpResponse({
            'codigo': 'EMAIL_NAO_CONFIRMADO',
            'erro': 'Confirme seu e-mail para entrar.',
          }, 403);
        }
        return TcpResponse(<String, dynamic>{}, 401);
      },
    );

    await tester.pumpWidget(const TrilhaApp());
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'teste@example.com');
    await tester.enterText(fields.at(1), 'SenhaTeste123!');
    final loginButton = find.byKey(const Key('login-button'));
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Confirme seu e-mail'), findsOneWidget);
    expect(ApiService.instance.user, isNull);
    await tester.enterText(fields.at(1), 'SenhaTeste123!');
    await tester.ensureVisible(find.text('Reenviar código'));
    await tester.tap(find.text('Reenviar código'));
    await tester.pumpAndSettle();
    expect(resendBody, {
      'email': 'teste@example.com',
      'senha': 'SenhaTeste123!',
    });
    expect(find.textContaining('Aguarde um minuto'), findsOneWidget);

    final code = 'A' * 43;
    await tester.enterText(fields.at(0), code);
    await tester.ensureVisible(find.text('Confirmar e-mail'));
    await tester.tap(find.text('Confirmar e-mail'));
    await tester.pumpAndSettle();
    expect(confirmBody, {'codigo': code, 'senha': 'SenhaTeste123!'});
    expect(find.text('teste@example.com'), findsOneWidget);
  });

  testWidgets('cadastro aguarda e-mail antes de iniciar a sessão', (
    tester,
  ) async {
    ApiService.instance = ApiService(
      send: (request) async {
        if (Uri.parse(request.path).path.endsWith('/cadastro')) {
          expect(request.data?['dataNascimento'], '2009-08-15');
          return TcpResponse({
            'verificacaoPendente': true,
            'emailEnviado': true,
          }, 201);
        }
        if (Uri.parse(request.path).path.endsWith('/escolas')) {
          return TcpResponse({'erro': 'Escolas indisponíveis.'}, 503);
        }
        return TcpResponse(<String, dynamic>{}, 401);
      },
    );
    tester.view.physicalSize = const Size(600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TrilhaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ainda não tenho uma conta'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Estudante Teste');
    await tester.enterText(fields.at(1), 'teste@example.com');
    await tester.enterText(fields.at(2), '2009-08-15');
    await tester.enterText(fields.at(3), 'SenhaTeste123!');
    await tester.tap(find.byKey(const Key('school-year-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3º ano do Ensino Médio').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuar e personalizar'));
    await tester.tap(find.text('Continuar e personalizar'));
    await tester.pumpAndSettle();

    expect(find.text('Confirme seu e-mail'), findsOneWidget);
    expect(ApiService.instance.user, isNull);
  });

  testWidgets(
    'login rejeitado permanece no formulário e mostra erro do servidor',
    (tester) async {
      ApiService.instance = ApiService(
        send: (_) async =>
            TcpResponse({'erro': 'E-mail, senha ou perfil incorretos.'}, 401),
      );
      await tester.pumpWidget(const TrilhaApp());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'teste@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'SenhaIncorreta123',
      );
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('E-mail, senha ou perfil incorretos.'), findsOneWidget);
      expect(find.text('Que bom ver você de volta!'), findsOneWidget);
      expect(ApiService.instance.user, isNull);
    },
  );

  testWidgets('cadastro envia dados e só avança após confirmação da API', (
    tester,
  ) async {
    Map<String, dynamic>? received;
    ApiService.instance = ApiService(
      send: (request) async {
        if (Uri.parse(request.path).path == '/api/usuarios/me') {
          return TcpResponse({'erro': 'Entre na sua conta.'}, 401);
        }
        if (Uri.parse(request.path).path == '/api/escolas') {
          return TcpResponse({
            'escolas': [
              {'codigo': 'ESCOLA-HORIZONTE', 'nome': 'Escola Horizonte'},
              {
                'codigo': 'ESCOLA-INTERNA',
                'nome': 'Escola de Demonstração',
                'demonstracao': true,
              },
            ],
          }, 200);
        }
        expect(Uri.parse(request.path).path, '/api/auth/cadastro');
        received = request.data;
        return TcpResponse({
          'token': 'test-token',
          'usuario': {
            'id': '1',
            'nome': received!['nome'],
            'email': received!['email'],
            'perfil': received!['perfil'],
            'anoEscolar': received!['anoEscolar'],
          },
        }, 201);
      },
    );
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TrilhaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ainda não tenho uma conta'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    for (final entry in [
      'Teste Integrado',
      'teste@example.com',
      '2009-08-15',
      'SenhaTeste123!',
    ].asMap().entries) {
      await tester.enterText(fields.at(entry.key), entry.value);
    }
    await tester.tap(find.byKey(const Key('school-year-select')));
    await tester.pumpAndSettle();
    expect(find.text('6º ano do Ensino Fundamental'), findsNothing);
    expect(find.text('Outro'), findsWidgets);
    await tester.tap(find.text('1º ano do Ensino Médio').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('educational-registration')),
    );
    await tester.tap(find.byKey(const Key('educational-registration')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Escola'));
    await tester.tap(find.text('Escola'));
    await tester.pumpAndSettle();
    expect(find.text('Escola de Demonstração'), findsNothing);
    await tester.tap(find.text('Escola Horizonte').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('class-code-register')),
      'AB12CD34EF56',
    );
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuar e personalizar'));
    await tester.tap(find.text('Continuar e personalizar'));
    await tester.pumpAndSettle();
    expect(received!['termosAceitos'], true);
    expect(received!['anoEscolar'], '1º ano do Ensino Médio');
    expect(received!['dataNascimento'], '2009-08-15');
    expect(received!['cadastroEducacional'], true);
    expect(received!['codigoEscola'], 'ESCOLA-HORIZONTE');
    expect(received!['codigoTurma'], 'AB12CD34EF56');
    expect(
      find.text('Vamos descobrir o melhor ponto de partida?'),
      findsOneWidget,
    );
    expect(ApiService.instance.user?.name, 'Teste Integrado');
  });

  testWidgets(
    'atividade retoma trilha e salva resposta antes de mostrar resultado',
    (tester) async {
      var saved = false;
      final item = {
        'questaoId': 'REAL-01',
        'nome': 'Questão real',
        'disciplina': 'Física',
        'motivo': {'descricao': 'Reforço de tema'},
        'questao': {
          'id': 'REAL-01',
          'questao': 'Questão recebida da API',
          'alternativaA': 'Alternativa da API',
          'banca': 'ENEM',
          'ano': 2024,
          'numero': 137,
          'caderno': '2º dia · Caderno 7 azul',
          'paginaProva': 16,
          'provaUrl': 'https://example.test/caderno.pdf',
        },
      };
      Map<String, dynamic> trail() => {
        'id': 'TRILHA-1',
        'modo': 'normal',
        'tipo': 'pratica',
        'status': saved ? 'concluida' : 'em_andamento',
        'acertos': saved ? 1 : 0,
        'erros': 0,
        'total': 1,
        'respondidas': saved ? 1 : 0,
        'itens': [item],
      };
      ApiService.instance = ApiService(
        send: (request) async {
          if (request.method == 'GET') {
            return TcpResponse({'trilha': trail()}, 200);
          }
          expect(
            Uri.parse(request.path).path,
            '/api/trilhas/TRILHA-1/respostas',
          );
          expect(request.data?['alternativa'], 'A');
          saved = true;
          return TcpResponse({
            'trilha': trail(),
            'resposta': {'correta': true, 'gabarito': 'A'},
            'proximaTrilha': {
              'id': 'TRILHA-2',
              'tipo': 'exploracao',
              'etapas': [
                {
                  'nome': 'Novo assunto',
                  'disciplina': 'Física',
                  'motivo': {'descricao': 'Assunto sorteado'},
                },
              ],
            },
          }, 200);
        },
      );
      Object? openedTrailArguments;
      await tester.pumpWidget(
        MaterialApp(
          home: const GraphQuizScreen(),
          onGenerateRoute: (settings) {
            openedTrailArguments = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Trilha aberta')),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Questão recebida da API'), findsOneWidget);
      expect(find.textContaining('ENEM 2024 · Questão 137'), findsOneWidget);
      expect(find.text('Abrir questão no caderno'), findsNothing);
      await tester.tap(find.text('A. Alternativa da API'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar resposta'));
      await tester.pumpAndSettle();
      expect(saved, true);
      expect(find.text('Resposta salva.'), findsOneWidget);
      await tester.tap(find.text('Ver resultado e trilha'));
      await tester.pumpAndSettle();
      expect(
        find.text('Você acertou todas! Vamos explorar novos assuntos.'),
        findsOneWidget,
      );
      expect(find.text('Novo assunto'), findsOneWidget);
      await tester.tap(find.text('Abrir minha trilha'));
      await tester.pumpAndSettle();
      expect(openedTrailArguments, 'TRILHA-2');
    },
  );
}
