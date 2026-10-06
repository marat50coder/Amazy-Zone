import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../game/paylines.dart';
import '../game/slot_engine.dart';
import '../game/spin_result.dart';
import '../game/symbols.dart';
import '../theme.dart';
import 'anticipation_overlay.dart';
import 'payline_overlay.dart';
import 'reel_widget.dart';

/// Callbacks + payload emitted after every spin resolves.
typedef SpinResolvedCallback = void Function(SpinResult result);

/// The 5x4 reel array wrapped in the ornate frame. Owns reel controllers and
/// the full spin lifecycle (pre-spin flash → spin → stop reels → anticipation →
/// land → win highlight). Pure UI; it never touches currency/balance - it just
/// surfaces [SpinResolvedCallback] events to the parent.
class SlotMachine extends StatefulWidget {
  const SlotMachine({
    super.key,
    required this.engine,
    required this.totalBetProvider,
    required this.onSpinStart,
    required this.onSpinResolved,
    required this.spinSignal,
    this.onAnticipation,
    this.onHighlightedWin,
  });

  final SlotEngine engine;
  final double Function() totalBetProvider;
  final VoidCallback onSpinStart;
  final SpinResolvedCallback onSpinResolved;

  /// A stream of "please start a spin" events from the parent (SPIN button).
  final Stream<void> spinSignal;

  /// Fired when a slow-stop anticipation kicks in. Parent can use it to
  /// trigger a camera-style zoom. [reelIndex] is the reel that is currently
  /// being anticipated, or null when the anticipation is over.
  final void Function(int? reelIndex)? onAnticipation;

  /// The line currently lit on the reels. Null means every winning line is
  /// shown at once (the banner should display the spin total).
  final void Function(LineWin? line)? onHighlightedWin;

  @override
  State<SlotMachine> createState() => SlotMachineState();
}

