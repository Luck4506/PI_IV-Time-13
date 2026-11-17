import 'package:flutter/material.dart';

import 'content_stage_screen.dart';
import 'content_trail_map.dart';
import 'graph_quiz_screen.dart';
import 'practice_subject.dart';
import 'services/api_service.dart';
import 'theme.dart';
import 'widgets.dart';

class UserTrailView extends StatefulWidget {
  const UserTrailView({super.key, this.active = true, this.initialTrailId});

  final bool active;
  final String? initialTrailId;

  @override
  State<UserTrailView> createState() => _UserTrailViewState();
}

class _UserTrailViewState extends State<UserTrailView> {
  late String? _selectedTrailId = widget.initialTrailId;
  Map<String, dynamic>? _trail;
  List<Map<String, dynamic>> _history = [];
  bool _loading = false;
  bool _generatingNext = false;
  String? _error;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(covariant UserTrailView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final changedTrail = widget.initialTrailId != oldWidget.initialTrailId;
    if (changedTrail) _selectedTrailId = widget.initialTrailId;
    if (widget.active && (!oldWidget.active || changedTrail)) _load();
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    final selectedId = _selectedTrailId;
    final api = ApiService.instance;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final [active, history] = await Future.wait([
        selectedId == null ? api.currentTrail() : api.getTrail(selectedId),
        api.trailHistory(),
      ]);

      // Se outra trilha foi escolhida durante a consulta, só ela atualiza a tela.
      if (!mounted || version != _loadVersion) return;

      final trail = active['trilha'];
      final rows = history['trilhas'];
      if ((trail != null && trail is! Map<String, dynamic>) || rows is! List) {
        throw const ApiException('Não foi possível carregar a trilha.');
      }

      setState(() {
        _trail = trail as Map<String, dynamic>?;
        _history = rows.whereType<Map<String, dynamic>>().toList();
      });
    } on ApiException catch (error) {
      if (mounted && version == _loadVersion) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && version == _loadVersion) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectTrail(String id) {
    _selectedTrailId = id;
    _load();
  }

