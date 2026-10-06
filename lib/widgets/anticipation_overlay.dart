import 'dart:math';

import 'package:flutter/material.dart';

import '../game/paylines.dart';

/// Full-grid overlay that highlights the "anticipated" reel during a bonus
/// hunt. Draws:
///   * a semi-transparent dark wash across all other reels
///   * a bright pulsing golden glow framing the active reel
///   * vertical light pillars inside the active reel
///   * animated spark particles rising on both sides
///
/// Visually inspired by Pragmatic Play's Zeus-vs-Hades anticipation sequence.
class AnticipationOverlay extends StatefulWidget {
  const AnticipationOverlay({
    super.key,
    required this.cellWidth,
    required this.cellHeight,
    required this.activeReel,
  });

  final double cellWidth;
  final double cellHeight;

  /// Reel index that is currently in the anticipation state (0..kReels-1).
  /// null → overlay fades out.
  final int? activeReel;

  @override
  State<AnticipationOverlay> createState() => _AnticipationOverlayState();
}

class _AnticipationOverlayState extends State<AnticipationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  late final AnimationController _show = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    reverseDuration: const Duration(milliseconds: 450),
  );

  final List<_Spark> _sparks = List<_Spark>.generate(28, (int i) {
    final Random r = Random(i * 31 + 7);
    return _Spark.random(r);
  });

  @override
  void didUpdateWidget(AnticipationOverlay old) {
    super.didUpdateWidget(old);
    if (widget.activeReel != null) {
      _show.forward();
    } else {
      _show.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.activeReel != null) {
      _show.forward();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _show.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_idle, _show]),
        builder: (BuildContext context, _) {
          if (_show.value <= 0.001 && widget.activeReel == null) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            size: Size(
                widget.cellWidth * kReels, widget.cellHeight * kRows),
            painter: _AnticipationPainter(
              cellWidth: widget.cellWidth,
              cellHeight: widget.cellHeight,
              activeReel: widget.activeReel,
              intensity: _show.value,
              t: _idle.value,
              sparks: _sparks,
            ),
          );
        },
      ),
    );
  }
}

class _Spark {
  _Spark({
    required this.sideLeft,
    required this.yPhase,
    required this.radius,
    required this.speed,
  });

  factory _Spark.random(Random r) => _Spark(
        sideLeft: r.nextBool(),
        yPhase: r.nextDouble(),
        radius: 1.3 + r.nextDouble() * 2.4,
        speed: 0.4 + r.nextDouble() * 0.6,
      );

  final bool sideLeft;
  final double yPhase;
  final double radius;
  final double speed;
}

class _AnticipationPainter extends CustomPainter {
  _AnticipationPainter({
    required this.cellWidth,
    required this.cellHeight,
    required this.activeReel,
    required this.intensity,
    required this.t,
    required this.sparks,
  });

  final double cellWidth;
  final double cellHeight;
  final int? activeReel;
  final double intensity; // 0..1 (overlay show amount)
  final double t; // 0..1 (idle loop)
  final List<_Spark> sparks;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final int reel = activeReel ?? 0;
    final double x0 = reel * cellWidth;
    final Rect activeRect = Rect.fromLTWH(x0, 0, cellWidth, size.height);

    // 1) Dim mask: paint black over the full grid, then "punch" the active
    //    reel back to transparent using srcOut blend. This produces a soft
    //    spotlight exclusively around the active column.
    final double dimAlpha = 0.55 * intensity;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: dimAlpha),
    );
    final Paint cut = Paint()
      ..blendMode = BlendMode.dstOut
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const <Color>[
          Color(0x00000000),
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0x00000000),
        ],
        stops: const <double>[0.0, 0.18, 0.82, 1.0],
      ).createShader(activeRect.inflate(cellWidth * 0.25));
    canvas.drawRect(activeRect.inflate(cellWidth * 0.25), cut);
    canvas.restore();

    // 2) Golden pulsing frame around the active reel.
    final double pulse = 0.6 + 0.4 * sin(t * 2 * pi);
    final double glowAlpha = (0.75 + 0.25 * pulse) * intensity;
    final Rect frameRect = activeRect.deflate(3);

    final Paint outerGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..color = const Color(0xFFFF9A28).withValues(alpha: 0.55 * glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(10)),
      outerGlow,
    );

    final Paint midGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0xFFFFCB5A).withValues(alpha: 0.9 * glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(8)),
      midGlow,
    );

    final Paint core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = Colors.white.withValues(alpha: 0.95 * intensity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(6)),
      core,
    );

    // 3) Vertical light pillars inside the reel.
    final Rect pillarRect = Rect.fromLTWH(
      activeRect.left + cellWidth * 0.06,
      activeRect.top + 2,
      activeRect.width - cellWidth * 0.12,
      activeRect.height - 4,
    );
    final Paint pillar = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          const Color(0xFFFFC37A)
              .withValues(alpha: 0.0),
          const Color(0xFFFF8A1C)
              .withValues(alpha: 0.18 * intensity * (0.7 + 0.3 * pulse)),
          const Color(0xFFFFC37A)
              .withValues(alpha: 0.0),
        ],
        stops: const <double>[0.0, 0.5, 1.0],
      ).createShader(pillarRect);
    canvas.drawRect(pillarRect, pillar);

    // 4) Rising spark particles on both sides of the active reel.
    for (final _Spark s in sparks) {
      final double tt = (t * s.speed + s.yPhase) % 1.0;
      final double y = size.height * (1 - tt) + 10;
      final double x = s.sideLeft
          ? activeRect.left - 6 + sin((tt + s.yPhase) * 6.28) * 4
          : activeRect.right + 6 + sin((tt + s.yPhase) * 6.28) * 4;
      final double alpha = (1 - tt).clamp(0.0, 1.0) * intensity;
      final Paint p = Paint()
        ..color = const Color(0xFFFFE0A6).withValues(alpha: 0.55 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.radius * 1.4);
      canvas.drawCircle(Offset(x, y), s.radius * 2, p);
      canvas.drawCircle(
        Offset(x, y),
        s.radius * 0.55,
        Paint()..color = Colors.white.withValues(alpha: 0.9 * alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_AnticipationPainter old) =>
      old.activeReel != activeReel ||
      old.intensity != intensity ||
      old.t != t;
}
