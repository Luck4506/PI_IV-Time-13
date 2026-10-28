import 'package:flutter/material.dart';

import 'services/api_service.dart';

class GraphQuizScreen extends StatefulWidget {
  const GraphQuizScreen({super.key, this.diagnostic = false});
  final bool diagnostic;
  @override
  State<GraphQuizScreen> createState() => _GraphQuizScreenState();
}

class _GraphQuizScreenState extends State<GraphQuizScreen> {
  List<Map<String, dynamic>> questions = [];
  bool loading = true;
  bool submitting = false;
  String? error;
  String? selected;
  Map<String, dynamic>? result;
  int current = 0;
  int answered = 0;
  int corrected = 0;
  int correct = 0;

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
      final data = await ApiService.instance.questions(
        limit: widget.diagnostic ? 3 : 10,
      );
      if (mounted) setState(() => questions = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _answer() async {
    if (selected == null || submitting) return;
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final id = Uri.encodeComponent(questions[current]['id'].toString());
      final response = await ApiService.instance.request(
        'POST',
        '/api/questoes/$id/responder',
        {'alternativa': selected},
      );
      if (mounted) {
        setState(() {
          result = response;
          answered++;
          if (response['corrigida'] == true) corrected++;
          if (response['correta'] == true) correct++;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _finish() {
    if (widget.diagnostic) {
      Navigator.pushNamedAndRemoveUntil(context, '/aluno', (_) => false);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (questions.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error ?? 'Nenhuma questão disponível no momento.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    } else if (current >= questions.length) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Atividade concluída',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '$answered questões respondidas. $correct acertos entre $corrected questões com gabarito.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Este teste ainda não altera sua trilha nem salva seu progresso.',
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _finish, child: const Text('Continuar')),
            ],
          ),
        ),
      );
    } else {
      final question = questions[current];
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Questão ${current + 1} de ${questions.length}'),
              const SizedBox(height: 12),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OutlinedButton(
                      onPressed: result != null || submitting
                          ? null
                          : () => setState(() => selected = letter),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        backgroundColor: selected == letter
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text('$letter. ${question['alternativa$letter']}'),
                    ),
                  ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (result != null) ...[
                Text(
                  result!['corrigida'] == true
                      ? (result!['correta'] == true
                            ? 'Resposta correta!'
                            : 'Alternativa correta: ${result!['gabarito']}.')
                      : result!['mensagem'].toString(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => setState(() {
                    current++;
                    selected = null;
                    result = null;
                  }),
                  child: Text(
                    current == questions.length - 1
                        ? 'Concluir'
                        : 'Próxima questão',
                  ),
                ),
              ] else
                FilledButton(
                  onPressed: selected == null || submitting ? null : _answer,
                  child: Text(
                    submitting ? 'Conferindo…' : 'Confirmar resposta',
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diagnostic ? 'Diagnóstico inicial' : 'Prática'),
      ),
      body: SafeArea(child: body),
    );
  }
}
