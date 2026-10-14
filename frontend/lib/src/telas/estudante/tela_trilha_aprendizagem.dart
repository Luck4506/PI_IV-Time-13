part of '../../telas_estudante.dart';

class LearningTrailScreen extends StatelessWidget {
  const LearningTrailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageFrame(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppMark(compact: true),
                  const SizedBox(height: 26),
                  const SectionHeader(
                    title: 'Sua trilha',
                    subtitle: 'Recalculada hoje com base no seu desempenho',
                  ),
                  const SizedBox(height: 18),
                  SurfaceCard(
                    color: const Color(0xFFEFF3FF),
                    borderColor: const Color(0xFFDCE3FF),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Priorizamos equações porque esse tema destrava 3 assuntos à frente.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _TrailSectionTitle(
                    number: '01',
                    title: 'Fortalecer a base',
                    detail: 'Matemática · 45% concluído',
                  ),
                  const SizedBox(height: 16),
                  _TrailNode(
                    status: _TrailStatus.done,
                    icon: Icons.play_lesson_outlined,
                    title: 'Relembrando expressões',
                    detail: 'Resumo · 5 min',
                    onTap: () => Navigator.pushNamed(
                      context,
                      MaterialDetailScreen.route,
                    ),
                  ),
                  _TrailConnector(done: true),
                  _TrailNode(
                    status: _TrailStatus.current,
                    icon: Icons.quiz_outlined,
                    title: 'Equações do 1º grau',
                    detail: 'Prática adaptativa · 8 questões',
                    onTap: () =>
                        Navigator.pushNamed(context, PracticeScreen.route),
                  ),
                  const _TrailConnector(done: false),
                  _TrailNode(
                    status: _TrailStatus.locked,
                    icon: Icons.calculate_outlined,
                    title: 'Problemas com equações',
                    detail: 'Desbloqueia após a prática',
                    onTap: () => showPendingFeature(context),
                  ),
                  const SizedBox(height: 30),
                  const _TrailSectionTitle(
                    number: '02',
                    title: 'Conectar ideias',
                    detail: 'Funções · próximo módulo',
                  ),
                  const SizedBox(height: 16),
                  _TrailNode(
                    status: _TrailStatus.locked,
                    icon: Icons.show_chart_rounded,
                    title: 'Introdução às funções',
                    detail: 'Resumo visual · 6 min',
                    onTap: () => showPendingFeature(context),
                  ),
                  const _TrailConnector(done: false),
                  _TrailNode(
                    status: _TrailStatus.locked,
                    icon: Icons.grid_on_rounded,
                    title: 'Leitura de gráficos',
                    detail: 'Prática · 10 questões',
                    onTap: () => showPendingFeature(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailSectionTitle extends StatelessWidget {
  const _TrailSectionTitle({
    required this.number,
    required this.title,
    required this.detail,
  });
  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              Text(detail, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

enum _TrailStatus { done, current, locked }

class _TrailNode extends StatelessWidget {
  const _TrailNode({
    required this.status,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });
  final _TrailStatus status;
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      _TrailStatus.done => AppColors.mint,
      _TrailStatus.current => AppColors.primary,
      _TrailStatus.locked => const Color(0xFF98A2B3),
    };
    return SurfaceCard(
      onTap: status == _TrailStatus.locked ? null : onTap,
      color: status == _TrailStatus.current
          ? const Color(0xFFF4F6FF)
          : AppColors.white,
      borderColor: status == _TrailStatus.current
          ? const Color(0xFFB8C6FF)
          : AppColors.border,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              status == _TrailStatus.done
                  ? Icons.check_rounded
                  : status == _TrailStatus.locked
                  ? Icons.lock_outline_rounded
                  : icon,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (status == _TrailStatus.current)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'PRÓXIMO PASSO',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: status == _TrailStatus.locked
                        ? AppColors.muted
                        : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (status != _TrailStatus.locked)
            Icon(Icons.chevron_right_rounded, color: color),
        ],
      ),
    );
  }
}

class _TrailConnector extends StatelessWidget {
  const _TrailConnector({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 43),
      child: Container(
        width: 2,
        height: 24,
        color: done ? AppColors.mint : AppColors.border,
      ),
    );
  }
}
