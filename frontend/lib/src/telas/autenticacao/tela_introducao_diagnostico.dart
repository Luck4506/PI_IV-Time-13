part of '../../telas_autenticacao.dart';

class DiagnosticIntroScreen extends StatelessWidget {
  const DiagnosticIntroScreen({super.key});

  static const route = '/diagnostico';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, StudentShell.route),
            child: const Text('Fazer depois'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageFrame(
            maxWidth: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EEFF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Vamos descobrir o melhor ponto de partida?',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Responda às questões disponíveis para experimentar a atividade inicial.',

                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 28),
                const _InfoRow(
                  icon: Icons.timer_outlined,
                  title: 'Diagnóstico rápido',
                  subtitle: 'Você pode pausar quando quiser.',
                ),
                const _InfoRow(
                  icon: Icons.tune_rounded,
                  title: 'Uma questão por vez',
                  subtitle: 'Leia com atenção e escolha uma alternativa.',
                ),
                const _InfoRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Confira suas respostas',
                  subtitle: 'A correção aparece quando há gabarito disponível.',
                ),
                const SizedBox(height: 30),
                FilledButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, DiagnosticQuizScreen.route),
                  child: const Text('Começar diagnóstico'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
