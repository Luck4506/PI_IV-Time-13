// Autoria de Lucas Soares Gonçalves RA 25009467
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trilha/src/content_stage_screen.dart';
import 'package:trilha/src/content_trail_map.dart';
import 'package:trilha/src/services/api_service.dart';
import 'package:trilha/src/services/tcp_client.dart';
import 'package:trilha/src/user_trail_view.dart';

void main() {
  testWidgets('caminho alterna os lados e bloqueia etapas futuras', (
    tester,
  ) async {
    String? opened;
    final stages = [
      {'id': 'a', 'nome': 'Queda livre', 'status': 'disponivel'},
      {'id': 'b', 'nome': 'Leis de Newton', 'status': 'bloqueada'},
      {'id': 'c', 'nome': 'Energia', 'status': 'bloqueada'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ContentTrailMap(
              stages: stages,
              onOpen: (s) => opened = s['id'],
            ),
          ),
        ),
      ),
    );
    final a = find.byKey(const Key('content-node-a'));
    final b = find.byKey(const Key('content-node-b'));
    final c = find.byKey(const Key('content-node-c'));
    expect(tester.getCenter(a).dx, lessThan(tester.getCenter(b).dx));
    expect(tester.getCenter(c).dx, tester.getCenter(a).dx);
    await tester.tap(b);
    expect(opened, isNull);
    await tester.tap(a);
    expect(opened, 'a');
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'material deve ser concluído para liberar prática e sua leitura é enviada à API',
    (tester) async {
      var read = false;
      ApiService.instance = ApiService(
        send: (request) async {
          if (request.method == 'POST') {
            expect(
              Uri.parse(request.path).path,
              '/api/trilhas/t1/etapas/c1/leitura',
            );
            expect(request.data, isEmpty);
            read = true;
          }
          return TcpResponse({
            'trilha': {'totalEtapas': 2},
            'etapa': {
              'id': 'c1',
              'nome': 'Queda livre',
              'disciplina': 'Física',
              'ordem': 1,
              'status': 'disponivel',
              'total': 1,
              'respondidas': 0,
              'motivo': {
                'tipo': 'reforco',
                'descricao': 'Motivo interno da questão',
              },
              'leituraConcluida': read,
              'praticaDisponivel': read,
              'material': {
                'titulo': 'Aprenda sobre a queda',
                'versao': 1,
                'blocos': [
                  {
                    'titulo': 'Gravidade',
                    'texto': 'Sem resistência do ar, os corpos têm a mesma aceleração.',
                  },
                ],
              },
            },
          }, 200);
        },
      );
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: ContentStageScreen(trailId: 't1', stageId: 'c1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gravidade'), findsOneWidget);
      expect(
        find.text(
          'Retome este assunto para reforçar o que você está aprendendo.',
        ),
        findsOneWidget,
      );
      final locked = find.widgetWithText(
        FilledButton,
        'Conclua a leitura primeiro',
      );
      expect(tester.widget<FilledButton>(locked).onPressed, isNull);
      await tester.tap(find.text('Concluir leitura e liberar prática'));
      await tester.pumpAndSettle();
      expect(read, true);
      expect(find.text('Leitura concluída'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Iniciar prática'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('concluir conteúdo retorna ao mapa e libera a próxima etapa', (
    tester,
  ) async {
    var read = false, answered = false;
    Map<String, dynamic> first() => {
      'id': 'c1',
      'nome': 'Queda livre',
      'disciplina': 'Física',
      'ordem': 1,
      'status': answered ? 'concluida' : 'disponivel',
      'questaoIds': ['Q1'],
      'total': 1,
      'respondidas': answered ? 1 : 0,
      'leituraConcluida': read,
      'praticaDisponivel': read,
      'motivo': {'descricao': 'Retome sua dificuldade.'},
    };
    Map<String, dynamic> trail() => {
      'id': 't1',
      'tipo': 'revisao',
      'modo': 'normal',
      'status': 'em_andamento',
      'total': 2,
      'respondidas': answered ? 1 : 0,
      'acertos': answered ? 1 : 0,
      'erros': 0,
      'totalEtapas': 2,
      'etapasConcluidas': answered ? 1 : 0,
      'etapas': [
        first(),
        {
          'id': 'c2',
          'nome': 'Energia',
          'disciplina': 'Física',
          'ordem': 2,
          'status': answered ? 'disponivel' : 'bloqueada',
          'questaoIds': ['Q2'],
          'total': 1,
          'respondidas': 0,
          'motivo': {'descricao': 'Novo conteúdo.'},
        },
      ],
      'itens': [
        {
          'questaoId': 'Q1',
          'disciplina': 'Física',
          'nome': 'Exemplo',
          if (answered)
            'resposta': {'alternativa': 'A', 'gabarito': 'A', 'correta': true},
          'questao': {
            'id': 'Q1',
            'questao': 'Questão do conteúdo',
            'alternativaA': 'Resposta adequada',
            'alternativaB': 'Resposta incompatível com o enunciado',
          },
        },
      ],
    };
    ApiService.instance = ApiService(
      send: (req) async {
        if (Uri.parse(req.path).path.endsWith('/leitura')) read = true;
        if (Uri.parse(req.path).path.endsWith('/respostas')) answered = true;
        final data = Uri.parse(req.path).path == '/api/trilhas'
            ? {'trilhas': []}
            : {
                'trilha': trail(),
                if (Uri.parse(req.path).path.contains('/etapas/'))
                  'etapa': {
                    ...first(),
                    'material': {
                      'titulo': 'A queda livre',
                      'versao': 1,
                      'blocos': [
                        {
                          'titulo': 'Gravidade',
                          'texto': 'A gravidade acelera os corpos.',
                        },
                      ],
                    },
                  },
                if (Uri.parse(req.path).path.endsWith('/respostas'))
                  'resposta': {'gabarito': 'A', 'correta': true},
              };
        return TcpResponse(data, 200);
      },
    );
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: UserTrailView())),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<InkWell>(find.byKey(const Key('content-node-c2'))).onTap,
      isNull,
    );
    for (final label in [
      'Abrir conteúdo',
      'Concluir leitura e liberar prática',
      'Iniciar prática',
      'A. Resposta adequada',
      'Confirmar resposta',
      'Concluir conteúdo',
      'Voltar à trilha',
    ]) {
      final button = find.text(label);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    expect(answered, true);
    expect(find.text('1 de 2 etapas concluídas'), findsOneWidget);
    expect(
      tester.widget<InkWell>(find.byKey(const Key('content-node-c2'))).onTap,
      isNotNull,
    );
  });

  testWidgets('continuação lenta mantém a trilha escolhida no histórico', (
    tester,
  ) async {
    final generation = Completer<TcpResponse>();
    final loaded = <String>[];
    final original = {
      'id': 'original',
      'tipo': 'pratica',
      'modo': 'normal',
      'status': 'concluida',
      'etapas': <Object>[],
    };
    final selected = {
      'id': 'escolhida',
      'tipo': 'revisao',
      'modo': 'normal',
      'status': 'em_andamento',
      'etapas': <Object>[],
    };
    ApiService.instance = ApiService(
      send: (request) async {
        if (request.method == 'POST') return generation.future;

        final path = Uri.parse(request.path).path;
        loaded.add(path);
        return TcpResponse({
          'trilha': path.endsWith('/escolhida') ? selected : original,
          'trilhas': [selected],
        }, 200);
      },
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: UserTrailView())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver próxima trilha'));
    await tester.pump();
    await tester.tap(find.text('Reforço · em andamento'));
    await tester.pumpAndSettle();

    generation.complete(
      TcpResponse({
        'proximaTrilha': {'id': 'continuacao'},
      }, 200),
    );
    await tester.pumpAndSettle();

    expect(loaded, isNot(contains('/api/trilhas/continuacao')));
    expect(find.text('Fortaleça sua base'), findsOneWidget);
  });
}
