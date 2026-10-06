import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/slot_engine.dart';
import '../game/spin_result.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/big_win_overlay.dart';
import '../widgets/bonus_wheel.dart';
import '../widgets/menu_sheet.dart';
import '../widgets/slot_machine.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  final SlotEngine _engine = SlotEngine();
  final StreamController<void> _spinSignal =
      StreamController<void>.broadcast();
  final GlobalKey<SlotMachineState> _slotKey =
      GlobalKey<SlotMachineState>();

  // Economy ---------------------------------------------------------------
  double _balance = 1000.0;
  double _lastWin = 0.0;

  /// Sum of every winning payline on the last spin. Shown under the reels
  /// as soon as the reels stop — not one line at a time.
  double _lineWinTotal = 0.0;

  // Bet size options (total bet across 25 lines).
  static const List<double> _betOptions = <double>[
    0.25, 0.50, 1.00, 2.50, 5.00, 10.00, 25.00, 50.00, 100.00
  ];
  int _betIndex = 2; // $1.00 default

  // UI state --------------------------------------------------------------
  bool _spinning = false;
  bool _showingOverlay = false;

  // Anticipation zoom tracking.
  late final AnimationController _zoomController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      reverseDuration: const Duration(milliseconds: 650),
    );
  }

  void _onAnticipation(int? reel) {
    if (reel != null) {
      _zoomController.forward();
    } else {
      _zoomController.reverse();
    }
  }

  @override
  void dispose() {
    _spinSignal.close();
    _zoomController.dispose();
    super.dispose();
  }

  double get _totalBet => _betOptions[_betIndex];

  void _onBetMinus() {
    if (_spinning) return;
    setState(() => _betIndex = math.max(0, _betIndex - 1));
  }

  void _onBetPlus() {
    if (_spinning) return;
    setState(() => _betIndex = math.min(_betOptions.length - 1, _betIndex + 1));
  }

  void _onSpinPressed() {
    if (_spinning || _showingOverlay) return;
    if (_balance < _totalBet) {
      _showToast('Not enough balance');
      return;
    }
    setState(() {
      _balance -= _totalBet;
      _lastWin = 0.0;
      _lineWinTotal = 0.0;
      _spinning = true;
    });
    _spinSignal.add(null);
  }

  void _onSpinResolved(SpinResult result) async {
    setState(() {
      _spinning = false;
      _lastWin = result.totalPay;
      _lineWinTotal = result.totalLinePay;
      _balance += result.totalPay;
    });

    // Handle bonus wheel first (it awards money on top).
    if (result.bonusTier != BonusTier.none) {
      // Short beat to let the player see the scatter land before the overlay.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await _showBonusWheel(result.bonusTier);
    }

    // After bonus (and its own payout) decide if we need a BIG WIN overlay.
    final double finalMultiplier =
        _totalBet > 0 ? _lastWin / _totalBet : 0.0;
    if (finalMultiplier >= 15.0) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await _showBigWinOverlay(_lastWin, finalMultiplier);
    }
  }

  Future<void> _showBonusWheel(BonusTier tier) async {
    _slotKey.currentState?.clearHighlights();
    setState(() => _showingOverlay = true);
    final double? won = await Navigator.of(context).push<double>(
      PageRouteBuilder<double>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => BonusWheelScreen(
          tier: tier,
          totalBet: _totalBet,
        ),
        transitionsBuilder: (_, Animation<double> a, __, Widget child) {
          return FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
    final double addition = won ?? 0.0;
    setState(() {
      _showingOverlay = false;
      _balance += addition;
      _lastWin += addition;
    });
  }

  Future<void> _showBigWinOverlay(double amount, double multiplier) async {
    _slotKey.currentState?.clearHighlights();
    setState(() => _showingOverlay = true);
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => BigWinOverlay(
          amount: amount,
          multiplier: multiplier,
        ),
        transitionsBuilder: (_, Animation<double> a, __, Widget child) {
          return FadeTransition(opacity: a, child: child);
        },
      ),
    );
    setState(() => _showingOverlay = false);
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AmazyTheme.panelDark,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => MenuSheet(
        onBackToMenu: () {
          Navigator.of(context).pop(); // close sheet
          Navigator.of(context).maybePop(); // pop game screen
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmazyTheme.bgDark,
      body: AnimatedGameBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              return Column(
                children: <Widget>[
                  _TopBar(
                    balance: _balance,
                    lastWin: _lastWin,
                    onMenu: _openMenu,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _AnticipationZoom(
                        controller: _zoomController,
                        child: SlotMachine(
                          key: _slotKey,
                          engine: _engine,
                          totalBetProvider: () => _totalBet,
                          onSpinStart: () {},
                          onSpinResolved: _onSpinResolved,
                          onAnticipation: _onAnticipation,
                          spinSignal: _spinSignal.stream,
                        ),
                      ),
                    ),
                  ),
                  _WinBanner(amount: _spinning ? 0 : _lineWinTotal),
                  _BottomControls(
                    bet: _totalBet,
                    spinning: _spinning,
                    onMinus: _onBetMinus,
                    onPlus: _onBetPlus,
                    onSpin: _onSpinPressed,
                    onMenu: _openMenu,
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.balance,
    required this.lastWin,
    required this.onMenu,
  });

  final double balance;
  final double lastWin;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Game logo
          SizedBox(
            height: 54,
            child: Image.asset(
              'assets/Amazy_Zone_additional_assets/Game_Name.webp',
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          _StatPlate(label: 'WIN', value: lastWin),
          const SizedBox(width: 8),
          _StatPlate(label: 'BALANCE', value: balance, highlight: true),
        ],
      ),
    );
  }
}

