import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'graph_quiz_screen.dart';
import 'content_stage_screen.dart';
import 'content_trail_map.dart';
import 'theme.dart';
import 'widgets.dart';

class UserTrailView extends StatefulWidget {
  const UserTrailView({
    super.key,
    this.active = true,
    this.initialMode = 'normal',
    this.initialTrailId,
  });
  final bool active;
  final String initialMode;
  final String? initialTrailId;
  @override
  State<UserTrailView> createState() => _UserTrailViewState();
}

class _UserTrailViewState extends State<UserTrailView> {
  late String mode = widget.initialMode;
  late String? selectedTrailId = widget.initialTrailId;
  Map<String, dynamic>? trail;
  List<Map<String, dynamic>> history = [];
  bool loading = false;
  String? error;
  int requestVersion = 0;
  String _label(dynamic type) => switch (type) {
    'diagnostico' => 'Diagnóstico',
    'pratica' => 'Prática',
    'revisao' => 'Reforço',
    'exploracao' => 'Novos conteúdos',
    _ => 'Atividade',
  };
  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(covariant UserTrailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  Future<void> _load() async {
    final version = ++requestVersion;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await Future.wait([
        selectedTrailId == null
            ? ApiService.instance.currentTrail(mode)
            : ApiService.instance.getTrail(selectedTrailId!),
        ApiService.instance.trailHistory(mode),
      ]);
      if (mounted && version == requestVersion) {
        setState(() {
          trail = data[0]['trilha'] as Map<String, dynamic>?;
          history = (data[1]['trilhas'] as List).cast<Map<String, dynamic>>();
        });
      }
    } on ApiException catch (e) {
      if (mounted && version == requestVersion) {
        setState(() => error = e.message);
      }
    } finally {
      if (mounted && version == requestVersion) setState(() => loading = false);
    }
  }

  Future<void> _diagnostic({String? id, bool example = false}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GraphQuizScreen(trailId: id, diagnostic: true, example: example),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _content(Map<String, dynamic> stage) async {
    if (stage['status'] == 'bloqueada') return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ContentStageScreen(
          trailId: trail!['id'] as String,
          stageId: stage['id'] as String,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _nextTrail() async {
    final nextId = trail?['proximaTrilhaId'] as String?;
    if (nextId != null) {
      selectedTrailId = nextId;
      await _load();
      return;
    }
    try {
      final data = await ApiService.instance.generateTrail(
        trail!['id'] as String,
      );
      if (!mounted) return;
      selectedTrailId = (data['proximaTrilha'] as Map)['id'] as String;
      _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final answers = (trail?['itens'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final stages = (trail?['etapas'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(
          (stage) => <String, dynamic>{
            ...stage,
            'erros': answers
                .where(
                  (item) =>
                      (stage['questaoIds'] as List? ?? []).contains(
                        item['questaoId'],
                      ) &&
                      (item['resposta'] as Map?)?['correta'] == false,
                )
                .length,
          },
        )
        .toList();
    final current = stages
        .where((s) => s['status'] == 'disponivel')
        .firstOrNull;
    final done = stages.where((s) => s['status'] == 'concluida').length;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppMark(compact: true),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Atualizar trilha',
                          onPressed: loading ? null : _load,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sua jornada de aprendizagem',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Um conteúdo por vez: entenda, pratique e avance pelo caminho.',
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'normal',
                          label: Text('Minha trilha'),
                        ),
                        ButtonSegment(
                          value: 'exemplo',
                          label: Text('Exemplos de teste'),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (value) {
                        setState(() {
                          mode = value.first;
                          selectedTrailId = null;
                          trail = null;
                          history = [];
                        });
                        _load();
                      },
                    ),
                    const SizedBox(height: 24),
                    if (loading)
                      const Center(child: CircularProgressIndicator())
                    else if (error != null) ...[
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Tentar novamente'),
                      ),
                    ] else if (trail == null) ...[
                      const SurfaceCard(
                        child: Text(
                          'Faça um diagnóstico para descobrir quais conteúdos estudar primeiro. Cada etapa terá material teórico e uma prática para concluir.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () =>
                            _diagnostic(example: mode == 'exemplo'),
                        child: const Text('Começar diagnóstico'),
                      ),
                    ] else if (trail!['tipo'] == 'diagnostico') ...[
                      SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seu ponto de partida',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${trail!['respondidas']} de ${trail!['total']} respostas salvas.',
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () =>
                                  _diagnostic(id: trail!['id'] as String),
                              child: const Text('Continuar diagnóstico'),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SurfaceCard(
                        color: const Color(0xFFEFF3FF),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trail!['tipo'] == 'revisao'
                                  ? 'Fortaleça sua base'
                                  : 'Explore novos conteúdos',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('$done de ${stages.length} etapas concluídas'),
                            const SizedBox(height: 12),
                            Semantics(
                              container: true,
                              child: LinearProgressIndicator(
                                semanticsLabel: 'Progresso da trilha',
                                value: stages.isEmpty
                                    ? 0
                                    : done / stages.length,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (current != null) ...[
                              Text(
                                current['nome'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _content(current),
                                icon: const Icon(Icons.auto_stories_rounded),
                                label: const Text('Abrir conteúdo'),
                              ),
                            ] else if (trail!['status'] == 'concluida')
                              FilledButton(
                                onPressed: _nextTrail,
                                child: const Text('Ver próxima trilha'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _Legend(
                            icon: Icons.auto_stories_rounded,
                            label: 'Disponível',
                            color: AppColors.primary,
                          ),
                          _Legend(
                            icon: Icons.check_circle_rounded,
                            label: 'Concluído',
                            color: AppColors.mint,
                          ),
                          _Legend(
                            icon: Icons.replay_rounded,
                            label: 'Revisar',
                            color: Color(0xFFB54708),
                          ),
                          _Legend(
                            icon: Icons.lock_rounded,
                            label: 'Bloqueado',
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ContentTrailMap(stages: stages, onOpen: _content),
                    ],
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      key: const Key('example-diagnostic-button'),
                      onPressed: loading
                          ? null
                          : () => _diagnostic(example: true),
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Novo diagnóstico de exemplo'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Teste os acertos e erros para ver seu caminho de conteúdos. Seu progresso fica salvo.',
                    ),
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const Text(
                        'Histórico salvo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      for (final entry in history)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${_label(entry['tipo'])} · ${entry['status'] == 'concluida' ? 'concluída' : 'em andamento'}',
                          ),
                          subtitle: Text(
                            entry['tipo'] == 'diagnostico'
                                ? '${entry['respondidas']}/${entry['total']} respostas'
                                : '${entry['etapasConcluidas'] ?? 0}/${entry['totalEtapas'] ?? 0} conteúdos concluídos',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            if (entry['tipo'] == 'diagnostico') {
                              _diagnostic(id: entry['id'] as String);
                            } else {
                              selectedTrailId = entry['id'] as String;
                              _load();
                            }
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
