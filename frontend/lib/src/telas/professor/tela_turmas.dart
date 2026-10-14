part of '../../telas_professor.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  String query = '';
  bool matches(String name) => name.toLowerCase().contains(query);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageFrame(
          maxWidth: 840,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppMark(compact: true),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Minhas turmas',
                subtitle: '3 turmas · 92 estudantes',
                action: IconButton.filled(
                  onPressed: () => showPendingFeature(context),
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) =>
                    setState(() => query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Buscar turma',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => showPendingFeature(context),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (!ClassInfo.samples.any((item) => matches(item.name)))
                const Text('Nenhuma turma encontrada.'),
              if (matches('3º A'))
                _ClassCard(
                  name: '3º A',
                  subject: 'Matemática · Ensino Médio',
                  students: 31,
                  active: 26,
                  average: .68,
                  alert: '14 precisam de reforço',
                  color: AppColors.primary,
                  onTap: () => Navigator.pushNamed(
                    context,
                    ClassDetailScreen.route,
                    arguments: ClassInfo.samples[0],
                  ),
                ),
              const SizedBox(height: 14),
              if (matches('3º B'))
                _ClassCard(
                  name: '3º B',
                  subject: 'Matemática · Ensino Médio',
                  students: 29,
                  active: 23,
                  average: .73,
                  alert: '5 precisam de reforço',
                  color: AppColors.mint,
                  onTap: () => Navigator.pushNamed(
                    context,
                    ClassDetailScreen.route,
                    arguments: ClassInfo.samples[1],
                  ),
                ),
              const SizedBox(height: 14),
              if (matches('2º A'))
                _ClassCard(
                  name: '2º A',
                  subject: 'Matemática · Ensino Médio',
                  students: 32,
                  active: 28,
                  average: .77,
                  alert: '3 precisam de reforço',
                  color: AppColors.amber,
                  onTap: () => Navigator.pushNamed(
                    context,
                    ClassDetailScreen.route,
                    arguments: ClassInfo.samples[2],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.name,
    required this.subject,
    required this.students,
    required this.active,
    required this.average,
    required this.alert,
    required this.color,
    required this.onTap,
  });
  final String name;
  final String subject;
  final int students;
  final int active;
  final double average;
  final String alert;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      subject,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(value: '$students', label: 'estudantes'),
              ),
              Expanded(
                child: _MiniMetric(value: '$active', label: 'ativos'),
              ),
              Expanded(
                child: _MiniMetric(
                  value: '${(average * 100).round()}%',
                  label: 'média',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ProgressBar(value: average, color: color, height: 7),
          const SizedBox(height: 12),
          TagChip(
            label: alert,
            icon: Icons.priority_high_rounded,
            color: AppColors.coral,
            backgroundColor: AppColors.coralSoft,
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