class _StatPlate extends StatelessWidget {
  const _StatPlate({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final double value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xDD1A1A20),
            Color(0xEE090909),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AmazyTheme.accentOrange.withValues(alpha: highlight ? 0.9 : 0.5),
          width: 1.2,
        ),
        boxShadow: highlight
            ? <BoxShadow>[
                BoxShadow(
                  color: AmazyTheme.accentOrange.withValues(alpha: 0.5),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            formatFans(value),
            style: TextStyle(
              color: highlight
                  ? AmazyTheme.accentOrangeGlow
                  : Colors.white,
              fontSize: 15,
              letterSpacing: 1,
              fontWeight: FontWeight.w900,
              shadows: highlight
                  ? <Shadow>[
                      Shadow(
                          color: AmazyTheme.accentOrange,
                          blurRadius: 12),
                    ]
                  : null,
            ),
          ),
          Text(
            kNoRealMoney,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 7,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sits directly under the reels and shows the sum of every winning line
/// the moment the reels stop.
class _WinBanner extends StatelessWidget {
  const _WinBanner({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final bool show = amount > 0;
    return SizedBox(
      height: 52,
      child: AnimatedOpacity(
        opacity: show ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width - 28,
            ),
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xDD1A1208), Color(0xEE0A0A0D)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AmazyTheme.accentGold.withValues(alpha: show ? 0.9 : 0),
                width: 1.2,
              ),
              boxShadow: show
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AmazyTheme.accentGold.withValues(alpha: 0.35),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'WIN  ${formatFans(amount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: <Shadow>[
                        Shadow(color: AmazyTheme.accentGold, blurRadius: 12),
                      ],
                    ),
                  ),
                  const Text(
                    kNoRealMoney,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 8,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.bet,
    required this.spinning,
    required this.onMinus,
    required this.onPlus,
    required this.onSpin,
    required this.onMenu,
  });

  final double bet;
  final bool spinning;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onSpin;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      child: Row(
        children: <Widget>[
          _CircleButton(
            onTap: onMenu,
            iconPart: _CirclePart.gear,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BetControl(
              bet: bet,
              onMinus: onMinus,
              onPlus: onPlus,
            ),
          ),
          const SizedBox(width: 8),
          _SpinButton(onTap: onSpin, spinning: spinning),
        ],
      ),
    );
  }
}

/// The ornate three-circle sprite is already a flattened image; we show the
/// relevant icon on top of a themed round button to allow interaction.
enum _CirclePart { gear, replay, play }

