import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

class ContentTrailMap extends StatelessWidget {
  const ContentTrailMap({
    super.key,
    required this.stages,
    required this.onOpen,
  });
  final List<Map<String, dynamic>> stages;
  final ValueChanged<Map<String, dynamic>> onOpen;
  static const stepHeight = 202.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final cardWidth = math.min(230.0, width * .58);
      final height = stages.length * stepHeight + 20;
      return SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _TrailLine(stages))),
            for (var i = 0; i < stages.length; i++)
              Positioned(
                top: 10 + i * stepHeight,
                left: width * (i.isEven ? .30 : .70) - cardWidth / 2,
                width: cardWidth,
                child: _ContentNode(
                  stage: stages[i],
                  number: i + 1,
                  onTap: stages[i]['status'] == 'bloqueada'
                      ? null
                      : () => onOpen(stages[i]),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _ContentNode extends StatelessWidget {
  const _ContentNode({
    required this.stage,
    required this.number,
    required this.onTap,
  });
  final Map<String, dynamic> stage;
  final int number;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = stage['status'] == 'bloqueada';
    final done = stage['status'] == 'concluida';
    final errors = (stage['erros'] as int?) ?? 0;
    final review = errors > 0 && !locked;
    final color = review
        ? const Color(0xFFB54708)
        : done
        ? AppColors.mint
        : locked
        ? const Color(0xFFC9CEDB)
        : AppColors.primary;
    final label = done
        ? 'Concluído'
        : locked
        ? 'Conclua a etapa anterior'
        : 'Seu próximo passo';
    return Semantics(
      button: true,
      enabled: !locked,
      label:
          'Etapa $number: ${stage['nome']}. $label${review ? '. Revisar: $errors erros' : ''}',
      child: Tooltip(
        message: stage['nome'] as String,
        child: InkWell(
          key: Key('content-node-${stage['id']}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: Colors.white, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: locked ? .12 : .25),
                        offset: const Offset(0, 6),
                        blurRadius: 0,
                      ),
                      if (!locked && !done)
                        BoxShadow(
                          color: color.withValues(alpha: .14),
                          blurRadius: 20,
                          spreadRadius: 6,
                        ),
                    ],
                  ),
                  child: Icon(
                    review
                        ? Icons.replay_rounded
                        : done
                        ? Icons.check_rounded
                        : locked
                        ? Icons.lock_rounded
                        : Icons.auto_stories_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'ETAPA ${number.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: locked ? AppColors.muted : color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  color: AppColors.surface,
                  child: Text(
                    stage['nome'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.3,
                      color: locked ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  locked
                      ? label
                      : review
                      ? 'Revisar · $errors ${errors == 1 ? 'erro' : 'erros'}'
                      : done
                      ? 'Etapa concluída'
                      : 'Material + prática',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: locked ? AppColors.muted : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailLine extends CustomPainter {
  _TrailLine(this.stages);
  final List<Map<String, dynamic>> stages;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < stages.length - 1; i++) {
      final a = Offset(
        size.width * (i.isEven ? .30 : .70),
        56 + i * ContentTrailMap.stepHeight,
      );
      final b = Offset(
        size.width * (i.isEven ? .70 : .30),
        56 + (i + 1) * ContentTrailMap.stepHeight,
      );
      final path = Path()
        ..moveTo(a.dx + (i.isEven ? 38 : -38), a.dy)
        ..cubicTo(
          size.width * .5,
          a.dy,
          size.width * .5,
          b.dy,
          b.dx + (i.isEven ? -38 : 38),
          b.dy,
        );
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 9;
      if (stages[i]['status'] == 'concluida') {
        canvas.drawPath(
          path,
          paint
            ..color =
                ((stages[i]['erros'] as int? ?? 0) > 0
                        ? AppColors.amber
                        : AppColors.mint)
                    .withValues(alpha: .55),
        );
      } else {
        paint.color = const Color(0xFFDCE1EC);
        for (final metric in path.computeMetrics()) {
          for (double distance = 0; distance < metric.length; distance += 21) {
            canvas.drawPath(
              metric.extractPath(
                distance,
                math.min(distance + 11, metric.length),
              ),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailLine oldDelegate) =>
      oldDelegate.stages != stages;
}
