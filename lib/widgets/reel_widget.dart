import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/paylines.dart';
import '../game/symbols.dart';
import 'symbol_tile.dart';

/// One vertical reel of [kRows] visible symbols.
///
/// It is controlled from the outside via a [ReelController] - that lets the
/// [SlotMachine] start all reels at once and stop them one by one (with
/// optional anticipation / slow-down on the last reels for bonus hunt).
class ReelController extends ChangeNotifier {
  List<SlotSymbol>? _targetWindow; // length == kRows
  bool _spinning = false;
  bool _requestStop = false;
  bool _slowStop = false;

  bool get spinning => _spinning;
  bool get requestStop => _requestStop;
  bool get slowStop => _slowStop;
  List<SlotSymbol>? get targetWindow => _targetWindow;

  /// Start spinning. The reel will keep spinning until [stopWith] is called.
  void start() {
    _spinning = true;
    _requestStop = false;
    _slowStop = false;
    _targetWindow = null;
    notifyListeners();
  }

  /// Ask the reel to stop and land on [window] (length == kRows).
  /// If [slow] is true, the reel decelerates with extra suspense.
  void stopWith(List<SlotSymbol> window, {bool slow = false}) {
    _targetWindow = List<SlotSymbol>.unmodifiable(window);
    _requestStop = true;
    _slowStop = slow;
    notifyListeners();
  }

  /// Called by [ReelWidget] when the landing animation finishes. Clears
  /// spinning flags AND notifies listeners so callers (e.g. SlotMachine's
  /// `_waitForReel`) can unblock.
  void markLanded() {
    _spinning = false;
    _requestStop = false;
    _slowStop = false;
    _targetWindow = null;
    notifyListeners();
  }
}

class ReelWidget extends StatefulWidget {
  const ReelWidget({
    super.key,
    required this.controller,
    required this.cellWidth,
    required this.cellHeight,
    required this.random,
    this.reelIndex = 0,
    this.onLanded,
    this.winRowEmphasis = const <int, double>{},
    this.winRowAnimation,
  });

  final ReelController controller;
  final double cellWidth;
  final double cellHeight;
  final Random random;
  final int reelIndex;
  final VoidCallback? onLanded;

  /// Row index -> emphasis amount (0..1). Only applied when the reel is still
  /// (not spinning). Used by the SlotMachine to light up winning symbols.
  final Map<int, double> winRowEmphasis;

  /// Shared Listenable so we can rebuild while a win pulse animation runs.
  final Listenable? winRowAnimation;

  @override
  State<ReelWidget> createState() => _ReelWidgetState();
}

