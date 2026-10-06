import 'package:flutter/material.dart';

import '../game/symbols.dart';
import '../theme.dart';

/// A single square tile showing a symbol. [emphasis] 0..1 drives a glow/scale
/// effect used when the symbol belongs to a winning line.
class SymbolTile extends StatelessWidget {
  const SymbolTile({
    super.key,
    required this.symbol,
    this.emphasis = 0.0,
    this.anticipation = 0.0,
  });

  final SlotSymbol symbol;
  final double emphasis;
  final double anticipation;

  @override
  Widget build(BuildContext context) {
    final SymbolData data = symbolData(symbol);
    final double scale = 1.0 + emphasis * 0.12 + anticipation * 0.08;
    final double glow = emphasis * 24 + anticipation * 18;
    final bool isBonus = symbol == SlotSymbol.bonus;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double side = (c.biggest.shortestSide).clamp(0.0, double.infinity);
        return Center(
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: side,
              height: side,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: <BoxShadow>[
                  if (glow > 0)
                    BoxShadow(
                      color: (isBonus
                              ? AmazyTheme.accentOrange
                              : (data.isHigh
                                  ? AmazyTheme.accentGold
                                  : AmazyTheme.accentOrangeGlow))
                          .withValues(alpha: 0.95),
                      blurRadius: glow,
                      spreadRadius: emphasis * 2,
                    ),
                ],
              ),
              child: Image.asset(
                data.asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        );
      },
    );
  }
}
