import 'dart:math';

import 'package:flutter/material.dart';

import '../game/spin_result.dart';
import '../theme.dart';

/// Immersive bonus wheel screen. Three tiers (bronze / silver / gold) with
/// their own colour schemes and reward tables. Returns the won amount via
/// [Navigator.pop].
class BonusWheelScreen extends StatefulWidget {
  const BonusWheelScreen({
    super.key,
    required this.tier,
    required this.totalBet,
  });

  final BonusTier tier;
  final double totalBet;

  @override
  State<BonusWheelScreen> createState() => _BonusWheelScreenState();
}

class _BonusWheelScreenState extends State<BonusWheelScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _entryController;
  final Random _rng = Random();
  bool _spinning = false;
  bool _finished = false;
  double _finalMultiplier = 0;
  double _targetAngle = 0;

  late final List<double> _rewards; // in multiples of totalBet
  late final List<Color> _segmentColors;
  late final List<Color> _accentColors;
  late final String _title;
  late final Color _rimColor;
  late final Color _hubColor;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..addStatusListener((AnimationStatus st) {
        if (st == AnimationStatus.completed) {
          setState(() => _finished = true);
        }
      });

    switch (widget.tier) {
      case BonusTier.bronze:
        _title = 'BRONZE WHEEL';
        // Sized so a 1% bronze trigger still fits a 98% RTP.
        _rewards = <double>[1, 2, 3, 2, 5, 3, 1, 8];
        _segmentColors = <Color>[
          const Color(0xFF8C4A1A),
          const Color(0xFFB06A2A),
          const Color(0xFF8C4A1A),
          const Color(0xFFB06A2A),
          const Color(0xFF8C4A1A),
          const Color(0xFFB06A2A),
          const Color(0xFF8C4A1A),
          const Color(0xFFD88A3C),
        ];
        _accentColors = <Color>[
          const Color(0xFFFFCC80),
          const Color(0xFFFFE0B2),
        ];
        _rimColor = const Color(0xFFCD7F32);
        _hubColor = const Color(0xFF8C4A1A);
        break;
      case BonusTier.silver:
        _title = 'SILVER WHEEL';
        // 4 scatters land on 0.75% of spins.
        _rewards = <double>[6, 10, 16, 8, 25, 12, 20, 50];
        _segmentColors = <Color>[
          const Color(0xFF4A4A55),
          const Color(0xFF7A7A8A),
          const Color(0xFF4A4A55),
          const Color(0xFF7A7A8A),
          const Color(0xFF4A4A55),
          const Color(0xFF7A7A8A),
          const Color(0xFF4A4A55),
          const Color(0xFFBFBFCC),
        ];
        _accentColors = <Color>[
          const Color(0xFFE0E0F0),
          const Color(0xFFF5F5FA),
        ];
        _rimColor = const Color(0xFFC0C0D0);
        _hubColor = const Color(0xFF4A4A55);
        break;
      case BonusTier.gold:
      default:
        _title = 'GOLD WHEEL';
        // 5 scatters land on 0.50% of spins. The top segment is the jackpot;
        // the average is what keeps the long-run RTP near 98%.
        _rewards = <double>[25, 50, 75, 40, 120, 60, 150, 820];
        _segmentColors = <Color>[
          const Color(0xFFB4890F),
          const Color(0xFFE2B341),
          const Color(0xFFB4890F),
          const Color(0xFFE2B341),
          const Color(0xFFB4890F),
          const Color(0xFFE2B341),
          const Color(0xFFB4890F),
          const Color(0xFFFFD56A),
        ];
        _accentColors = <Color>[
          const Color(0xFFFFF2B5),
          const Color(0xFFFFE69A),
        ];
        _rimColor = const Color(0xFFFFCA3A);
        _hubColor = const Color(0xFF8C6A0A);
        break;
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_spinning || _finished) return;
    final int winningSegment = _rng.nextInt(_rewards.length);
    _finalMultiplier = _rewards[winningSegment];

    const double segAngle = 2 * pi / 8;
    // Each segment is drawn at `-π/2 - sweep/2 + i*sweep` (see _WheelPainter).
    // So its CENTRE sits at `-π/2 + i*sweep`. To rotate segment i to the
    // pointer (which lives at -π/2), we need rotation = -i*sweep (modulo 2π).
    // Previously we added an extra sweep/2 which parked the pointer on the
    // segment edge instead of its centre.
    const int extraSpins = 6;
    _targetAngle = extraSpins * 2 * pi - winningSegment * segAngle;

    _spinController
      ..reset()
      ..forward();
    setState(() => _spinning = true);
  }

  void _collect() {
    Navigator.of(context).pop<double>(_finalMultiplier * widget.totalBet);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double wheelSize = min(size.width, size.height * 0.55);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedBuilder(
            animation: _entryController,
            builder: (_, Widget? child) {
              return Opacity(
                opacity: Curves.easeOut.transform(_entryController.value),
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[
                    _rimColor.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const <double>[0.0, 0.9],
                  radius: 1.0,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 12),
                _TitleBanner(title: _title, color: _rimColor),
                const SizedBox(height: 10),
                Text(
                  _spinning
                      ? (_finished ? 'YOU WON!' : 'SPINNING...')
                      : 'TAP SPIN TO START',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: wheelSize,
                  height: wheelSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _spinController,
                        builder: (_, __) {
                          final double curved =
                              Curves.easeOutCubic.transform(_spinController.value);
                          return Transform.rotate(
                            angle: _targetAngle * curved,
                            child: CustomPaint(
                              size: Size.square(wheelSize),
                              painter: _WheelPainter(
                                rewards: _rewards,
                                segmentColors: _segmentColors,
                                accents: _accentColors,
                                rim: _rimColor,
                                hub: _hubColor,
                              ),
                            ),
                          );
                        },
                      ),
                      // Pointer at top
                      Positioned(
                        top: -2,
                        child: CustomPaint(
                          size: Size(wheelSize * 0.11, wheelSize * 0.16),
                          painter: _PointerPainter(color: _rimColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (_finished)
                  _CollectButton(
                    amount: _finalMultiplier * widget.totalBet,
                    multiplier: _finalMultiplier,
                    color: _rimColor,
                    onTap: _collect,
                  )
                else
                  _SpinButton(
                    enabled: !_spinning,
                    color: _rimColor,
                    onTap: _spin,
                  ),
                const SizedBox(height: 12),
                Text(
                  _tierDescription(widget.tier),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tierDescription(BonusTier t) {
    switch (t) {
      case BonusTier.bronze:
        return '3 BONUS SCATTERS';
      case BonusTier.silver:
        return '4 BONUS SCATTERS';
      case BonusTier.gold:
        return '5 BONUS SCATTERS';
      case BonusTier.none:
        return '';
    }
  }
}

class _TitleBanner extends StatelessWidget {
  const _TitleBanner({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.black.withValues(alpha: 0.9),
            color.withValues(alpha: 0.35),
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: color, width: 1.8),
        borderRadius: BorderRadius.circular(10),
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 24),
        ],
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: Colors.white,
          shadows: <Shadow>[
            Shadow(color: color, blurRadius: 20),
          ],
        ),
      ),
    );
  }
}

class _SpinButton extends StatelessWidget {
  const _SpinButton({
    required this.enabled,
    required this.color,
    required this.onTap,
  });
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[
                Color(0xFFFFC37A),
                Color(0xFFFF8A1C),
                Color(0xFFE55A00),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: <BoxShadow>[
              BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 24),
            ],
            border: Border.all(color: Colors.white, width: 1.6),
          ),
          child: const Text(
            'SPIN',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 5,
              color: Colors.white,
              shadows: <Shadow>[
                Shadow(color: Colors.black, blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectButton extends StatefulWidget {
  const _CollectButton({
    required this.amount,
    required this.multiplier,
    required this.color,
    required this.onTap,
  });
  final double amount;
  final double multiplier;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_CollectButton> createState() => _CollectButtonState();
}

class _CollectButtonState extends State<_CollectButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final double v = Curves.easeOut.transform(_c.value);
        final double display = widget.amount * v;
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.95),
                  widget.color.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.color, width: 2.2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: widget.color.withValues(alpha: 0.9),
                    blurRadius: 28),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '×${widget.multiplier.toStringAsFixed(widget.multiplier >= 10 ? 0 : 1)} BET',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatFans(display),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    shadows: <Shadow>[
                      Shadow(color: widget.color, blurRadius: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  kNoRealMoney,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'TAP TO COLLECT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.rewards,
    required this.segmentColors,
    required this.accents,
    required this.rim,
    required this.hub,
  });

  final List<double> rewards;
  final List<Color> segmentColors;
  final List<Color> accents;
  final Color rim;
  final Color hub;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.width / 2;

    // Outer glow halo
    canvas.drawCircle(
      c,
      r + 4,
      Paint()
        ..color = rim.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );

    // Rim
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.fill
        ..color = rim.withValues(alpha: 0.9),
    );

    final double innerR = r * 0.93;

    // Segments
    const double sweep = 2 * pi / 8;
    for (int i = 0; i < 8; i++) {
      final Paint seg = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: <Color>[
            segmentColors[i].withValues(alpha: 1.0),
            segmentColors[i].withValues(alpha: 0.7),
          ],
          radius: 0.9,
        ).createShader(Rect.fromCircle(center: c, radius: innerR));
      // We want segment 0 at the top, extending clockwise. In canvas, 0 rad
      // is at 3 o'clock, so we offset by -pi/2 and shift back by half a seg
      // so pointer at top ends between segments naturally.
      final double start = -pi / 2 - sweep / 2 + i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: innerR),
        start,
        sweep,
        true,
        seg,
      );
      // Segment divider
      final Offset edge = Offset(
        c.dx + cos(start + sweep) * innerR,
        c.dy + sin(start + sweep) * innerR,
      );
      canvas.drawLine(
        c,
        edge,
        Paint()
          ..color = rim
          ..strokeWidth = 2,
      );
    }

    // Reward labels
    for (int i = 0; i < 8; i++) {
      final double start = -pi / 2 - sweep / 2 + i * sweep;
      final double mid = start + sweep / 2;
      final double tx = c.dx + cos(mid) * innerR * 0.68;
      final double ty = c.dy + sin(mid) * innerR * 0.68;
      final String label = '×${rewards[i].toStringAsFixed(rewards[i] >= 10 ? 0 : 1)}';
      final TextPainter tp = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: innerR * 0.14,
            fontWeight: FontWeight.w900,
            shadows: <Shadow>[
              Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 6),
            ],
          ),
        ),
      )..layout();
      canvas.save();
      canvas.translate(tx, ty);
      canvas.rotate(mid + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Hub
    canvas.drawCircle(c, innerR * 0.22,
        Paint()..color = hub);
    canvas.drawCircle(
      c,
      innerR * 0.22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = rim,
    );
    final TextPainter hubTp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'A',
        style: TextStyle(
          color: accents[0],
          fontSize: innerR * 0.22,
          fontWeight: FontWeight.w900,
        ),
      ),
    )..layout();
    hubTp.paint(canvas, Offset(c.dx - hubTp.width / 2, c.dy - hubTp.height / 2));
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}

class _PointerPainter extends CustomPainter {
  _PointerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      p,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}
