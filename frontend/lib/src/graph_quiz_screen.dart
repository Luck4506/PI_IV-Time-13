// Autoria de Lucas Soares Gonçalves RA 25009467
import 'package:flutter/material.dart';

import 'exam_question_source.dart';
import 'quiz_answer_feedback.dart';
import 'services/api_service.dart';

class GraphQuizScreen extends StatefulWidget {
  const GraphQuizScreen({
    super.key,
    this.diagnostic = false,
    this.trailId,
    this.stageId,
  });
  final bool diagnostic;
  final String? trailId;
  final String? stageId;
  @override
  State<GraphQuizScreen> createState() => _GraphQuizScreenState();
}

class _GraphQuizScreenState extends State<GraphQuizScreen> {
  final startKey = ApiService.requestKey();
  final replacementKey = ApiService.requestKey();
  final feedbackAnchor = GlobalKey();
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
    final loaded = data['trilha'];
    if (loaded is! Map<String, dynamic> ||
        loaded['id'] is! String ||
        loaded['itens'] is! List) {
      throw const ApiException('Não foi possível abrir as questões da trilha.');
    }

    final questions = (loaded['itens'] as List)
        .whereType<Map<String, dynamic>>();
    final stageId = widget.stageId;
    if (stageId == null) {
      items = questions.toList();
    } else {
      // A prática de um conteúdo usa somente as questões da etapa aberta.
      final stages = (loaded['etapas'] as List? ?? [])
          .whereType<Map<String, dynamic>>();
      final stage = stages.where((item) => item['id'] == stageId).firstOrNull;
      final ids = (stage?['questaoIds'] as List? ?? []).toSet();
      items = questions
          .where((item) => ids.contains(item['questaoId']))
          .toList();
    }

