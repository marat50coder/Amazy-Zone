import 'dart:math';

import 'paylines.dart';
import 'spin_result.dart';
import 'symbols.dart';

/// Multiplier applied to each symbol's base weight. Any entry not in the map
/// uses weight = 1 (unchanged). This is the hook we use to make the game
/// drastically more generous during development (see [SlotEngine.new]).
typedef SymbolWeightOverride = Map<SlotSymbol, int>;

/// Weighted reel strip. We build it once from [kSymbolRegistry] and reuse per
/// reel. The strip is just a flat list where each symbol is repeated according
/// to its weight so [Random.nextInt] on the length yields a weighted pick.
class _ReelStrip {
  _ReelStrip({
    SymbolWeightOverride overrides = const <SlotSymbol, int>{},
    bool absolute = false,
  }) {
    final List<SlotSymbol> builder = <SlotSymbol>[];
    for (final SymbolData s in kSymbolRegistry.values) {
      final int w;
      if (absolute && overrides.containsKey(s.symbol)) {
        // In absolute mode the override is the FINAL weight (base weight is
        // ignored). This lets us dial individual symbol frequency precisely,
        // e.g. to raise premium weights while LOWERING low-value weights.
        w = overrides[s.symbol]!;
      } else {
        w = s.weight * (overrides[s.symbol] ?? 1);
      }
      for (int i = 0; i < w; i++) {
        builder.add(s.symbol);
      }
    }
    strip = List<SlotSymbol>.unmodifiable(builder);
  }

  late final List<SlotSymbol> strip;

  SlotSymbol pick(Random r) => strip[r.nextInt(strip.length)];
}

/// Scatter never comes from the strip. Counts are drawn from
/// [_kScatterLadder] so the bonus odds stay exact.
const SymbolWeightOverride _kStripOverrides = <SlotSymbol, int>{
  SlotSymbol.bonus: 0,
};

/// Cumulative probability ladder for scatter counts on a single spin.
/// Reading top-down: the first bucket whose upper bound exceeds the drawn
/// `nextDouble()` wins. Must stay sorted in increasing bound order.
///
///   P(5 scatters) = 0.50 %   → Gold wheel
///   P(4 scatters) = 0.75 %   → Silver wheel
///   P(3 scatters) = 1.00 %   → Bronze wheel
///   P(2 scatters) = 2.00 %   → anticipation only, no wheel
const List<_ScatterBucket> _kScatterLadder = <_ScatterBucket>[
  _ScatterBucket(upperBound: 0.0050, count: 5),
  _ScatterBucket(upperBound: 0.0125, count: 4),
  _ScatterBucket(upperBound: 0.0225, count: 3),
  _ScatterBucket(upperBound: 0.0425, count: 2),
];

class _ScatterBucket {
  const _ScatterBucket({required this.upperBound, required this.count});
  final double upperBound;
  final int count;
}

class SlotEngine {
  SlotEngine({Random? random, bool? debugBoost})
      : _random = random ?? Random(),
        _strip = _ReelStrip(overrides: _kStripOverrides) {
    // Debug and release share one model. The flag is accepted so older
    // call sites keep compiling.
    assert(debugBoost == null || debugBoost == true || debugBoost == false);
  }

  final Random _random;
  final _ReelStrip _strip;

  /// Advertised return-to-player.
  static const double rtp = 0.98;

  /// Perform one spin for the given [totalBet].
  ///
  /// [totalBet] is the total bet across all 25 paylines (so bet-per-line
  /// equals [totalBet] / 25).
  SpinResult spin({required double totalBet}) {
    // 1. Fill the grid from the natural reel strip (no scatters yet).
    final List<List<SlotSymbol>> grid = _fillGrid();

    // 2. Place scatters from the fixed ladder.
    // Winning cells are avoided when another row on that reel is free, so a
    // scatter doesn't silently delete the line the player is about to see.
    _placeScatters(grid, totalBet);

    return _score(grid, totalBet);
  }

  List<List<SlotSymbol>> _fillGrid() {
    return List<List<SlotSymbol>>.generate(
      kReels,
      (_) => List<SlotSymbol>.generate(kRows, (_) => _strip.pick(_random)),
    );
  }

