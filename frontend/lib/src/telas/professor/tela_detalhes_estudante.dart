part of '../../telas_professor.dart';

class StudentProfileData {
  const StudentProfileData({
    required this.initials,
    required this.name,
    required this.className,
    required this.lastActivity,
    required this.listDetail,
    required this.accuracy,
    required this.studyTime,
    required this.accentColor,
    required this.insightTitle,
    required this.insight,
    required this.topics,
    required this.trail,
  });

  final String initials;
  final String name;
  final String className;
  final String lastActivity;
  final String listDetail;
  final int accuracy;
  final String studyTime;
  final Color accentColor;
  final String insightTitle;
  final String insight;
  final List<StudentTopicData> topics;
  final List<StudentTrailData> trail;
}

class StudentTopicData {
  const StudentTopicData({
    required this.name,
    required this.value,
    required this.status,
    required this.color,
  });

  final String name;
  final double value;
  final String status;
  final Color color;
}

class StudentTrailData {
  const StudentTrailData({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
}

abstract final class StudentProfiles {
  static const joao = StudentProfileData(
    initials: 'JS',
    name: 'João Souza',
    className: '3º A · Matemática',
    lastActivity: 'há 9 dias',
    listDetail: '9 dias sem atividade',
    accuracy: 42,
    studyTime: '1h12',
    accentColor: AppColors.coral,
    insightTitle: 'Intervenção recomendada',
    insight: 'João reduziu o ritmo de estudos e apresenta dificuldade em equações e funções. Uma retomada guiada pode ajudá-lo a recuperar a sequência.',
    topics: [
      StudentTopicData(
        name: 'Razão e proporção',
        value: .55,
        status: 'Em desenvolvimento',
        color: AppColors.amber,
      ),
      StudentTopicData(
        name: 'Equações do 1º grau',
        value: .38,
        status: 'Precisa de reforço',
        color: AppColors.coral,
      ),
      StudentTopicData(
        name: 'Funções',
        value: .34,
        status: 'Precisa de reforço',
        color: AppColors.coral,
      ),
    ],
    trail: [
      StudentTrailData(
        icon: Icons.check_circle_rounded,
        title: 'Expressões algébricas',
        detail: 'Concluído · 61%',
        color: AppColors.mint,
      ),
      StudentTrailData(
        icon: Icons.pause_circle_filled_rounded,
        title: 'Equações do 1º grau',
        detail: 'Pausado · 1 de 4 etapas',
        color: AppColors.coral,
      ),
      StudentTrailData(
        icon: Icons.lock_outline_rounded,
        title: 'Problemas com equações',
        detail: 'Próximo conteúdo',
        color: AppColors.muted,
      ),
    ],
  );

  static const marina = StudentProfileData(
    initials: 'MC',
    name: 'Marina Costa',
    className: '3º A · Matemática',
    lastActivity: 'ativa hoje',
    listDetail: 'Foco em equações',
    accuracy: 68,
    studyTime: '4h18',
    accentColor: AppColors.amber,
    insightTitle: 'Ponto de atenção',
    insight: 'Marina melhorou em operações, mas ainda erra ao transformar problemas em equações.',
    topics: [
      StudentTopicData(
        name: 'Razão e proporção',
        value: .82,
        status: 'Domínio consolidado',
        color: AppColors.mint,
      ),
      StudentTopicData(
        name: 'Equações do 1º grau',
        value: .46,
        status: 'Em desenvolvimento',
        color: AppColors.coral,
      ),
      StudentTopicData(
        name: 'Funções',
        value: .58,
        status: 'Revisão programada',
        color: AppColors.amber,
      ),
    ],
    trail: [
      StudentTrailData(
        icon: Icons.check_circle_rounded,
        title: 'Expressões algébricas',
        detail: 'Concluído · 86%',
        color: AppColors.mint,
      ),
      StudentTrailData(
        icon: Icons.play_circle_fill_rounded,
        title: 'Equações do 1º grau',
        detail: 'Em andamento · 2 de 4 etapas',
        color: AppColors.primary,
      ),
      StudentTrailData(
        icon: Icons.lock_outline_rounded,
        title: 'Problemas com equações',
        detail: 'Próximo conteúdo',
        color: AppColors.muted,
      ),
    ],
  );

  static const rafael = StudentProfileData(
    initials: 'RL',
    name: 'Rafael Lima',
    className: '3º A · Matemática',
    lastActivity: 'ativo há 22 min',
    listDetail: 'Evolução consistente',
    accuracy: 84,
    studyTime: '5h42',
    accentColor: AppColors.mint,
    insightTitle: 'Boa evolução',
    insight: 'Rafael mantém uma sequência consistente e já pode avançar para desafios de maior complexidade em funções.',
    topics: [
      StudentTopicData(
        name: 'Razão e proporção',
        value: .91,
        status: 'Domínio consolidado',
        color: AppColors.mint,
      ),
      StudentTopicData(
        name: 'Equações do 1º grau',
        value: .83,
        status: 'Domínio consolidado',
        color: AppColors.mint,
      ),
      StudentTopicData(
        name: 'Funções',
        value: .72,
        status: 'Em desenvolvimento',
        color: AppColors.primary,
      ),
    ],
    trail: [
      StudentTrailData(
        icon: Icons.check_circle_rounded,
        title: 'Expressões algébricas',
        detail: 'Concluído · 94%',
        color: AppColors.mint,
      ),
      StudentTrailData(
        icon: Icons.check_circle_rounded,
        title: 'Equações do 1º grau',
        detail: 'Concluído · 88%',
        color: AppColors.mint,
      ),
      StudentTrailData(
        icon: Icons.play_circle_fill_rounded,
        title: 'Introdução às funções',
        detail: 'Em andamento · 3 de 5 etapas',
        color: AppColors.primary,
      ),
    ],
  );

  static const beatriz = StudentProfileData(
    initials: 'BL',
    name: 'Beatriz Lopes',
    className: '3º A · Matemática',
    lastActivity: 'ativa há 2 h',
    listDetail: 'Trilha em dia',
    accuracy: 88,
    studyTime: '6h05',
    accentColor: AppColors.mint,
    insightTitle: 'Desempenho em destaque',
    insight: 'Beatriz está com a trilha em dia e demonstra domínio consistente. Considere propor uma atividade de aprofundamento.',
    topics: [
      StudentTopicData(
        name: 'Razão e proporção',
        value: .94,
        status: 'Domínio consolidado',
        color: AppColors.mint,
      ),
      StudentTopicData(
        name: 'Equações do 1º grau',
        value: .87,
        status: 'Domínio consolidado',
        color: AppColors.mint,
      ),
      StudentTopicData(
        name: 'Funções',
        value: .82,
        status: 'Domínio consolidado',
        color: AppColors.mint,
      ),
    ],
    trail: [
      StudentTrailData(
        icon: Icons.check_circle_rounded,
        title: 'Expressões algébricas',
        detail: 'Concluído · 96%',
        color: AppColors.mint,
      ),
      StudentTrailData(
        icon: Icons.check_circle_rounded,
        title: 'Equações do 1º grau',
        detail: 'Concluído · 91%',
        color: AppColors.mint,
      ),
      StudentTrailData(
        icon: Icons.play_circle_fill_rounded,
        title: 'Problemas com equações',
        detail: 'Em andamento · 2 de 3 etapas',
        color: AppColors.primary,
      ),
    ],
  );
}

class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key, this.student = StudentProfiles.marina});

  static const route = '/professor/estudante';

  final StudentProfileData student;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do aluno'),
        actions: [
          IconButton(
            tooltip: 'Mais opções',
            onPressed: () => showPendingFeature(context),
            icon: const Icon(Icons.more_horiz_rounded),
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
                _StudentHeader(student: student),
                const SizedBox(height: 24),
                Row(
                  children: [
                    StatPill(
                      icon: Icons.task_alt_rounded,
                      value: '${student.accuracy}%',
                      label: 'acertos',
                      color: student.accentColor,
                    ),
                    const SizedBox(width: 10),
                    StatPill(
                      icon: Icons.schedule_rounded,
                      value: student.studyTime,
                      label: 'estudo',
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _StudentInsight(student: student),
                const SizedBox(height: 26),
                const SectionHeader(
                  title: 'Domínio por assunto',
                  subtitle: 'Desempenho individual nas atividades',
                ),
                const SizedBox(height: 14),
                for (var index = 0; index < student.topics.length; index++) ...[
                  _TopicMastery(
                    name: student.topics[index].name,
                    value: student.topics[index].value,
                    students: student.topics[index].status,
                    color: student.topics[index].color,
                  ),
                  if (index < student.topics.length - 1)
                    const SizedBox(height: 11),
                ],
                const SizedBox(height: 26),
                const SectionHeader(
                  title: 'Trilha atual',
                  subtitle: 'Progresso nos conteúdos recomendados',
                ),
                const SizedBox(height: 14),
                SurfaceCard(
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < student.trail.length;
                        index++
                      ) ...[
                        _StudentTrailRow(item: student.trail[index]),
                        if (index < student.trail.length - 1)
                          const Divider(height: 24),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: () => showPendingFeature(context),
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Adicionar observação pedagógica'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.student});

  final StudentProfileData student;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final identity = Row(
          children: [
            InitialAvatar(
              initials: student.initials,
              size: 68,
              color: student.accentColor,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${student.className} · ${student.lastActivity}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        );

        final messageButton = OutlinedButton.icon(
          onPressed: () => showPendingFeature(context),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Mensagem'),
        );

        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [identity, const SizedBox(height: 16), messageButton],
          );
        }

        return Row(
          children: [
            Expanded(child: identity),
            const SizedBox(width: 18),
            SizedBox(width: 150, child: messageButton),
          ],
        );
      },
    );
  }
}

class _StudentInsight extends StatelessWidget {
  const _StudentInsight({required this.student});

  final StudentProfileData student;

  @override
  Widget build(BuildContext context) {
    final isPositive = student.accentColor == AppColors.mint;
    final background = isPositive ? AppColors.mintSoft : AppColors.coralSoft;
    final border = isPositive
        ? const Color(0xFFBCE9DD)
        : const Color(0xFFFFCFC4);
    final foreground = isPositive
        ? const Color(0xFF19785F)
        : const Color(0xFFA63F2A);

    return SurfaceCard(
      color: background,
      borderColor: border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.flag_rounded,
            color: student.accentColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.insightTitle,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.insight,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTrailRow extends StatelessWidget {
  const _StudentTrailRow({required this.item});

  final StudentTrailData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(item.icon, color: item.color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
              Text(item.detail, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
