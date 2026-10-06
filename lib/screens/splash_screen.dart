import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/symbols.dart';
import '../theme.dart';
import 'main_menu_screen.dart';

/// Loading screen that supports both portrait and landscape orientation.
///
/// The horizontal progress bar fills left-to-right. It is driven both by real
/// asset precaching and by a baseline timer so it has a smooth, deliberate
/// animation. The bar reaches 100% only right before the game is pushed.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _dotsController;
  double _progress = 0.0;
  Timer? _timer;
  bool _assetsReady = false;
  bool _pushed = false;

  @override
  void initState() {
    super.initState();

    // Allow both orientations during loading.
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _startProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheAssets());
  }

  void _startProgress() {
    const Duration tick = Duration(milliseconds: 50);
    _timer = Timer.periodic(tick, (Timer t) {
      // Linear progress drifts up to 90% then waits for real assets.
      double next = _progress;
      if (!_assetsReady) {
        if (next < 0.90) {
          next += 0.012;
        } else {
          // Hover a bit under 90% while assets finish.
          next += 0.0007;
          if (next > 0.92) next = 0.92;
        }
      } else {
        next += 0.025;
      }
      if (next >= 1.0) {
        next = 1.0;
      }
      if (next != _progress) {
        setState(() => _progress = next);
      }
      if (next >= 1.0 && _assetsReady && !_pushed) {
        _pushed = true;
        t.cancel();
        _goToGame();
      }
    });
  }

  Future<void> _precacheAssets() async {
    final List<String> paths = <String>[
      'assets/Amazy_Zone_gameplay_assets/background_game.webp',
      'assets/Amazy_Zone_gameplay_assets/slot_frame_asset.webp',
      'assets/Amazy_Zone_gameplay_assets/button_start_asset.webp',
      'assets/Amazy_Zone_gameplay_assets/button_bet_asset.webp',
      'assets/Amazy_Zone_gameplay_assets/button_bet_asset2.webp',
      'assets/Amazy_Zone_gameplay_assets/buttons_game_asset.webp',
      'assets/Amazy_Zone_additional_assets/Game_Name.webp',
      for (final SymbolData s in kSymbolRegistry.values) s.asset,
    ];
    for (final String p in paths) {
      await precacheImage(AssetImage(p), context);
    }
    // A short, deliberate pause so the player enjoys the splash.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _assetsReady = true);
  }

  Future<void> _goToGame() async {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const MainMenuScreen(),
        transitionsBuilder: (_, Animation<double> a, __, Widget child) {
          return FadeTransition(opacity: a, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Orientation orient = MediaQuery.of(context).orientation;
    final bool landscape = orient == Orientation.landscape;

    return Scaffold(
      backgroundColor: AmazyTheme.bgDark,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            landscape
                ? 'assets/Amazy_Zone_additional_assets/Horizontal_Loading_Screen.webp'
                : 'assets/Amazy_Zone_additional_assets/Vertical_Loading_Screen.webp',
            fit: BoxFit.cover,
          ),
          // Subtle vignette so the bar + text are readable.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x66000000),
                  Color(0xCC000000),
                ],
                stops: <double>[0.0, 0.55, 0.80, 1.0],
              ),
            ),
            child: SizedBox.expand(),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: landscape ? 48 : 28,
                right: landscape ? 48 : 28,
                bottom: landscape ? 24 : 42,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _LoadingText(controller: _dotsController),
                  const SizedBox(height: 14),
                  _ProgressBar(progress: _progress),
                  const SizedBox(height: 10),
                  Text(
                    '${(_progress * 100).floor()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AmazyTheme.accentOrangeGlow,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingText extends StatelessWidget {
  const _LoadingText({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final int dotCount = (controller.value * 4).floor() % 4;
        final String dots = '.' * dotCount;
        return Text(
          'Loading$dots',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: Colors.white,
            shadows: <Shadow>[
              Shadow(
                color: AmazyTheme.accentOrange.withValues(alpha: 0.9),
                blurRadius: 18,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double width = c.maxWidth;
        return SizedBox(
          height: 18,
          width: width,
          child: Stack(
            children: <Widget>[
              // Track
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xDD0C0C0E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AmazyTheme.accentOrange.withValues(alpha: 0.65),
                    width: 1.2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AmazyTheme.accentOrange.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const SizedBox.expand(),
              ),
              // Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                width: width * progress,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: <Color>[
                      Color(0xFFFFE6B5),
                      Color(0xFFFF9F3A),
                      Color(0xFFFF5A00),
                    ],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AmazyTheme.accentOrange.withValues(alpha: 0.95),
                      blurRadius: 18,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
