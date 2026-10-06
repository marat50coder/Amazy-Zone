import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

enum BigWinTier { big, mega, epic, ultimate }

BigWinTier bigWinTierFromMultiplier(double m) {
  if (m >= 500) return BigWinTier.ultimate;
  if (m >= 100) return BigWinTier.epic;
  if (m >= 40) return BigWinTier.mega;
  return BigWinTier.big;
}

String bigWinTierTitle(BigWinTier t) {
  switch (t) {
    case BigWinTier.big:
      return 'BIG WIN';
    case BigWinTier.mega:
      return 'MEGA WIN';
    case BigWinTier.epic:
      return 'EPIC WIN';
    case BigWinTier.ultimate:
      return 'ULTIMATE WIN';
  }
}

/// Full-screen celebration overlay. Dimmed background, animated title and
/// a counter that smoothly ticks up to the final amount. Tap anywhere to
/// dismiss.
class BigWinOverlay extends StatefulWidget {
  const BigWinOverlay({
    super.key,
    required this.amount,
    required this.multiplier,
  });

  final double amount;
  final double multiplier;

  @override
  State<BigWinOverlay> createState() => _BigWinOverlayState();
}

class _BigWinOverlayState extends State<BigWinOverlay>
    with TickerProviderStateMixin {
  late final BigWinTier _tier = bigWinTierFromMultiplier(widget.multiplier);
  late final AnimationController _countController;
  late final AnimationController _introController;
  late final AnimationController _idleController;
  final Random _rng = Random();

  late final List<_Particle> _particles;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    // Longer count-up for bigger wins.
    final int countMs = switch (_tier) {
      BigWinTier.big => 1800,
      BigWinTier.mega => 2400,
      BigWinTier.epic => 3200,
      BigWinTier.ultimate => 4200,
    };
    _countController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: countMs),
    )..forward().whenComplete(() => setState(() => _finished = true));
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _particles = List<_Particle>.generate(
      switch (_tier) {
        BigWinTier.big => 40,
        BigWinTier.mega => 70,
        BigWinTier.epic => 110,
        BigWinTier.ultimate => 160,
      },
      (_) => _Particle.random(_rng),
    );
  }

  @override
  void dispose() {
    _countController.dispose();
    _introController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  Color get _tierColor {
    switch (_tier) {
      case BigWinTier.big:
        return const Color(0xFFFFC37A);
      case BigWinTier.mega:
        return const Color(0xFFFFD56A);
      case BigWinTier.epic:
        return const Color(0xFFFF6A2A);
      case BigWinTier.ultimate:
        return const Color(0xFFFF3B4A);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in a transparent Material so Text widgets inherit a proper
    // DefaultTextStyle (otherwise Flutter paints the yellow "debug" double
    // underlines you see on raw Text widgets with no Material ancestor).
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          decoration: TextDecoration.none,
          fontFamily: 'Roboto',
        ),
        child: GestureDetector(
      onTap: () {
        if (_finished) {
          Navigator.of(context).pop();
        } else {
          // Skip to final value.
          _countController
            ..stop()
            ..value = 1.0;
          setState(() => _finished = true);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Dim backdrop
          AnimatedBuilder(
            animation: _introController,
            builder: (_, Widget? child) {
              return Container(
                color: Colors.black.withValues(
                  alpha: 0.75 * Curves.easeOut.transform(_introController.value),
                ),
              );
            },
          ),
          // Radial pulse
          AnimatedBuilder(
            animation: _idleController,
            builder: (_, __) {
              final double p = _idleController.value;
              return CustomPaint(
                painter: _RadialPulsePainter(
                  color: _tierColor,
                  t: p,
                ),
              );
            },
          ),
          // Particles
          AnimatedBuilder(
            animation: _idleController,
            builder: (_, __) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  color: _tierColor,
                  t: _idleController.value,
                ),
              );
            },
          ),
          // Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _AnimatedTitle(
                    text: bigWinTierTitle(_tier),
                    color: _tierColor,
                    controller: _introController,
                    idleController: _idleController,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '×${widget.multiplier.toStringAsFixed(1)} TOTAL BET',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _countController,
                    builder: (_, __) {
                      final double v = Curves.easeOutCubic
                          .transform(_countController.value);
                      final double shown = widget.amount * v;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            formatFans(shown),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: Colors.white,
                              shadows: <Shadow>[
                                Shadow(color: _tierColor, blurRadius: 32),
                                const Shadow(color: Colors.black, blurRadius: 6),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            kNoRealMoney,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 36),
                  AnimatedOpacity(
                    opacity: _finished ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: _tierColor.withValues(alpha: 0.9),
                            width: 1.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'TAP TO CONTINUE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}

class _AnimatedTitle extends StatelessWidget {
  const _AnimatedTitle({
    required this.text,
    required this.color,
    required this.controller,
    required this.idleController,
  });

  final String text;
  final Color color;
  final AnimationController controller;
  final AnimationController idleController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[controller, idleController]),
      builder: (_, __) {
        final double intro = Curves.elasticOut.transform(controller.value);
        final double idlePulse =
            1.0 + 0.05 * sin(idleController.value * 2 * pi);
        return Transform.scale(
          scale: (0.5 + 0.5 * intro).clamp(0.0, 1.1) * idlePulse,
          child: Opacity(
            opacity: Curves.easeOut.transform(controller.value),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Colors.white,
                shadows: <Shadow>[
                  Shadow(color: color, blurRadius: 40),
                  Shadow(color: color.withValues(alpha: 0.6), blurRadius: 80),
                  const Shadow(color: Colors.black, blurRadius: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.distance,
    required this.radius,
    required this.phase,
    required this.speed,
  });

  factory _Particle.random(Random r) => _Particle(
        angle: r.nextDouble() * 2 * pi,
        distance: 0.1 + r.nextDouble() * 0.6,
        radius: 1.5 + r.nextDouble() * 3.0,
        phase: r.nextDouble(),
        speed: 0.3 + r.nextDouble() * 0.9,
      );

  final double angle;
  final double distance; // 0..1 of (shortest side / 2)
  final double radius;
  final double phase;
  final double speed;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.color,
    required this.t,
  });

  final List<_Particle> particles;
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double maxR = min(size.width, size.height) / 2;
    for (final _Particle p in particles) {
      final double tt = (t * p.speed + p.phase) % 1.0;
      final double d = p.distance * maxR * (0.4 + 0.6 * tt);
      final double x = c.dx + cos(p.angle) * d;
      final double y = c.dy + sin(p.angle) * d - tt * 60;
      final double alpha = (1 - tt).clamp(0.0, 1.0);
      final Paint pp = Paint()
        ..color = color.withValues(alpha: 0.5 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 1.6);
      canvas.drawCircle(Offset(x, y), p.radius * 2, pp);
      canvas.drawCircle(
        Offset(x, y),
        p.radius * 0.6,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

class _RadialPulsePainter extends CustomPainter {
  _RadialPulsePainter({required this.color, required this.t});
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double maxR = sqrt(size.width * size.width + size.height * size.height);
    for (int i = 0; i < 3; i++) {
      final double phase = (t + i / 3) % 1.0;
      final double r = maxR * phase;
      final double alpha = (1 - phase).clamp(0.0, 1.0) * 0.25;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    // Base radial gradient
    final Paint grad = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: maxR * 0.6));
    canvas.drawRect(Offset.zero & size, grad);
  }

  @override
  bool shouldRepaint(_RadialPulsePainter old) => true;
}

// Theme accessor to silence unused import warnings in future refactors.
// ignore: unused_element
Color _amazyAccent() => AmazyTheme.accentOrange;
