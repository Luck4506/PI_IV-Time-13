part of '../../telas_estudante.dart';

class MaterialDetailScreen extends StatelessWidget {
  const MaterialDetailScreen({super.key});

  static const route = '/aluno/material';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material de apoio'),
        actions: [
          IconButton(
            onPressed: () => showPendingFeature(context),
            icon: const Icon(Icons.bookmark_border_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageFrame(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 190,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF355FD8), AppColors.sky],
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.show_chart_rounded,
                      color: AppColors.white,
                      size: 90,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TagChip(label: 'MATEMÁTICA'),
                    TagChip(
                      label: '6 MIN',
                      icon: Icons.schedule_rounded,
                      color: AppColors.mint,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Funções: uma relação entre valores',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Entenda como uma entrada se transforma em uma saída e aprenda a reconhecer isso em tabelas e gráficos.',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 26),
                Text(
                  'A ideia principal',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Uma função é como uma máquina: você fornece um valor, aplica uma regra e recebe um resultado. Cada entrada permitida produz uma única saída.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 18),
                SurfaceCard(
                  color: const Color(0xFFF0F3FF),
                  borderColor: const Color(0xFFDCE3FF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EXEMPLO RESOLVIDO',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'f(x) = 2x + 1',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Se x = 3, então f(3) = 2 · 3 + 1 = 7.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, PracticeScreen.route),
                  icon: const Icon(Icons.quiz_outlined),
                  label: const Text('Testar o que aprendi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
