import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'graph_quiz_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class ContentStageScreen extends StatefulWidget {
  const ContentStageScreen({
    super.key,
    required this.trailId,
    required this.stageId,
  });
  final String trailId, stageId;
  @override
  State<ContentStageScreen> createState() => _ContentStageScreenState();
}

class _ContentStageScreenState extends State<ContentStageScreen> {
  Map<String, dynamic>? stage;
  Map<String, dynamic>? trail;
  bool loading = true, saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ApiService.instance.getContentStage(
        widget.trailId,
        widget.stageId,
      );
      if (mounted) {
        setState(() {
          stage = data['etapa'] as Map<String, dynamic>;
          trail = data['trilha'] as Map<String, dynamic>;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _read() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final data = await ApiService.instance.completeContentReading(
        widget.trailId,
        widget.stageId,
      );
      if (mounted) {
        setState(() => stage = data['etapa'] as Map<String, dynamic>);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => saving = false);
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
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final material = stage?['material'] as Map<String, dynamic>?;
    final blocks = (material?['blocos'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final done = stage?['status'] == 'concluida';
    final read = stage?['leituraConcluida'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Seu próximo conteúdo')),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      if (stage == null) ...[
                        Text(error ?? 'Conteúdo indisponível.'),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Tentar novamente'),
                        ),
                      ] else ...[
                        Text(
                          'ETAPA ${stage!['ordem']} DE ${trail!['totalEtapas']} · ${stage!['disciplina']}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          stage!['nome'] as String,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text((stage!['motivo'] as Map)['descricao'] as String),
                        const SizedBox(height: 24),
                        SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    read
                                        ? Icons.check_circle
                                        : Icons.menu_book_rounded,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    '1. Material teórico',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (blocks.isEmpty) ...[
                                const Text(
                                  'Material em preparação',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Aqui você encontrará a explicação e os materiais deste conteúdo. Enquanto eles são preparados, a prática já está disponível.',
                                ),
                              ] else ...[
                                Text(
                                  material!['titulo'] as String,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                for (final block in blocks) ...[
                                  const SizedBox(height: 18),
                                  Text(
                                    block['titulo'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    block['texto'] as String,
                                    style: const TextStyle(height: 1.6),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                if (read)
                                  const Text(
                                    'Leitura concluída',
                                    style: TextStyle(
                                      color: AppColors.mint,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                else
                                  FilledButton.icon(
                                    onPressed: saving ? null : _read,
                                    icon: const Icon(Icons.check_rounded),
                                    label: Text(
                                      saving ? 'Salvando…' : 'Concluir leitura e liberar prática',
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    done
                                        ? Icons.check_circle
                                        : stage!['praticaDisponivel'] == true
                                        ? Icons.quiz_outlined
                                        : Icons.lock_outline,
                                    color: done
                                        ? AppColors.mint
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    '2. Prática do conteúdo',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${stage!['respondidas']} de ${stage!['total']} questões respondidas.',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                done
                                    ? 'Conteúdo concluído. A próxima etapa foi liberada.'
                                    : 'Conclua a prática para liberar a próxima etapa da trilha.',
                              ),
                              const SizedBox(height: 16),
                              if (done)
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Voltar à trilha'),
                                )
                              else
                                FilledButton(
                                  onPressed:
                                      stage!['praticaDisponivel'] == true &&
                                          !saving
                                      ? _practice
                                      : null,
                                  child: Text(
                                    stage!['praticaDisponivel'] == true
                                        ? 'Iniciar prática'
                                        : 'Conclua a leitura primeiro',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
