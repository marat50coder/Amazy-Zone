import 'package:flutter/foundation.dart';

/// A payline is an ordered list of row-indices (0..3), one entry per reel.
@immutable
class Payline {
  const Payline(this.index, this.rows, this.color);

  final int index; // 1..25 for display
  final List<int> rows; // length == 5
  final int color; // ARGB
}

/// 25 industry-standard paylines across a 5x4 grid (rows 0..3).
///
/// Row 0 = top, row 3 = bottom.
const List<Payline> kPaylines = <Payline>[
  // --- 4 straight horizontals ---
  Payline(1, <int>[1, 1, 1, 1, 1], 0xFFFF8A1C), // row 2 - orange
  Payline(2, <int>[0, 0, 0, 0, 0], 0xFF35E07E), // row 1 - green
  Payline(3, <int>[2, 2, 2, 2, 2], 0xFF2BC2FF), // row 3 - cyan
  Payline(4, <int>[3, 3, 3, 3, 3], 0xFFFF3B4A), // row 4 - red
  // --- Vs & inverted Vs ---
  Payline(5, <int>[0, 1, 2, 1, 0], 0xFFBD6AFF),
  Payline(6, <int>[3, 2, 1, 2, 3], 0xFFFFD56A),
  Payline(7, <int>[1, 2, 3, 2, 1], 0xFF52FFC9),
  Payline(8, <int>[2, 1, 0, 1, 2], 0xFFFF7E9D),
  // --- Zig-zags ---
  Payline(9, <int>[0, 1, 0, 1, 0], 0xFFFFA726),
  Payline(10, <int>[1, 2, 1, 2, 1], 0xFF4CAF50),
  Payline(11, <int>[2, 3, 2, 3, 2], 0xFF29B6F6),
  Payline(12, <int>[1, 0, 1, 0, 1], 0xFF9575CD),
  Payline(13, <int>[2, 1, 2, 1, 2], 0xFFF06292),
  Payline(14, <int>[3, 2, 3, 2, 3], 0xFFCE93D8),
  // --- Mixed step lines ---
  Payline(15, <int>[0, 0, 1, 2, 2], 0xFFFFEB3B),
  Payline(16, <int>[3, 3, 2, 1, 1], 0xFF80DEEA),
  Payline(17, <int>[0, 1, 2, 3, 3], 0xFFFF6E40),
  Payline(18, <int>[3, 2, 1, 0, 0], 0xFF69F0AE),
  Payline(19, <int>[1, 2, 1, 0, 1], 0xFFFFAB91),
  Payline(20, <int>[2, 1, 2, 3, 2], 0xFF90CAF9),
  Payline(21, <int>[0, 2, 0, 2, 0], 0xFFFFD180),
  Payline(22, <int>[3, 1, 3, 1, 3], 0xFFCCFF90),
  Payline(23, <int>[1, 1, 2, 1, 1], 0xFFF48FB1),
  Payline(24, <int>[2, 2, 1, 2, 2], 0xFF81D4FA),
  Payline(25, <int>[0, 3, 0, 3, 0], 0xFFE1BEE7),
];

const int kReels = 5;
const int kRows = 4;
