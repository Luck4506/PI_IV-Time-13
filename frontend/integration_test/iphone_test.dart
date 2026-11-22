// Autoria de Lucas Soares Gonçalves RA 25009467
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trilha/main.dart';
import 'package:trilha/src/services/api_service.dart';
import 'package:trilha/src/services/tcp_client.dart';

import '../test/api_test_support.dart';
import 'apoio_ios.dart';

const email = 'conta@example.test';
const password = 'SenhaTeste123!';
const isolatedNodePort = int.fromEnvironment('API_TCP_PORT');
const isolatedJavaPort = int.fromEnvironment('JAVA_TCP_PORT');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ServerSocket server;
  late List<TcpRequest> requests;

  setUp(() async {
    expect(
      Platform.isIOS,
      isTrue,
      reason: 'Execute em um iPhone ou simulador iOS.',
    );
    final respond = createTestTransport();
    requests = [];
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);

    // O app percorre o transporte real. O servidor de teste roda no próprio
    // dispositivo e responde com dados em memória.
    server.listen((socket) async {
      try {
        final line = await const Utf8Decoder()
            .bind(socket)
            .transform(const LineSplitter())
            .first;
        final data = jsonDecode(line) as Map<String, dynamic>;
        final request = TcpRequest(
          data['metodo'] as String,
          data['caminho'] as String,
          data: data['dados'] as Map<String, dynamic>?,
          token: data['token'] as String?,
        );
        requests.add(request);

        final response = await respond(request);
        final payload = jsonEncode({
          'status': response.status,
          'corpo': response.body,
        });
        socket.add(utf8.encode('$payload\n'));
        await socket.flush();
      } finally {
        socket.destroy();
      }
    });

    final client = TcpClient(server.address.address, server.port);
    ApiService.instance = ApiService(send: client.send);
  });

  tearDown(() async {
    await server.close();
  });

  testWidgets('iPhone exibe a marca e navega com uma conta de estudante', (
    tester,
  ) async {
    await tester.pumpWidget(const TrilhaApp());
    await waitFor(tester, find.text('Gabariteii'));
    expect(
      find.image(const AssetImage('assets/images/gabariteii_logo.png')),
      findsOneWidget,
    );

    await signIn(tester, email, password);
    await waitFor(tester, find.text('Olá, Marina!'));
    await tap(tester, find.byTooltip('Notificações'));
    await waitFor(tester, find.textContaining('Nova conquista'));
    await tap(tester, find.text('Marcar como lidas'));
    await tap(tester, find.byType(BackButton));

    await tap(tester, find.text('Trilha'));
    await waitFor(tester, find.text('Começar diagnóstico'));
    await tap(tester, find.text('Perfil'));
    await tap(tester, find.text('Sair'));
    await waitFor(tester, find.text('Que bom ver você de volta!'));

    final login = requests.singleWhere(
      (request) => request.path == '/api/auth/login',
    );
    expect(login.method, 'POST');
    expect(login.data?['perfil'], 'student');
    final logout = requests.singleWhere(
      (request) => request.path == '/api/auth/logout',
    );
    expect(logout.token, 'test-session');
    expect(tester.takeException(), isNull);
  });

  testWidgets('iPhone abre a turma e encontra o aluno no quartil pelo nome', (
    tester,
  ) async {
    await tester.pumpWidget(const TrilhaApp());
    await tap(tester, find.text('Professor'));
    await signIn(tester, email, password);
    await tap(tester, find.text('Turmas'));
    await tap(tester, find.text('3º A'));

    final search = find.widgetWithText(TextField, 'Buscar aluno por nome');
    await reveal(tester, search);
    await tester.enterText(search, 'joao souza');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Q1 · Menor desempenho'), findsOneWidget);
    await tap(tester, find.text('João Souza'));
    await waitFor(tester, find.text('Detalhes do aluno'));
    expect(find.text('Porcentagens'), findsOneWidget);
    expect(
      requests.any(
        (request) => request.path == '/api/professor/turmas/a/alunos/student',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  if (isolatedNodePort > 0 && isolatedJavaPort > 0) {
    testWidgets(
      'iPhone cadastra pelo Java simulado e autentica pelo Node isolado',
      (tester) async {
        const client = TcpClient('127.0.0.1', isolatedNodePort);

        // Confirme o ambiente isolado antes de criar uma conta.
        final health = await client.send(const TcpRequest('GET', '/health/qa'));
        expect(health.status, 200);
        expect(health.body, {'modo': 'memoria', 'validador': 'simulado'});

        final api = ApiService();
        final registration = await api.register(
          name: 'João de Ávila',
          email: email,
          password: password,
          role: 'student',
          schoolField: 'Outro',
          birthDate: '2009-08-15',
        );
        expect(registration.user?.name, 'João de Ávila');
        expect(registration.user?.schoolYear, 'Outro');

        await api.logout();
        expect(api.user, isNull);
        final loggedIn = await api.login(
          email: email,
          password: password,
          role: 'student',
        );
        expect(loggedIn.id, registration.user?.id);
        await api.restoreSession();
        expect(api.user?.name, 'João de Ávila');
        await api.logout();
        expect(api.user, isNull);
      },
    );
  }
}