class SlotMachineState extends State<SlotMachine>
    with TickerProviderStateMixin {
  final List<ReelController> _reels = List<ReelController>.generate(
    kReels,
    (_) => ReelController(),
  );
  final Random _random = Random();

  late final AnimationController _winPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  SpinResult? _lastResult;
  bool _busy = false;
  StreamSubscription<void>? _spinSub;
  List<LineWin> _activeWins = <LineWin>[];
  Timer? _lineCycleTimer;
  int _lineCycleIndex = -1; // -1 = show all simultaneously

  // Currently anticipated reel (null = no anticipation visuals).
  int? _anticipationReel;

  @override
  void initState() {
    super.initState();
    _spinSub = widget.spinSignal.listen((_) => _startSpin());
  }

  @override
  void dispose() {
    _spinSub?.cancel();
    _lineCycleTimer?.cancel();
    _winPulse.dispose();
    for (final ReelController c in _reels) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _startSpin() async {
    if (_busy) return;
    _busy = true;
    setState(() {
      _activeWins = <LineWin>[];
      _lineCycleIndex = -1;
      _lastResult = null;
    });
    widget.onHighlightedWin?.call(null);
    widget.onSpinStart();

    SpinResult? result;
    try {
      // Fire all reels at once.
      for (final ReelController c in _reels) {
        c.start();
      }

      // Generate the result immediately so we know what each reel must land on.
      final double totalBet = widget.totalBetProvider();
      result = widget.engine.spin(totalBet: totalBet);
      _lastResult = result;

      // Pre-count scatters per reel from the known result so we can decide,
      // for every reel k, whether it should land slowly (anticipated).
      //
      // Rule (Pragmatic-style): if the number of scatters that will be visible
      // on reels 0..k-1 is already ≥ 2, slow-land reel k. We can safely use
      // the pre-computed result because reels land left-to-right, which means
      // when it is time to stop reel k, reels 0..k-1 are already visible to
      // the player.
      final List<int> scattersInReel = <int>[
        for (int r = 0; r < kReels; r++)
          <int>[
            for (int row = 0; row < kRows; row++)
              result.grid[r][row] == SlotSymbol.bonus ? 1 : 0,
          ].fold(0, (int a, int b) => a + b),
      ];
      int cumBeforeReel(int k) =>
          scattersInReel.sublist(0, k).fold(0, (int a, int b) => a + b);
      bool isSlow(int k) => k >= 2 && cumBeforeReel(k) >= 2;

      for (int r = 0; r < kReels; r++) {
        final bool slow = isSlow(r);
        final bool prevSlow = r > 0 && isSlow(r - 1);

        final List<SlotSymbol> window = <SlotSymbol>[
          for (int row = 0; row < kRows; row++) result.grid[r][row],
        ];

        if (slow) {
          // CRITICAL: before kicking off the zoom on reel r, make sure the
          // previous reel has visually CLICKED into place. Otherwise the
          // overlay appears while the symbol that pushed the scatter count
          // to 2 is still mid-landing.
          if (r > 0 && _reels[r - 1].spinning) {
            await _waitForReel(r - 1);
          }
          // Move the highlight onto THIS reel. If the previous reel was also
          // anticipated, the overlay simply re-targets — the transition is
          // seamless (no fade-out / fade-in flicker).
          _setAnticipation(r);
          // Short dramatic beat ONLY the first time we enter zoom. Within a
          // chain of slow reels we flow straight from one landing to the next.
          if (!prevSlow) {
            await Future<void>.delayed(const Duration(milliseconds: 260));
          }
          _reels[r].stopWith(window, slow: true);
          await _waitForReel(r);
        } else {
          // Standard stagger between non-slow reels.
          await Future<void>.delayed(const Duration(milliseconds: 240));
          _reels[r].stopWith(window, slow: false);
        }
      }

      // Make sure all remaining reels have actually landed before resolving.
      for (int r = 0; r < kReels; r++) {
        if (_reels[r].spinning) {
          await _waitForReel(r);
        }
      }
      _setAnticipation(null);

      // Note: there is deliberately NO post-anticipation here. When the
      // final grid holds only 2 scatters without triggering slow landings,
      // the bonus was impossible and we don't want to tease a non-existent
      // bonus. The static scatter glow (see _ScatterEmphasis) still draws
      // attention to the landed scatters.

      // Winning lines highlight.
      final List<LineWin> wins = List<LineWin>.of(result.lineWins)
        ..sort((LineWin a, LineWin b) => b.amount.compareTo(a.amount));
      if (mounted) {
        setState(() => _activeWins = wins);
      }
      if (wins.isNotEmpty) {
        _startLineCycle(wins.length);
      } else {
        widget.onHighlightedWin?.call(null);
      }

      widget.onSpinResolved(result);
    } finally {
      _busy = false;
    }
  }

  void _setAnticipation(int? reel) {
    if (_anticipationReel == reel) return;
    setState(() => _anticipationReel = reel);
    widget.onAnticipation?.call(reel);
  }

  Future<void> _waitForReel(int reelIndex) async {
    final Completer<void> c = Completer<void>();
    late final VoidCallback l;
    l = () {
      if (!_reels[reelIndex].spinning) {
        _reels[reelIndex].removeListener(l);
        c.complete();
      }
    };
    _reels[reelIndex].addListener(l);
    if (!_reels[reelIndex].spinning) {
      _reels[reelIndex].removeListener(l);
      return;
    }
    await c.future;
  }

  void _onReelLanded(int reelIndex) {
    // Reserved for future per-reel landing side effects (sound, haptics...).
  }

  void _startLineCycle(int totalWins) {
    _lineCycleTimer?.cancel();
    // Lead with the single biggest line so the glow and the amount under
    // the reels describe the same win. The cycle then walks the rest and
    // finishes on "all lines" (index == -1).
    _lineCycleIndex = 0;
    _emitHighlighted();
    _lineCycleTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (Timer t) {
        if (!mounted) return;
        setState(() {
          _lineCycleIndex = (_lineCycleIndex + 1) % (totalWins + 1);
          if (_lineCycleIndex == totalWins) _lineCycleIndex = -1;
        });
        _emitHighlighted();
      },
    );
  }

  void _emitHighlighted() {
    if (_lineCycleIndex < 0 || _lineCycleIndex >= _activeWins.length) {
      widget.onHighlightedWin?.call(null);
      return;
    }
    widget.onHighlightedWin?.call(_activeWins[_lineCycleIndex]);
  }

  /// Stop any ongoing animations and clear win highlights. Used by the parent
  /// before an overlay (Big Win / Bonus Wheel) takes over the screen.
  void clearHighlights() {
    _lineCycleTimer?.cancel();
    setState(() {
      _activeWins = <LineWin>[];
      _lineCycleIndex = -1;
    });
    widget.onHighlightedWin?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints c) {
      // Compute cell size so that the 5x4 grid fits within the available area,
      // leaving room for the ornate frame.
      final double availW = c.maxWidth;
      final double availH = c.maxHeight;

      // Frame aspect (W/H) based on the slot_frame_asset image.
      const double frameAspect = 1466 / 1191;

      // Fit the frame into available area while preserving aspect.
      double frameW = availW;
      double frameH = frameW / frameAspect;
      if (frameH > availH) {
        frameH = availH;
        frameW = frameH * frameAspect;
      }

      // Inside the frame: the play area is slightly offset downward because
      // the ornate top banner takes a bit of vertical space. Numbers measured
      // against slot_frame_asset.webp (1466 × 1191 px).
      const double innerLeftFrac = 0.055;
      const double innerRightFrac = 0.055;
      const double innerTopFrac = 0.118;
      // Slightly larger bottom inset so the lowest row of symbols sits a
      // few pixels above the painted frame base-strip (was 0.050, which let
      // the bottom symbol feet nip the ornamental bar).
      const double innerBottomFrac = 0.075;

      final double innerW = frameW * (1 - innerLeftFrac - innerRightFrac);
      final double innerH = frameH * (1 - innerTopFrac - innerBottomFrac);

      // The frame's cells are slightly wider than they are tall. We honour
      // that so the live symbols sit exactly inside the painted frame cells
      // instead of being an inscribed square that leaves gaps.
      final double cellW = innerW / kReels;
      final double cellH = innerH / kRows;
      final double gridW = cellW * kReels;
      final double gridH = cellH * kRows;
      final double gridLeft = frameW * innerLeftFrac;
      final double gridTop = frameH * innerTopFrac;

      final List<LineWin> drawnWins = _lineCycleIndex == -1
          ? _activeWins
          : (_activeWins.isNotEmpty
              ? <LineWin>[_activeWins[_lineCycleIndex]]
              : <LineWin>[]);

      // Highlight: which (reel,row) coords are part of a drawn win?
      final List<Map<int, double>> perReelEmphasis =
          List<Map<int, double>>.generate(kReels, (_) => <int, double>{});
      for (final LineWin w in drawnWins) {
        for (int r = 0; r < w.matchCount; r++) {
          perReelEmphasis[r][w.rows[r]] = 1.0;
        }
      }

      return Center(
        child: SizedBox(
          width: frameW,
          height: frameH,
          child: Stack(
            children: <Widget>[
              // Layer 1: ornate frame (bottom). Fills the whole area.
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/Amazy_Zone_gameplay_assets/slot_frame_asset.webp',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              // Layer 2: dark panel directly underneath the reels so the
              // frame's painted cell slots don't clash with the live symbols.
              Positioned(
                left: gridLeft - 3,
                top: gridTop - 3,
                width: gridW + 6,
                height: gridH + 6,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              // Layer 3: the reels themselves.
              Positioned(
                left: gridLeft,
                top: gridTop,
                width: gridW,
                height: gridH,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (int r = 0; r < kReels; r++)
                      _ReelColumn(
                        controller: _reels[r],
                        cellWidth: cellW,
                        cellHeight: cellH,
                        random: _random,
                        reelIndex: r,
                        onLanded: () => _onReelLanded(r),
                        emphasis: perReelEmphasis[r],
                        pulse: _winPulse,
                      ),
                  ],
                ),
              ),
              // Layer 4: scatter glow behind bonus symbols.
              if (_lastResult != null)
                Positioned(
                  left: gridLeft,
                  top: gridTop,
                  width: gridW,
                  height: gridH,
                  child: _ScatterEmphasis(
                    positions: _lastResult!.scatterPositions,
                    cellWidth: cellW,
                    cellHeight: cellH,
                    pulse: _winPulse,
                  ),
                ),
              // Layer 5: anticipation (dim + glow around active reel).
              Positioned(
                left: gridLeft,
                top: gridTop,
                width: gridW,
                height: gridH,
                child: AnticipationOverlay(
                  cellWidth: cellW,
                  cellHeight: cellH,
                  activeReel: _anticipationReel,
                ),
              ),
              // Layer 6: winning paylines (always on top of symbols).
              Positioned(
                left: gridLeft,
                top: gridTop,
                width: gridW,
                height: gridH,
                child: PaylineOverlay(
                  cellWidth: cellW,
                  cellHeight: cellH,
                  wins: drawnWins,
                  pulse: _winPulse,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ReelColumn extends StatelessWidget {
  const _ReelColumn({
    required this.controller,
    required this.cellWidth,
    required this.cellHeight,
    required this.random,
    required this.reelIndex,
    required this.onLanded,
    required this.emphasis,
    required this.pulse,
  });

  final ReelController controller;
  final double cellWidth;
  final double cellHeight;
  final Random random;
  final int reelIndex;
  final VoidCallback onLanded;
  final Map<int, double> emphasis;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return ReelWidget(
      controller: controller,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      random: random,
      reelIndex: reelIndex,
      onLanded: onLanded,
      winRowEmphasis: emphasis,
      winRowAnimation: pulse,
    );
  }
}

/// Lightweight visualiser that pulses a glow directly behind every bonus
/// symbol on the grid (so users notice scatters even if no line win exists).
class _ScatterEmphasis extends StatelessWidget {
  const _ScatterEmphasis({
    required this.positions,
    required this.cellWidth,
    required this.cellHeight,
    required this.pulse,
  });

  final List<List<int>> positions;
  final double cellWidth;
  final double cellHeight;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    if (positions.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          return Stack(
            children: <Widget>[
              for (final List<int> p in positions)
                Positioned(
                  left: p[0] * cellWidth,
                  top: p[1] * cellHeight,
                  width: cellWidth,
                  height: cellHeight,
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AmazyTheme.accentOrange.withValues(
                              alpha: 0.5 +
                                  0.5 *
                                      (0.5 + 0.5 * sin(pulse.value * 2 * pi))),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