  void _placeScatters(List<List<SlotSymbol>> grid, double totalBet) {
    int scatterCount = 0;
    final double scatterRoll = _random.nextDouble();
    for (final _ScatterBucket b in _kScatterLadder) {
      if (scatterRoll < b.upperBound) {
        scatterCount = b.count;
        break;
      }
    }
    if (scatterCount == 0) return;

    final Set<int> protected = <int>{};
    for (final Payline line in kPaylines) {
      final LineWin? win = _evaluateLine(line, grid, totalBet);
      if (win == null) continue;
      for (int r = 0; r < win.matchCount; r++) {
        protected.add(r * kRows + win.rows[r]);
      }
    }

    final List<int> reels = List<int>.generate(kReels, (int i) => i)
      ..shuffle(_random);
    for (int i = 0; i < scatterCount; i++) {
      final int reel = reels[i];
      final List<int> rows = List<int>.generate(kRows, (int r) => r)
        ..shuffle(_random);
      int chosen = rows.first;
      for (final int row in rows) {
        if (!protected.contains(reel * kRows + row)) {
          chosen = row;
          break;
        }
      }
      grid[reel][chosen] = SlotSymbol.bonus;
    }
  }

  SpinResult _score(List<List<SlotSymbol>> grid, double totalBet) {
    // 2. Evaluate line wins.
    final List<LineWin> wins = <LineWin>[];
    double totalLinePay = 0;
    for (final Payline line in kPaylines) {
      final LineWin? win = _evaluateLine(line, grid, totalBet);
      if (win != null) {
        wins.add(win);
        totalLinePay += win.amount;
      }
    }

    // 3. Scatter / bonus. (Positions are reconstructed from the grid rather
    // than tracked during injection so any dedup is captured.)
    final List<List<int>> scatterPositions = <List<int>>[];
    for (int r = 0; r < kReels; r++) {
      for (int row = 0; row < kRows; row++) {
        if (grid[r][row] == SlotSymbol.bonus) {
          scatterPositions.add(<int>[r, row]);
        }
      }
    }
    final int scatterCount = scatterPositions.length;
    double scatterPay = 0;
    BonusTier tier = BonusTier.none;
    switch (scatterCount) {
      case 2:
        scatterPay = totalBet * 0.5;
        break;
      case 3:
        scatterPay = totalBet * 1.0;
        tier = BonusTier.bronze;
        break;
      case 4:
        scatterPay = totalBet * 2.0;
        tier = BonusTier.silver;
        break;
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
      case 11:
      case 12:
      case 13:
      case 14:
      case 15:
      case 16:
      case 17:
      case 18:
      case 19:
      case 20:
        scatterPay = totalBet * 5.0;
        tier = BonusTier.gold;
        break;
    }

    return SpinResult(
      grid: grid,
      lineWins: wins,
      scatterCount: scatterCount,
      scatterPositions: scatterPositions,
      scatterPay: scatterPay,
      bonusTier: tier,
      totalLinePay: totalLinePay,
    );
  }

  LineWin? _evaluateLine(
    Payline line,
    List<List<SlotSymbol>> grid,
    double totalBet,
  ) {
    final List<SlotSymbol> lineSymbols = <SlotSymbol>[
      for (int r = 0; r < kReels; r++) grid[r][line.rows[r]],
    ];

    // Paytable multipliers apply to the bet on one line (total bet ÷ 25).
    final double unit = totalBet / kPaylines.length;

    LineWin? best;

    void consider(SlotSymbol anchor, int matches) {
      if (matches < 3 || anchor == SlotSymbol.bonus) return;
      final SymbolData data = symbolData(anchor);
      final double multiplier = switch (matches) {
        3 => data.pay3,
        4 => data.pay4,
        _ => data.pay5,
      };
      if (multiplier <= 0) return;
      final double amount = multiplier * unit;
      if (best != null && amount <= best!.amount) return;
      best = LineWin(
        paylineIndex: line.index,
        rows: line.rows,
        symbol: anchor,
        matchCount: matches,
        multiplier: multiplier,
        amount: amount,
        color: line.color,
      );
    }

    // A leading run of wilds is its own win (wild ×3/×4/×5). Without this,
    // WILD WILD WILD WILD TEN is paid as five tens — the glow sits on the
    // wilds, but the cash is the cheap symbol.
    int wildRun = 0;
    for (final SlotSymbol s in lineSymbols) {
      if (s != SlotSymbol.wild) break;
      wildRun++;
    }
    if (wildRun >= 3) consider(SlotSymbol.wild, wildRun);

    // Wilds also substitute into the first real symbol from the left.
    // Whichever reading pays more is the one we keep (and highlight).
    SlotSymbol? anchor;
    for (final SlotSymbol s in lineSymbols) {
      if (s == SlotSymbol.bonus) break;
      if (s != SlotSymbol.wild) {
        anchor = s;
        break;
      }
    }
    if (anchor != null) {
      int matches = 0;
      for (final SlotSymbol s in lineSymbols) {
        if (s == anchor || s == SlotSymbol.wild) {
          matches++;
        } else {
          break;
        }
      }
      consider(anchor, matches);
    }

    return best;
  }
}