class _ReelWidgetState extends State<ReelWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  // Pixel offset accumulated while scrolling. The visible window is a sliding
  // view onto [_strip] driven by this offset.
  double _offset = 0;

  // Linear free-spin velocity (px/ms). High value → brisk reel.
  double _velocity = 2.4;

  List<SlotSymbol> _strip = <SlotSymbol>[];

  // Last known visible window shown by the static builder.
  List<SlotSymbol> _window = <SlotSymbol>[
    SlotSymbol.ace,
    SlotSymbol.king,
    SlotSymbol.queen,
    SlotSymbol.jack,
  ];

  DateTime _lastTick = DateTime.now();

  // Landing (deceleration) state.
  bool _landing = false;
  double _landStartOffset = 0;
  double _landTargetOffset = 0;
  int _landDurationMs = 0;
  int _landElapsedMs = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(ReelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _ticker.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.spinning && !_ticker.isActive) {
      // Begin spinning.
      _strip = _buildRandomStrip(80);
      _offset = 0;
      _velocity = 2.4;
      _landing = false;
      _lastTick = DateTime.now();
      _ticker.start();
    }
    if (widget.controller.requestStop && !_landing) {
      // Prepare the landing animation. We append plenty of extra random
      // symbols followed by the exact target window to the end of the strip.
      // Then we animate [_offset] to the index that positions the target
      // window inside the visible viewport.
      final List<SlotSymbol> window = widget.controller.targetWindow!;
      final bool slow = widget.controller.slowStop;

      // Extra free-wheel distance so that:
      //   - a normal stop takes ~0.9s
      //   - a slow (anticipation) stop takes ~3.4s and ticks visibly symbol
      //     by symbol toward the end
      final int runUp = slow ? 42 : 18;
      final List<SlotSymbol> extra = _buildRandomStrip(runUp)
        // The visible top-to-bottom order equals strip[topIndex..+kRows-1]
        // (see _buildSpinning). So the FINAL kRows strip entries must be the
        // target window IN ORDER (NOT reversed) — otherwise the landing frame
        // and the subsequent static frame would show different symbols.
        ..addAll(window);
      _strip = <SlotSymbol>[..._strip, ...extra];

      final int targetTopIndex = _strip.length - window.length;
      _landTargetOffset = targetTopIndex * widget.cellHeight;
      _landStartOffset = _offset;
      _landElapsedMs = 0;
      _landDurationMs = slow ? 2200 : 850;
      _landing = true;
    }
  }

  List<SlotSymbol> _buildRandomStrip(int n) {
    // Weighted strip reused for scrolling. Bonus and wild are rarer here to
    // avoid teasing on every spin.
    const List<SlotSymbol> pool = <SlotSymbol>[
      SlotSymbol.ten,
      SlotSymbol.jack,
      SlotSymbol.queen,
      SlotSymbol.king,
      SlotSymbol.ace,
      SlotSymbol.cherry,
      SlotSymbol.bell,
      SlotSymbol.bar,
      SlotSymbol.chips,
      SlotSymbol.diamonds,
      SlotSymbol.crown,
      SlotSymbol.amazoncoin,
    ];
    return <SlotSymbol>[
      for (int i = 0; i < n; i++) pool[widget.random.nextInt(pool.length)],
    ];
  }

  // Smooth monotonic ease-out cubic. Chosen over quintic because the final
  // 20 % of the animation shouldn't be a long "settling" plateau — in slot
  // UX the perceived click should line up with the actual end so overlays
  // (anticipation glow, win highlight, …) can switch instantly.
  double _ease(double t) {
    final double x = 1 - t;
    return 1 - x * x * x;
  }

  void _onTick(Duration elapsed) {
    final DateTime now = DateTime.now();
    final int dtMs = now.difference(_lastTick).inMilliseconds.clamp(1, 64);
    _lastTick = now;

    if (_landing) {
      _landElapsedMs += dtMs;
      final double t =
          (_landElapsedMs / _landDurationMs).clamp(0.0, 1.0).toDouble();
      final double eased = _ease(t);
      _offset =
          _landStartOffset + (_landTargetOffset - _landStartOffset) * eased;

      // Snap-and-fire slightly before t == 1.0 when the remaining pixel
      // distance is sub-pixel. The visual difference is zero but the overlay
      // (anticipation / wins) can move to the next reel ~1 frame earlier,
      // which the player PERCEIVES as a sharper transition.
      final double remaining =
          (_landTargetOffset - _offset).abs();
      if (t >= 1.0 || (t > 0.9 && remaining < 1.0)) {
        _offset = _landTargetOffset;
        _landing = false;
        _ticker.stop();
        _window = List<SlotSymbol>.of(widget.controller.targetWindow!);
        setState(() {});
        widget.controller.markLanded();
        widget.onLanded?.call();
        return;
      }
    } else {
      _offset += _velocity * dtMs;
      // Recycle head when we've scrolled a full cell so the strip stays
      // bounded in memory.
      while (_offset > widget.cellHeight) {
        _offset -= widget.cellHeight;
        if (_strip.isNotEmpty) {
          _strip.removeAt(0);
          _strip.add(_buildRandomStrip(1).first);
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.cellHeight * kRows,
      width: widget.cellWidth,
      child: ClipRect(
        child: _landing || widget.controller.spinning
            ? _buildSpinning()
            : _buildStatic(),
      ),
    );
  }

  Widget _buildSpinning() {
    final int topIndex = (_offset / widget.cellHeight).floor();
    final double subOffset = _offset - topIndex * widget.cellHeight;

    final double speedBlur = _landing
        ? (1 - _landElapsedMs / _landDurationMs).clamp(0.0, 1.0)
        : 1.0;

    final List<Widget> tiles = <Widget>[];
    for (int i = -1; i < kRows + 1; i++) {
      final int idx = topIndex + i;
      final SlotSymbol s = (idx >= 0 && idx < _strip.length)
          ? _strip[idx]
          : SlotSymbol.ten;
      tiles.add(
        Positioned(
          top: i * widget.cellHeight - subOffset,
          left: 0,
          right: 0,
          height: widget.cellHeight,
          child: Opacity(
            opacity: speedBlur < 0.3 ? 1.0 : 0.9,
            child: SymbolTile(symbol: s),
          ),
        ),
      );
    }
    return Stack(children: tiles);
  }

  Widget _buildStatic() {
    final List<Widget> tiles = <Widget>[];
    for (int r = 0; r < kRows; r++) {
      final SlotSymbol s = (_window.length > r) ? _window[r] : SlotSymbol.ten;
      final double emph = widget.winRowEmphasis[r] ?? 0.0;
      tiles.add(
        Positioned(
          top: r * widget.cellHeight,
          left: 0,
          right: 0,
          height: widget.cellHeight,
          child: AnimatedBuilder(
            animation:
                widget.winRowAnimation ?? const AlwaysStoppedAnimation<double>(0),
            builder: (_, __) => SymbolTile(symbol: s, emphasis: emph),
          ),
        ),
      );
    }
    return Stack(children: tiles);
  }
}
