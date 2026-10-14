part of '../../telas_estudante.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  static const route = '/aluno/pratica';

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int current = 0;
  int? selected;
  bool checked = false;

  static const questions = [
    ('Resolva a equação: 4x - 7 = 13', ['x = 3', 'x = 4', 'x = 5', 'x = 6'], 2),
    ('Se 2x + 8 = 20, qual é o valor de x?', ['4', '5', '6', '7'], 2),
    (
      'Qual equação representa “o triplo de um número mais 2 é 17”?',
      ['3x + 2 = 17', '3(x + 2) = 17', 'x + 6 = 17', '2x + 3 = 17'],
      0,
    ),
  ];

  void _continue() {
    if (!checked) {
      setState(() => checked = true);
      return;
    }
    if (current == questions.length - 1) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const _PracticeCompleteSheet(),
      );
      return;
    }
    setState(() {
      current++;
      selected = null;
      checked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[current];
    final correct = selected == question.$3;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('Equações do 1º grau'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: TagChip(
                label: '+20 XP',
                icon: Icons.stars_rounded,
                color: Color(0xFFB87A00),
                backgroundColor: AppColors.amberSoft,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ProgressBar(
                value: (current + 1) / questions.length,
                height: 7,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: PageFrame(
                  maxWidth: 680,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Questão ${current + 1} de ${questions.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question.$1,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 26),
                      ...List.generate(
                        question.$2.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnswerOption(
                            label: question.$2[index],
                            index: index,
                            selected: selected == index,
                            checked: checked,
                            correctIndex: question.$3,
                            onTap: checked
                                ? null
                                : () => setState(() => selected = index),
                          ),
                        ),
                      ),
                      if (checked) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(17),
                          decoration: BoxDecoration(
                            color: correct
                                ? AppColors.mintSoft
                                : AppColors.coralSoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                correct
                                    ? Icons.check_circle_rounded
                                    : Icons.lightbulb_rounded,
                                color: correct
                                    ? AppColors.mint
                                    : AppColors.coral,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      correct ? 'Muito bem!' : 'Vamos entender',
                                      style: TextStyle(
                                        color: correct
                                            ? const Color(0xFF147D64)
                                            : const Color(0xFFA63F2A),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Some 7 aos dois lados: 4x = 20. Depois divida tudo por 4. Assim, x = 5.',
                                      style: TextStyle(
                                        color: correct
                                            ? const Color(0xFF216B59)
                                            : const Color(0xFF8E4939),
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: FilledButton(
                    onPressed: selected == null ? null : _continue,
                    style: checked
                        ? FilledButton.styleFrom(
                            backgroundColor: correct
                                ? AppColors.mint
                                : AppColors.coral,
                          )
                        : null,
                    child: Text(
                      checked
                          ? (current == questions.length - 1
                                ? 'Concluir prática'
                                : 'Próxima questão')
                          : 'Verificar resposta',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.index,
    required this.selected,
    required this.checked,
    required this.correctIndex,
    required this.onTap,
  });
  final String label;
  final int index;
  final bool selected;
  final bool checked;
  final int correctIndex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color border = selected ? AppColors.primary : AppColors.border;
    Color background = selected ? const Color(0xFFF1F4FF) : AppColors.white;
    IconData? trailing;
    if (checked && index == correctIndex) {
      border = AppColors.mint;
      background = AppColors.mintSoft;
      trailing = Icons.check_circle_rounded;
    } else if (checked && selected) {
      border = AppColors.coral;
      background = AppColors.coralSoft;
      trailing = Icons.cancel_rounded;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: border,
            width: selected || (checked && index == correctIndex) ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 33,
              height: 33,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: border.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Text(
                String.fromCharCode(65 + index),
                style: TextStyle(
                  color: selected || (checked && index == correctIndex)
                      ? border
                      : AppColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing != null) Icon(trailing, color: border),
          ],
        ),
      ),
    );
  }
}

class _PracticeCompleteSheet extends StatelessWidget {
  const _PracticeCompleteSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: AppColors.amberSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.amber,
              size: 42,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            'Prática concluída!',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 7),
          Text(
            'Você avançou em equações do 1º grau.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              StatPill(
                icon: Icons.check_circle_rounded,
                value: '2/3',
                label: 'acertos',
                color: AppColors.mint,
              ),
              SizedBox(width: 10),
              StatPill(
                icon: Icons.stars_rounded,
                value: '+60',
                label: 'XP ganho',
                color: AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Voltar para minha trilha'),
          ),
        ],
      ),
    );
  }
}
