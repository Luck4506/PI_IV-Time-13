part of '../../telas_autenticacao.dart';

class DiagnosticResultScreen extends StatelessWidget {
  const DiagnosticResultScreen({super.key});

  static const route = '/diagnostico/resultado';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageFrame(
            maxWidth: 620,
            padding: const EdgeInsets.fromLTRB(20, 34, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      color: AppColors.mintSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: AppColors.mint,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Text(
                    'Sua primeira trilha está pronta!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Começaremos reforçando os pontos que mais podem destravar sua evolução.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 28),
                SurfaceCard(
                  child: Column(
                    children: const [
                      _ResultSubject(
                        name: 'Matemática',
                        detail: 'Reforçar equações e funções',
                        value: .42,
                        color: AppColors.coral,
                      ),
                      Divider(height: 26),
                      _ResultSubject(
                        name: 'Português',
                        detail: 'Bom domínio de interpretação',
                        value: .76,
                        color: AppColors.primary,
                      ),
                      Divider(height: 26),
                      _ResultSubject(
                        name: 'Biologia',
                        detail: 'Avançar em citologia',
                        value: .64,
                        color: AppColors.mint,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFFB87A00),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sua trilha será recalculada conforme você aprende. Nada fica preso a este resultado.',
                          style: TextStyle(
                            color: Color(0xFF805900),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    StudentShell.route,
                    (route) => false,
                  ),
                  child: const Text('Conhecer minha trilha'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultSubject extends StatelessWidget {
  const _ResultSubject({
    required this.name,
    required this.detail,
    required this.value,
    required this.color,
  });
  final String name;
  final String detail;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name, style: Theme.of(context).textTheme.titleMedium),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(detail, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 9),
        ProgressBar(value: value, color: color),
      ],
    );
  }
}