  Future<void> _openDiagnostic([String? id]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => GraphQuizScreen(trailId: id, diagnostic: true),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openContent(String trailId, Map<String, dynamic> stage) async {
    if (stage['status'] == 'bloqueada') return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ContentStageScreen(
          trailId: trailId,
          stageId: stage['id'] as String,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openNextTrail(Map<String, dynamic> source) async {
    if (_generatingNext) return;

    final nextId = source['proximaTrilhaId'];
    if (nextId is String) {
      _selectTrail(nextId);
      return;
    }

    final version = _loadVersion;
    setState(() => _generatingNext = true);

    try {
      final data = await ApiService.instance.generateTrail(
        source['id'] as String,
      );
      if (!mounted || version != _loadVersion || !widget.active) return;

      final next = data['proximaTrilha'];
      if (next is! Map<String, dynamic> || next['id'] is! String) {
        throw const ApiException('Não foi possível abrir a próxima trilha.');
      }
      _selectTrail(next['id'] as String);
    } on ApiException catch (error) {
      if (!mounted || version != _loadVersion || !widget.active) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _generatingNext = false);
    }
  }

  Widget _activity() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final error = _error;
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(onPressed: _load, child: const Text('Tentar novamente')),
        ],
      );
    }

    final trail = _trail;
    if (trail == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          const SurfaceCard(
            child: Text(
              'Faça um diagnóstico para descobrir quais conteúdos estudar primeiro. '
              'Depois, leia o material de cada etapa e avance com a prática.',
            ),
          ),
          FilledButton(
            onPressed: _openDiagnostic,
            child: const Text('Começar diagnóstico'),
          ),
        ],
      );
    }

    final id = trail['id'] as String;
    if (trail['tipo'] == 'diagnostico') {
      final completed = trail['status'] == 'concluida';
      return SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              'Seu ponto de partida',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${trail['respondidas']} de ${trail['total']} respostas salvas.',
            ),
            FilledButton(
              onPressed: () => _openDiagnostic(id),
              child: Text(
                completed ? 'Ver resultado' : 'Continuar diagnóstico',
              ),
            ),
          ],
        ),
      );
    }

    return _TrailProgress(
      trail: trail,
      onOpen: (stage) => _openContent(id, stage),
      onNext: () => _openNextTrail(trail),
      generatingNext: _generatingNext,
    );
  }

  Widget _historyRow(Map<String, dynamic> entry) {
    final id = entry['id'] as String;
    final diagnostic = entry['tipo'] == 'diagnostico';
    final kind = switch (entry['tipo']) {
      'diagnostico' => 'Diagnóstico',
      'pratica' => 'Prática',
      'revisao' => 'Reforço',
      'exploracao' => 'Novos conteúdos',
      _ => 'Atividade',
    };
    final status = entry['status'] == 'concluida'
        ? 'concluída'
        : 'em andamento';
    final progress = diagnostic
        ? '${entry['respondidas']}/${entry['total']} respostas'
        : '${entry['etapasConcluidas'] ?? 0}/${entry['totalEtapas'] ?? 0} conteúdos concluídos';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$kind · $status'),
      subtitle: Text(progress),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (diagnostic) {
          _openDiagnostic(id);
        } else {
          _selectTrail(id);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: AppMark(compact: true)),
                        IconButton(
                          tooltip: 'Atualizar trilha',
                          onPressed: _loading ? null : _load,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SectionHeader(
                      title: 'Sua jornada de aprendizagem',
                      subtitle: 'Um conteúdo por vez: entenda, pratique e avance pelo caminho.',
                    ),
                    const SizedBox(height: 12),
                    PracticeSubjectButton(onStarted: _selectTrail),
                    const SizedBox(height: 24),
                    _activity(),
                    if (_history.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'Histórico salvo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      for (final entry in _history) _historyRow(entry),
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

class _TrailProgress extends StatelessWidget {
  const _TrailProgress({
    required this.trail,
    required this.onOpen,
    required this.onNext,
    required this.generatingNext,
  });

  final Map<String, dynamic> trail;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final VoidCallback onNext;
  final bool generatingNext;

  List<Map<String, dynamic>> _stages() {
    final items = (trail['itens'] as List? ?? [])
        .whereType<Map<String, dynamic>>();
    final missed = <Object?>{};
    for (final item in items) {
      final answer = item['resposta'];
      if (answer is Map && answer['correta'] == false) {
        missed.add(item['questaoId']);
      }
    }

    // A indicação de revisão vem das respostas realmente salvas na etapa.
    final stages = (trail['etapas'] as List? ?? [])
        .whereType<Map<String, dynamic>>();
    return [
      for (final stage in stages)
        {
          ...stage,
          'erros': (stage['questaoIds'] as List? ?? [])
              .where(missed.contains)
              .length,
        },
    ];
  }

  String _title(List<Map<String, dynamic>> stages) {
    if (trail['tipo'] == 'revisao') return 'Fortaleça sua base';
    if (trail['tipo'] != 'pratica') return 'Explore novos conteúdos';

    final subjects = stages
        .map((stage) => stage['disciplina'])
        .whereType<String>()
        .toSet();
    if (subjects.length == 1) return 'Prática de ${subjects.single}';
    return 'Prática por conteúdo';
  }

  @override
  Widget build(BuildContext context) {
    final stages = _stages();
    final current = stages
        .where((stage) => stage['status'] == 'disponivel')
        .firstOrNull;
    final done = stages.where((stage) => stage['status'] == 'concluida').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        SurfaceCard(
          color: const Color(0xFFEFF3FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                _title(stages),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('$done de ${stages.length} etapas concluídas'),
              LinearProgressIndicator(
                semanticsLabel: 'Progresso da trilha',
                value: stages.isEmpty ? 0 : done / stages.length,
              ),
              if (current != null) ...[
                Text(
                  current['nome'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                FilledButton.icon(
                  onPressed: () => onOpen(current),
                  icon: const Icon(Icons.auto_stories_rounded),
                  label: const Text('Abrir conteúdo'),
                ),
              ] else if (trail['status'] == 'concluida')
                FilledButton(
                  onPressed: generatingNext ? null : onNext,
                  child: Text(
                    generatingNext
                        ? 'Preparando próxima trilha…'
                        : 'Ver próxima trilha',
                  ),
                ),
            ],
          ),
        ),
        if (stages.isNotEmpty) ...[
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
          ContentTrailMap(stages: stages, onOpen: onOpen),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        Icon(icon, color: color, size: 16),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
