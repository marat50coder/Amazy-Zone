import 'package:flutter/material.dart';

import '../game/paylines.dart';
import '../theme.dart';
import 'info_scaffold.dart';

/// Shows all 25 paylines on a 5x4 grid thumbnail. Each tile has its own colour
/// (reused from the live payline overlay) and the line is drawn as a glowing
/// polyline so players can study the shapes.
class PaylinesScreen extends StatelessWidget {
  const PaylinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoScaffold(
      title: 'PAYLINES',
      subtitle: '25 ways to win • 5 reels × 4 rows',
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 5 / 4.6,
        ),
        itemCount: kPaylines.length,
        itemBuilder: (BuildContext context, int i) {
          final Payline line = kPaylines[i];
          return _PaylineCard(line: line);
        },
      ),
    );
  }
}

class _PaylineCard extends StatelessWidget {
  const _PaylineCard({required this.line});
  final Payline line;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(line.color);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.75),
          width: 1.3,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 0.5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${line.index}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'LINE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: AspectRatio(
              aspectRatio: 5 / 4,
              child: CustomPaint(
                painter: _MiniGridPainter(rows: line.rows, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  _MiniGridPainter({required this.rows, required this.color});
  final List<int> rows;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double cellW = size.width / kReels;
    final double cellH = size.height / kRows;

    // Grid cells.
    final Paint cellFill = Paint()
      ..color = AmazyTheme.panelDark.withValues(alpha: 0.9);
    final Paint cellBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.08);
    for (int r = 0; r < kReels; r++) {
      for (int row = 0; row < kRows; row++) {
        final Rect rect = Rect.fromLTWH(
          r * cellW + 1,
          row * cellH + 1,
          cellW - 2,
          cellH - 2,
        );
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)), cellFill);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)),
            cellBorder);
      }
    }

    // Highlighted cells + line.
    final Path path = Path();
    for (int r = 0; r < kReels; r++) {
      final double cx = r * cellW + cellW / 2;
      final double cy = rows[r] * cellH + cellH / 2;
      if (r == 0) {
        path.moveTo(cx, cy);
      } else {
        path.lineTo(cx, cy);
      }
      final Rect hit = Rect.fromLTWH(
        r * cellW + 1,
        rows[r] * cellH + 1,
        cellW - 2,
        cellH - 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(hit, const Radius.circular(3)),
        Paint()..color = color.withValues(alpha: 0.35),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );

    // Dots at line vertices.
    for (int r = 0; r < kReels; r++) {
      final double cx = r * cellW + cellW / 2;
      final double cy = rows[r] * cellH + cellH / 2;
      canvas.drawCircle(
          Offset(cx, cy), 2.8, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(cx, cy), 1.4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_MiniGridPainter old) => false;
}
