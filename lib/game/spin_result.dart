import 'package:flutter/foundation.dart';

import 'symbols.dart';

/// A single line-win description.
@immutable
class LineWin {
  const LineWin({
    required this.paylineIndex,
    required this.rows,
    required this.symbol,
    required this.matchCount,
    required this.multiplier,
    required this.amount,
    required this.color,
  });

  final int paylineIndex; // 1..25
  final List<int> rows; // length == 5 (full line definition)
  final SlotSymbol symbol;
  final int matchCount; // 3, 4 or 5 (positions 0..matchCount-1)

  /// Paytable multiplier for this hit (×3 / ×4 / ×5 of the stake unit).
  final double multiplier;
  final double amount; // in currency units for the active bet
  final int color;
}

enum BonusTier { none, bronze, silver, gold }

@immutable
class SpinResult {
  const SpinResult({
    required this.grid,
    required this.lineWins,
    required this.scatterCount,
    required this.scatterPositions,
    required this.scatterPay,
    required this.bonusTier,
    required this.totalLinePay,
  });

  /// grid[reel][row], reel 0..4, row 0..3.
  final List<List<SlotSymbol>> grid;
  final List<LineWin> lineWins;
  final int scatterCount;
  final List<List<int>> scatterPositions; // list of [reel, row]
  final double scatterPay;
  final BonusTier bonusTier;
  final double totalLinePay;

  double get totalPay => totalLinePay + scatterPay;
}