    trail = loaded;
    final continuation = data['proximaTrilha'];
    nextTrail = continuation is Map<String, dynamic> ? continuation : null;
  }

  Future<Map<String, dynamic>> _fetchTrail() async {
    final api = ApiService.instance;
    final id = trail?['id'] as String? ?? widget.trailId;
    if (id != null) return api.getTrail(id);

    final data = await api.currentTrail();
    final active = data['trilha'];
    if (active is Map<String, dynamic> &&
        (!widget.diagnostic || active['tipo'] == 'diagnostico')) {
      return data;
    }

    return api.startTrail(diagnostic: widget.diagnostic, key: startKey);
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await _fetchTrail();
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
    final alternative = selected;
    final trailId = trail?['id'] as String?;
    if (alternative == null ||
        submitting ||
        trailId == null ||
        current >= items.length) {
      return;
    }

    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final data = await ApiService.instance.answerTrail(
        trailId,
        items[current]['questaoId'] as String,
        alternative,
      );
      if (mounted) {
        final saved = data['resposta'];
        if (saved is! Map<String, dynamic>) {
          throw const ApiException('Não foi possível confirmar a resposta.');
        }
        setState(() {
          _apply(data);
          result = saved;
        });
        _showFeedback();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _startWithCompleteQuestions() async {
    if (submitting) return;
    setState(() {
      submitting = true;
      error = null;
    });

    try {
      final diagnostic = trail?['tipo'] == 'diagnostico';
      final subjects = (trail?['itens'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((item) => item['disciplina'])
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty)
          .toSet();
      final data = await ApiService.instance.startTrail(
        diagnostic: diagnostic,
        key: replacementKey,
        subject: !diagnostic && subjects.length == 1 ? subjects.single : null,
      );
      final id = (data['trilha'] as Map?)?['id'];
      if (id is! String) {
        throw const ApiException(
          'Não foi possível iniciar uma nova atividade.',
        );
      }
      if (!mounted) return;

      // A prática começa no mapa, onde a leitura libera as questões da etapa.
      if (!diagnostic) {
        Navigator.pushReplacementNamed(context, '/aluno/trilha', arguments: id);
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GraphQuizScreen(trailId: id, diagnostic: true),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _showFeedback() {
    // No celular, a correção aparece abaixo do botão que o aluno tocou.
    // Esperamos o Flutter montar essa parte antes de rolar até ela.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedbackContext = feedbackAnchor.currentContext;
      if (feedbackContext == null) return;

      Scrollable.ensureVisible(
        feedbackContext,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: const Duration(milliseconds: 220),
      );
    });
  }

  Future<void> _generate() async {
    final trailId = trail?['id'] as String?;
    if (submitting || trailId == null) return;

    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final data = await ApiService.instance.generateTrail(trailId);
      if (mounted) setState(() => _apply(data));
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Widget _emptyQuiz() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error ?? 'Nenhuma questão corrigível disponível no momento.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _completedStage() {
    return Center(
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
  }

  Widget _completedQuiz() {
    final nextItems = (nextTrail?['etapas'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return Center(
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
                  subtitle: Text('${item['disciplina']} · Material + prática'),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/aluno/trilha',
                  arguments: nextTrail!['id'],
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
  }

  Widget _answerResult() {
    String nextLabel = 'Próxima questão';
    if (current == items.length - 1) {
      nextLabel = widget.stageId != null
          ? 'Concluir conteúdo'
          : 'Ver resultado e trilha';
    }

    return Column(
      key: feedbackAnchor,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizAnswerFeedback(
          correct: result!['correta'] == true,
          selected: selected,
          answerKey: result!['gabarito'].toString(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => setState(() {
            current++;
            selected = null;
            result = null;
            error = null;
          }),
          child: Text(nextLabel),
        ),
      ],
    );
  }

  Widget _currentQuestion() {
    final item = items[current];
    final question = item['questao'] as Map<String, dynamic>?;
    final statement = question?['questao'] ?? question?['enunciado'];
    final images = question?['imagens'];
    final alternatives = <String, String>{};
    for (final letter in ['A', 'B', 'C', 'D', 'E']) {
      final text = question?['alternativa$letter'];
      if (text is String && text.trim().isNotEmpty) {
        alternatives[letter] = text;
      }
    }
    final placeholder = RegExp(r'^alternativa [a-e]$', caseSensitive: false);
    final unavailable =
        question == null ||
        statement is! String ||
        statement.trim().isEmpty ||
        (images is List && images.isNotEmpty) ||
        alternatives.length < 2 ||
        alternatives.values.any((text) => placeholder.hasMatch(text.trim()));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          key: ValueKey(item['questaoId']),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Questão ${current + 1} de ${items.length} · ${item['disciplina']}',
            ),
            const SizedBox(height: 6),
            const SizedBox(height: 12),
            if (unavailable) ...[
              Text(
                question == null
                    ? 'Esta questão não está disponível no momento. Sua trilha está salva.'
                    : 'Esta questão antiga ainda não pode ser respondida na tela. Suas respostas anteriores estão salvas.',
              ),
              if (question == null)
                TextButton(
                  onPressed: submitting ? null : _load,
                  child: const Text('Recarregar'),
                ),
              FilledButton(
                onPressed: submitting ? null : _startWithCompleteQuestions,
                child: Text(
                  submitting ? 'Carregando…' : 'Iniciar nova atividade',
                ),
              ),
              if (error != null) Text(error!),
            ] else ...[
              ExamQuestionSource(question: question),
              Text(statement, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              for (final MapEntry(key: letter, value: label)
                  in alternatives.entries)
                QuizAnswerOption(
                  letter: letter,
                  label: '$letter. $label',
                  selected: selected == letter,
                  correct: result?['gabarito'] == letter,
                  wrong: result?['correta'] == false && selected == letter,
                  onPressed: result != null || submitting
                      ? null
                      : () => setState(() => selected = letter),
                ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (result != null)
                _answerResult()
              else
                FilledButton(
                  onPressed: selected == null || submitting ? null : _answer,
                  child: Text(submitting ? 'Salvando…' : 'Confirmar resposta'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return _emptyQuiz();
    if (current < items.length) return _currentQuestion();
    if (widget.stageId != null) return _completedStage();
    return _completedQuiz();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.stageId != null
              ? 'Prática do conteúdo'
              : widget.diagnostic
              ? 'Diagnóstico inicial'
              : 'Prática da trilha',
        ),
      ),
      body: SafeArea(child: _body()),
    );
  }
}
