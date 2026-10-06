import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/menu_sheet.dart';
import 'about_screen.dart';
import 'game_screen.dart';
import 'paylines_screen.dart';
import 'paytable_screen.dart';

/// Home screen the user lands on after the splash. Hosts the big logo plus
/// four primary navigation buttons.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoFloat = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _logoFloat.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: AmazyTheme.bgDark,
      body: AnimatedGameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Column(
              children: <Widget>[
                // Top-right settings pill (opens the existing MenuSheet with
                // Privacy / Support links).
                Align(
                  alignment: Alignment.topRight,
                  child: _PillButton(
                    icon: Icons.settings,
                    label: 'SETTINGS',
                    onTap: _openSettings,
                  ),
                ),
                const Spacer(flex: 2),
                // Floating logo.
                AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[_logoFloat, _enter]),
                  builder: (_, Widget? child) {
                    final double enter =
                        Curves.easeOutCubic.transform(_enter.value);
                    final double float =
                        sin(_logoFloat.value * 2 * pi) * 6;
                    return Transform.translate(
                      offset: Offset(0, (1 - enter) * -30 + float),
                      child: Opacity(opacity: enter, child: child),
                    );
                  },
                  child: SizedBox(
                    height: mq.size.height * 0.22,
                    child: Image.asset(
                      'assets/Amazy_Zone_additional_assets/Game_Name.webp',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const Spacer(),
                // Primary buttons.
                _MenuEntry(
                  index: 0,
                  controller: _enter,
                  child: _BigButton(
                    label: 'PLAY',
                    icon: Icons.play_arrow_rounded,
                    primary: true,
                    onTap: () => _pushFade(const GameScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                _MenuEntry(
                  index: 1,
                  controller: _enter,
                  child: _BigButton(
                    label: 'PAYLINES',
                    icon: Icons.timeline,
                    onTap: () => _pushFade(const PaylinesScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                _MenuEntry(
                  index: 2,
                  controller: _enter,
                  child: _BigButton(
                    label: 'PAY TABLE',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => _pushFade(const PaytableScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                _MenuEntry(
                  index: 3,
                  controller: _enter,
                  child: _BigButton(
                    label: 'ABOUT',
                    icon: Icons.info_outline,
                    onTap: () => _pushFade(const AboutScreen()),
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  'v1.0.0 • RTP 98%',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.5,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const MenuSheet(),
    );
  }

  void _pushFade(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, Animation<double> a, __, Widget child) {
          return FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Staggered entry animation for each menu row.
class _MenuEntry extends StatelessWidget {
  const _MenuEntry({
    required this.index,
    required this.controller,
    required this.child,
  });

  final int index;
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, Widget? c) {
        final double t = Curves.easeOutCubic.transform(
          ((controller.value - index * 0.08) / 0.6).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset((1 - t) * 40, 0),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

class _BigButton extends StatefulWidget {
  const _BigButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<_BigButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapCancel: () => _press.reverse(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, Widget? child) {
          final double scale = 1.0 - _press.value * 0.04;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          height: widget.primary ? 68 : 58,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            gradient: widget.primary
                ? const LinearGradient(
                    colors: <Color>[
                      Color(0xFFFFC37A),
                      Color(0xFFFF8A1C),
                      Color(0xFFC14300),
                    ],
                  )
                : const LinearGradient(
                    colors: <Color>[
                      Color(0xDD1A1A20),
                      Color(0xEE090909),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AmazyTheme.accentOrange
                  .withValues(alpha: widget.primary ? 1.0 : 0.75),
              width: widget.primary ? 2.2 : 1.4,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AmazyTheme.accentOrange
                    .withValues(alpha: widget.primary ? 0.75 : 0.35),
                blurRadius: widget.primary ? 24 : 14,
                spreadRadius: widget.primary ? 1 : 0,
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Icon(
                widget.icon,
                size: widget.primary ? 32 : 24,
                color: widget.primary
                    ? Colors.white
                    : AmazyTheme.accentOrangeGlow,
                shadows: widget.primary
                    ? const <Shadow>[
                        Shadow(color: Colors.black, blurRadius: 6),
                      ]
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.primary ? 24 : 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                    shadows: const <Shadow>[
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.9),
                size: widget.primary ? 32 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AmazyTheme.accentOrange.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 15, color: AmazyTheme.accentOrangeGlow),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
