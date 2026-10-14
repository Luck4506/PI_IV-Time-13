part of '../../telas_autenticacao.dart';

class DiagnosticQuizScreen extends StatefulWidget {
  const DiagnosticQuizScreen({super.key});

  static const route = '/diagnostico/questoes';

  @override
  State<DiagnosticQuizScreen> createState() => _DiagnosticQuizScreenState();
}

class _DiagnosticQuizScreenState extends State<DiagnosticQuizScreen> {
  int current = 0;
  int? selected;

  static const questions = [
    (
      'Matemática',
      'Qual é o valor de x na equação 3x + 6 = 21?',
      ['3', '5', '7', '9'],
    ),
    (
      'Português',
      'Em “A cidade acordou apressada”, qual figura de linguagem aparece?',
      ['Metáfora', 'Personificação', 'Hipérbole', 'Antítese'],
    ),
    (
      'Biologia',
      'Qual estrutura celular é responsável pela produção de energia?',
      ['Ribossomo', 'Lisossomo', 'Mitocôndria', 'Núcleo'],
    ),
  ];

  void _next() {
    if (current == questions.length - 1) {
      Navigator.pushReplacementNamed(context, DiagnosticResultScreen.route);
      return;
    }
    setState(() {
      current++;
      selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[current];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico inicial'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '${current + 1} de ${questions.length}',
                style: const TextStyle(fontWeight: FontWeight.w800),
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
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TagChip(label: question.$1, icon: Icons.book_outlined),
                      const SizedBox(height: 18),
                      Text(
                        question.$2,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      ...List.generate(question.$3.length, (index) {
                        final active = selected == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => setState(() => selected = index),
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFFE9EEFF)
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: active ? 1.6 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.primary
                                          : AppColors.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      String.fromCharCode(65 + index),
                                      style: TextStyle(
                                        color: active
                                            ? AppColors.white
                                            : AppColors.ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Text(
                                      question.$3[index],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: FilledButton(
                    onPressed: selected == null ? null : _next,
                    child: Text(
                      current == questions.length - 1
                          ? 'Ver meu resultado'
                          : 'Continuar',
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
