// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';

import 'graph_quiz_screen.dart';
import 'services/api_service.dart';
import 'theme.dart';
import 'widgets.dart';

class ContentStageScreen extends StatefulWidget {
  const ContentStageScreen({
    super.key,
    required this.trailId,
    required this.stageId,
  });

  final String trailId;
  final String stageId;

  @override
  State<ContentStageScreen> createState() => _ContentStageScreenState();
}

class _ContentStageScreenState extends State<ContentStageScreen> {
  Map<String, dynamic>? _stage;
  int? _totalStages;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _showStage(Map<String, dynamic> response) {
    final stage = response['etapa'];
    final trail = response['trilha'];

    if (stage is! Map<String, dynamic> ||
        stage['nome'] is! String ||
        trail is! Map<String, dynamic>) {
      throw const ApiException('Não foi possível abrir este conteúdo.');
    }

    setState(() {
      _stage = stage;
      _totalStages = trail['totalEtapas'] as int?;
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.instance.getContentStage(
        widget.trailId,
        widget.stageId,
      );
      if (mounted) _showStage(data);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _read() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final data = await ApiService.instance.completeContentReading(
        widget.trailId,
        widget.stageId,
      );

      // O servidor confirma a leitura da versão atual e informa se a prática foi liberada.
      if (mounted) _showStage(data);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _practice() async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GraphQuizScreen(trailId: widget.trailId, stageId: widget.stageId),
      ),
    );

    if (!mounted) return;

    if (completed == true) {
      Navigator.pop(context, true);
    } else {
      await _load();
    }
  }

  String? _recommendation(Map<String, dynamic> stage) {
    final reason = stage['motivo'];
    if (reason is! Map) return null;

    // A tela explica o motivo da etapa a partir do conteúdo que o aluno vai estudar.
    switch (reason['tipo']) {
      case 'reforco':
      case 'fundamento':
      case 'retomada':
        return 'Retome este assunto para reforçar o que você está aprendendo.';
      case 'exploracao':
        return 'Explore outro assunto e pratique o que aprendeu.';
      case 'complementar':
        return 'Uma etapa complementar para variar a prática.';
      case 'inicial':
        return null;
      default:
        final description = reason['descricao'];
        return description is String ? description : null;
    }
  }

  Widget _materialCard(Map<String, dynamic> stage) {
    final material = stage['material'] as Map<String, dynamic>?;
    final blocks = (material?['blocos'] as List? ?? [])
        .whereType<Map<String, dynamic>>();
    final read = stage['leituraConcluida'] == true;
    final title = Theme.of(context).textTheme.titleLarge;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          _CardHeading(
            title: '1. Material teórico',
            icon: read ? Icons.check_circle : Icons.menu_book_rounded,
            color: AppColors.primary,
          ),
          if (blocks.isEmpty) ...[
            Text('Material em preparação', style: title),
            const Text(
              'Você pode seguir para a prática enquanto o material está indisponível.',
            ),
          ] else ...[
            Text(
              material?['titulo'] as String? ?? 'Material teórico',
              style: title,
            ),
            for (final block in blocks)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    block['titulo'] as String,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    block['texto'] as String,
                    style: const TextStyle(height: 1.6),
                  ),
                ],
              ),
            if (read)
              const Text(
                'Leitura concluída',
                style: TextStyle(
                  color: Color(0xFF08765F),
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              FilledButton.icon(
                onPressed: _saving ? null : _read,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  _saving ? 'Salvando…' : 'Concluir leitura e liberar prática',
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _practiceCard(Map<String, dynamic> stage) {
    final done = stage['status'] == 'concluida';
    final available = stage['praticaDisponivel'] == true;
    var icon = available ? Icons.quiz_outlined : Icons.lock_outline;
    if (done) icon = Icons.check_circle;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          _CardHeading(
            title: '2. Prática do conteúdo',
            icon: icon,
            color: done ? AppColors.mint : AppColors.primary,
          ),
          Text(
            '${stage['respondidas']} de ${stage['total']} questões respondidas.',
          ),
          Text(
            done
                ? 'Conteúdo concluído. Seu progresso está salvo.'
                : 'Conclua a prática para liberar a próxima etapa da trilha.',
          ),
          if (done)
            OutlinedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Voltar à trilha'),
            )
          else
            FilledButton(
              onPressed: available && !_saving ? _practice : null,
              child: Text(
                available ? 'Iniciar prática' : 'Conclua a leitura primeiro',
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _content() {
    final stage = _stage;
    final error = _error;
    if (stage == null) {
      return [
        Text(error ?? 'Conteúdo indisponível.'),
        TextButton(onPressed: _load, child: const Text('Tentar novamente')),
      ];
    }

    final recommendation = _recommendation(stage);
    return [
      Text(
        'ETAPA ${stage['ordem']} DE $_totalStages · ${stage['disciplina']}',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        stage['nome'] as String,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      if (recommendation != null) ...[
        const SizedBox(height: 10),
        Text(recommendation),
      ],
      const SizedBox(height: 24),
      _materialCard(stage),
      const SizedBox(height: 20),
      _practiceCard(stage),
      if (error != null) ...[
        const SizedBox(height: 12),
        Text(
          error,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seu próximo conteúdo')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: _content(),
                  ),
                ),
              ),
      ),
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        Icon(icon, color: color),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}
