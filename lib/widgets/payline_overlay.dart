import 'dart:math';

import 'package:flutter/material.dart';

import '../game/paylines.dart';
import '../game/spin_result.dart';
import '../theme.dart';

/// Paints the winning polylines above the grid as glowing paths that pulse.
class PaylineOverlay extends StatelessWidget {
  const PaylineOverlay({
    super.key,
    required this.cellWidth,
    required this.cellHeight,
    required this.wins,
    required this.pulse,
  });

  final double cellWidth;
  final double cellHeight;
  final List<LineWin> wins;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (BuildContext context, _) {
          return CustomPaint(
            size: Size(cellWidth * kReels, cellHeight * kRows),
            painter: _PaylinePainter(
              cellWidth: cellWidth,
              cellHeight: cellHeight,
              wins: wins,
              t: pulse.value,
            ),
          );
        },
      ),
    );
  }
}

class _PaylinePainter extends CustomPainter {
  _PaylinePainter({
    required this.cellWidth,
    required this.cellHeight,
    required this.wins,
    required this.t,
  });

  final double cellWidth;
  final double cellHeight;
  final List<LineWin> wins;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final LineWin w in wins) {
      final Path path = Path();
      for (int r = 0; r < w.matchCount; r++) {
        final double cx = cellWidth * r + cellWidth / 2;
        final double cy = cellHeight * w.rows[r] + cellHeight / 2;
        if (r == 0) {
          path.moveTo(cx, cy);
        } else {
          path.lineTo(cx, cy);
        }
      }

      final Color base = Color(w.color);
      final double pulse = 0.5 + 0.5 * sin(t * 2 * pi);

      // Outer glow
      final Paint outer = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14 + 6 * pulse
        ..color = base.withValues(alpha: 0.35 + 0.25 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(path, outer);

      // Core line
      final Paint core = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 + 2 * pulse
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.95);
      canvas.drawPath(path, core);

      // Win amount for THIS line, sitting on its first symbol.
      final double tagX = cellWidth * 0.04;
      final double tagY = cellHeight * w.rows[0] + cellHeight * 0.06;
      final TextPainter tp = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: formatFans(w.amount),
          style: TextStyle(
            color: Colors.white,
            fontSize: cellHeight * 0.16,
            fontWeight: FontWeight.w900,
            shadows: <Shadow>[
              Shadow(color: base, blurRadius: 12),
              const Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        ),
      )..layout();
      final Rect tagRect = Rect.fromLTWH(
        tagX,
        tagY,
        tp.width + 10,
        tp.height + 4,
      );
      final Paint tagBg = Paint()
        ..color = base.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(tagRect, const Radius.circular(6)),
        tagBg,
      );
      tp.paint(canvas, Offset(tagX + 5, tagY + 2));
    }
  }

  @override
  bool shouldRepaint(_PaylinePainter old) =>
      old.wins != wins ||
      old.t != t ||
      old.cellWidth != cellWidth ||
      old.cellHeight != cellHeight;
}
