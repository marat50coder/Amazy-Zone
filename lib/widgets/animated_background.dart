import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Full-bleed background: the artwork plus floating glowing embers that drift
/// upward. Pure Flutter, no plugins.
class AnimatedGameBackground extends StatefulWidget {
  const AnimatedGameBackground({super.key, required this.child});
  final Widget child;

  @override
  State<AnimatedGameBackground> createState() => _AnimatedGameBackgroundState();
}

class _AnimatedGameBackgroundState extends State<AnimatedGameBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Ember> _embers = <_Ember>[];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    for (int i = 0; i < 24; i++) {
      _embers.add(_Ember.random(_rng));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          'assets/Amazy_Zone_gameplay_assets/background_game.webp',
          fit: BoxFit.cover,
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, _) {
            return CustomPaint(
              painter: _EmberPainter(
                embers: _embers,
                t: _controller.value,
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _Ember {
  _Ember({
    required this.x,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.wobble,
  });

  factory _Ember.random(Random r) => _Ember(
        x: r.nextDouble(),
        radius: 1.4 + r.nextDouble() * 3.0,
        speed: 0.35 + r.nextDouble() * 0.65,
        phase: r.nextDouble(),
        wobble: 0.012 + r.nextDouble() * 0.03,
      );

  final double x; // 0..1 of width
  final double radius;
  final double speed;
  final double phase; // 0..1 time offset
  final double wobble;
}

class _EmberPainter extends CustomPainter {
  _EmberPainter({required this.embers, required this.t});
  final List<_Ember> embers;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint();
    for (final _Ember e in embers) {
      final double progress = (t * e.speed + e.phase) % 1.0;
      final double y = size.height * (1 - progress);
      final double x = size.width *
          (e.x + e.wobble * sin((progress + e.phase) * 2 * pi * 2));
      final double alpha = (1 - progress).clamp(0.0, 1.0);
      p
        ..color = AmazyTheme.accentOrangeGlow.withValues(alpha: 0.35 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, e.radius * 1.4);
      canvas.drawCircle(Offset(x, y), e.radius * 2, p);
      p
        ..color = Colors.white.withValues(alpha: 0.85 * alpha)
        ..maskFilter = null;
      canvas.drawCircle(Offset(x, y), e.radius * 0.6, p);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => true;
}