class _CircleButton extends StatefulWidget {
  const _CircleButton({required this.onTap, required this.iconPart});
  final VoidCallback onTap;
  final _CirclePart iconPart;

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.iconPart) {
      case _CirclePart.gear:
        return Icons.settings;
      case _CirclePart.replay:
        return Icons.replay;
      case _CirclePart.play:
        return Icons.play_arrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapCancel: () => _c.reverse(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, Widget? child) {
          final double scale = 1.0 - _c.value * 0.08;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: <Color>[
                Color(0xFF333338),
                Color(0xFF0A0A0D),
              ],
            ),
            border: Border.all(
                color: AmazyTheme.accentOrange.withValues(alpha: 0.85),
                width: 1.6),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AmazyTheme.accentOrange.withValues(alpha: 0.55),
                blurRadius: 14,
              ),
            ],
          ),
          child: Icon(_icon, color: AmazyTheme.accentOrangeGlow, size: 24),
        ),
      ),
    );
  }
}

class _BetControl extends StatelessWidget {
  const _BetControl({
    required this.bet,
    required this.onMinus,
    required this.onPlus,
  });

  final double bet;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xDD111115), Color(0xEE0A0A0D)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AmazyTheme.accentOrange.withValues(alpha: 0.75),
          width: 1.4,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: AmazyTheme.accentOrange.withValues(alpha: 0.4),
              blurRadius: 16),
        ],
      ),
      child: Row(
        children: <Widget>[
          _ArrowButton(onTap: onMinus, left: true),
          const SizedBox(width: 2),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'TOTAL BET',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formatFans(bet),
                    style: const TextStyle(
                      color: AmazyTheme.accentOrangeGlow,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    kNoRealMoney,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 7,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          _ArrowButton(onTap: onPlus, left: false),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.onTap, required this.left});
  final VoidCallback onTap;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 36,
        padding: const EdgeInsets.all(4),
        child: Icon(
          left ? Icons.chevron_left : Icons.chevron_right,
          color: AmazyTheme.accentOrange,
          size: 30,
        ),
      ),
    );
  }
}

/// Applies a smooth zoom-in with a very subtle pulsing shake while the parent
/// [AnimationController] value is non-zero. Used during the "bonus hunt"
/// anticipation on the last reels after 2+ bonus symbols have landed.
class _AnticipationZoom extends StatefulWidget {
  const _AnticipationZoom({
    required this.controller,
    required this.child,
  });

  final AnimationController controller;
  final Widget child;

  @override
  State<_AnticipationZoom> createState() => _AnticipationZoomState();
}

class _AnticipationZoomState extends State<_AnticipationZoom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[widget.controller, _wobble]),
      builder: (BuildContext context, Widget? child) {
        // The controller value drifts up slowly on `forward()` (900ms) and
        // falls back on `reverse()` (650ms). Combined with the wobble, the
        // slot subtly "breathes" during the long anticipation.
        final double raw = widget.controller.value;
        final double eased = Curves.easeInOutCubic.transform(raw);
        final double breath =
            0.5 + 0.5 * math.sin(_wobble.value * 2 * math.pi);
        final double scale = 1.0 + eased * (0.08 + 0.025 * breath);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

class _SpinButton extends StatefulWidget {
  const _SpinButton({required this.onTap, required this.spinning});
  final VoidCallback onTap;
  final bool spinning;

  @override
  State<_SpinButton> createState() => _SpinButtonState();
}

class _SpinButtonState extends State<_SpinButton>
    with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final AnimationController _rotate = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void didUpdateWidget(_SpinButton old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_rotate.isAnimating) {
      _rotate.repeat();
    } else if (!widget.spinning && _rotate.isAnimating) {
      _rotate.stop();
      _rotate.value = 0;
    }
  }

  @override
  void dispose() {
    _press.dispose();
    _rotate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.spinning ? null : (_) => _press.forward(),
      onTapCancel: widget.spinning ? null : () => _press.reverse(),
      onTapUp: widget.spinning
          ? null
          : (_) {
              _press.reverse();
              widget.onTap();
            },
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_press, _rotate]),
        builder: (_, Widget? child) {
          final double scale = 1.0 - _press.value * 0.08;
          return Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: _rotate.value * 2 * math.pi,
              child: child,
            ),
          );
        },
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: <Color>[
                Color(0xFFFFC37A),
                Color(0xFFFF8A1C),
                Color(0xFFC14300),
              ],
              stops: <double>[0.0, 0.6, 1.0],
            ),
            border: Border.all(color: Colors.white, width: 1.8),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AmazyTheme.accentOrange.withValues(alpha: 0.9),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            widget.spinning ? Icons.autorenew : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 42,
            shadows: const <Shadow>[
              Shadow(color: Colors.black, blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
