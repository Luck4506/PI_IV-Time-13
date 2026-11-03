import 'package:flutter/material.dart';

import 'services/api_service.dart';

class GraphQuizScreen extends StatefulWidget {
  const GraphQuizScreen({
    super.key,
    this.diagnostic = false,
    this.example = false,
    this.trailId,
    this.stageId,
  });
  final bool diagnostic;
  final bool example;
  final String? trailId;
  final String? stageId;
  @override
  State<GraphQuizScreen> createState() => _GraphQuizScreenState();
}

class _GraphQuizScreenState extends State<GraphQuizScreen> {
  final startKey = ApiService.requestKey();
  Map<String, dynamic>? trail;
  Map<String, dynamic>? nextTrail;
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  bool submitting = false;
  String? error;
  String? selected;
  Map<String, dynamic>? result;
  int current = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _apply(Map<String, dynamic> data) {
    trail = data['trilha'] as Map<String, dynamic>;
    items = (trail!['itens'] as List).cast<Map<String, dynamic>>();
    if (widget.stageId != null) {
      final stages = (trail!['etapas'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final stage = stages.firstWhere(
        (x) => x['id'] == widget.stageId,
        orElse: () => {},
      );
      final ids = (stage['questaoIds'] as List? ?? []);
      items = items.where((x) => ids.contains(x['questaoId'])).toList();
    }
    nextTrail = data['proximaTrilha'] as Map<String, dynamic>?;
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      Map<String, dynamic> data;
      final id = trail?['id'] as String? ?? widget.trailId;
      if (id != null) {
        data = await ApiService.instance.getTrail(id);
      } else {
        final active = !widget.diagnostic && !widget.example
            ? (await ApiService.instance.currentTrail('normal'))['trilha']
                  as Map<String, dynamic>?
            : null;
        data = active != null
            ? {'trilha': active}
            : await ApiService.instance.startTrail(
                diagnostic: widget.diagnostic,
                example: widget.example,
                key: startKey,
              );
      }
      if (mounted) {
        setState(() {
          _apply(data);
          current = items.indexWhere((x) => x['resposta'] == null);
          if (current < 0) current = items.length;
          result = null;
          selected = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _answer() async {
    if (selected == null || submitting || trail == null) return;
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final data = await ApiService.instance.answerTrail(
        trail!['id'] as String,
        items[current]['questaoId'] as String,
        selected!,
      );
      if (mounted) {
        setState(() {
          _apply(data);
          result = data['resposta'] as Map<String, dynamic>;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _generate() async {
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final data = await ApiService.instance.generateTrail(
        trail!['id'] as String,
      );
      if (mounted) setState(() => _apply(data));
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Widget _option(String letter, Map<String, dynamic> question) {
    final correct = result != null && result!['gabarito'] == letter;
    final wrong =
        result != null && result!['correta'] != true && selected == letter;
    final color = correct
        ? const Color(0xFF13795B)
        : wrong
        ? const Color(0xFFB42318)
        : null;
    final background = correct
        ? const Color(0xFFE8F8F3)
        : wrong
        ? const Color(0xFFFFECE7)
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        key: Key('answer-option-$letter'),
        onPressed: result != null || submitting
            ? null
            : () => setState(() => selected = letter),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: color,
          disabledForegroundColor: color,
          backgroundColor:
              background ??
              (selected == letter
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null),
          disabledBackgroundColor: background,
          side: color == null ? null : BorderSide(color: color, width: 2),
          padding: const EdgeInsets.all(16),
        ),
        child: Row(
          children: [
            Expanded(child: Text('$letter. ${question['alternativa$letter']}')),
            if (correct || wrong) ...[
              const SizedBox(width: 10),
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                semanticLabel: correct
                    ? 'Alternativa correta'
                    : 'Sua resposta incorreta',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _feedback() {
    final correct = result!['correta'] == true;
    final color = correct ? const Color(0xFF13795B) : const Color(0xFFB42318);
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(correct ? 'correct-answer-feedback' : 'wrong-answer-feedback'),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: correct ? const Color(0xFFE8F8F3) : const Color(0xFFFFECE7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              correct
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: color,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correct ? 'Resposta correta!' : 'Ainda não foi desta vez',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  if (!correct) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Você marcou $selected. Alternativa correta: ${result!['gabarito']}.',
                      style: TextStyle(color: color),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Releia o conteúdo com calma e siga praticando.',
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text('Resposta salva.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guide() {
    final guide = (trail?['roteiro'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    if (guide.isEmpty) return const SizedBox.shrink();
    return Card(
      child: ExpansionTile(
        title: const Text('Roteiro para testar acertos e erros'),
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Para testar a revisão, erre a primeira e acerte as outras. Para testar novos assuntos, acerte as três. As respostas deste exemplo também são salvas.',
            ),
          ),
          for (final step in guide)
            ListTile(
              title: Text('${step['questaoId']} · ${step['nome']}'),
              subtitle: Text(
                'Para acertar: ${step['correta']} · Para errar: ${step['incorreta']}',
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (items.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error ?? 'Nenhuma questão corrigível disponível no momento.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    } else if (widget.stageId != null && current >= items.length) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.teal,
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                'Conteúdo concluído!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                trail!['status'] == 'concluida'
                    ? 'Você concluiu esta trilha. Seus resultados estão salvos.'
                    : 'Sua prática foi salva e a próxima etapa está liberada.',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Voltar à trilha'),
              ),
            ],
          ),
        ),
      );
    } else if (current >= items.length) {
      final nextItems = (nextTrail?['etapas'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Atividade concluída',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Acertos: ${trail!['acertos']} · Erros: ${trail!['erros']} · Questões: ${trail!['total']}',
              ),
              const SizedBox(height: 12),
              const Text('Suas respostas e seu histórico foram salvos.'),
              const SizedBox(height: 20),
              if (nextTrail != null) ...[
                Text(
                  nextTrail!['tipo'] == 'revisao'
                      ? 'Sua trilha de reforço está pronta'
                      : 'Você acertou todas! Vamos explorar novos assuntos.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final item in nextItems)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['nome'] as String),
                    subtitle: Text(
                      '${item['disciplina']} · Material + prática',
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/aluno/trilha',
                    arguments: {
                      'modo': trail!['modo'],
                      'trilhaId': nextTrail!['id'],
                    },
                  ),
                  child: const Text('Abrir minha trilha'),
                ),
              ] else ...[
                const Text(
                  'Suas respostas estão salvas. Conclua a geração da próxima trilha.',
                ),
                if (error != null) Text(error!),
                FilledButton(
                  onPressed: submitting ? null : _generate,
                  child: Text(submitting ? 'Gerando…' : 'Gerar minha trilha'),
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      final item = items[current];
      final question = item['questao'] as Map<String, dynamic>?;
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (trail!['modo'] == 'exemplo' &&
                  trail!['tipo'] == 'diagnostico') ...[
                const Text(
                  'DIAGNÓSTICO DE EXEMPLO',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                _guide(),
                const SizedBox(height: 16),
              ],
              Text(
                'Questão ${current + 1} de ${items.length} · ${item['disciplina']}',
              ),
              const SizedBox(height: 6),
              Text(item['questaoId'] as String),
              const SizedBox(height: 12),
              if (question == null) ...[
                const Text(
                  'Esta questão não está disponível no momento. Sua trilha está salva.',
                ),
                TextButton(onPressed: _load, child: const Text('Recarregar')),
              ] else ...[
                Text(
                  (question['questao'] ??
                          question['enunciado'] ??
                          question['nome'] ??
                          '')
                      .toString(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if ((question['imagens'] as List?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Esta questão possui imagem complementar; consulte o material original enquanto as imagens são integradas.',
                  ),
                ],
                const SizedBox(height: 20),
                for (final letter in ['A', 'B', 'C', 'D', 'E'])
                  if (question['alternativa$letter'] != null)
                    _option(letter, question),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (result != null) ...[
                  _feedback(),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() {
                      current++;
                      selected = null;
                      result = null;
                      error = null;
                    }),
                    child: Text(
                      current == items.length - 1
                          ? widget.stageId != null
                                ? 'Concluir conteúdo'
                                : 'Ver resultado e trilha'
                          : 'Próxima questão',
                    ),
                  ),
                ] else
                  FilledButton(
                    onPressed: selected == null || submitting ? null : _answer,
                    child: Text(
                      submitting ? 'Salvando…' : 'Confirmar resposta',
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.stageId != null
              ? 'Prática do conteúdo'
              : widget.example || trail?['modo'] == 'exemplo'
              ? 'Exemplo de diagnóstico'
              : widget.diagnostic
              ? 'Diagnóstico inicial'
              : 'Prática da trilha',
        ),
      ),
      body: SafeArea(child: body),
    );
  }
}
