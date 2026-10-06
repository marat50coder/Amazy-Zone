import 'package:flutter/material.dart';

import '../game/symbols.dart';
import '../theme.dart';
import 'info_scaffold.dart';

/// Scrollable list of every symbol with its 3/4/5-of-a-kind payouts.
/// Payouts are shown as "x of bet-per-line" multipliers.
class PaytableScreen extends StatelessWidget {
  const PaytableScreen({super.key});

  // Group symbols by tier for the UI.
  static const List<_Section> _sections = <_Section>[
    _Section(
      title: 'HIGH-VALUE',
      symbols: <SlotSymbol>[
        SlotSymbol.amazoncoin,
        SlotSymbol.crown,
        SlotSymbol.diamonds,
        SlotSymbol.chips,
        SlotSymbol.bar,
        SlotSymbol.bell,
        SlotSymbol.cherry,
      ],
    ),
    _Section(
      title: 'LOW-VALUE',
      symbols: <SlotSymbol>[
        SlotSymbol.ace,
        SlotSymbol.king,
        SlotSymbol.queen,
        SlotSymbol.jack,
        SlotSymbol.ten,
      ],
    ),
    _Section(
      title: 'SPECIAL',
      symbols: <SlotSymbol>[SlotSymbol.wild, SlotSymbol.bonus],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return InfoScaffold(
      title: 'PAY TABLE',
      subtitle: 'Payouts × bet per line',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
        children: <Widget>[
          for (final _Section s in _sections) ...<Widget>[
            _SectionHeader(title: s.title),
            const SizedBox(height: 6),
            for (final SlotSymbol sym in s.symbols) ...<Widget>[
              _SymbolRow(symbol: sym),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 10),
          ],
          const _InfoBox(),
        ],
      ),
    );
  }
}

class _Section {
  const _Section({required this.title, required this.symbols});
  final String title;
  final List<SlotSymbol> symbols;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              height: 1,
              color: AmazyTheme.accentOrange.withValues(alpha: 0.35),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              title,
              style: const TextStyle(
                color: AmazyTheme.accentOrangeGlow,
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AmazyTheme.accentOrange.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymbolRow extends StatelessWidget {
  const _SymbolRow({required this.symbol});
  final SlotSymbol symbol;

  @override
  Widget build(BuildContext context) {
    final SymbolData d = symbolData(symbol);
    final bool isSpecial =
        symbol == SlotSymbol.wild || symbol == SlotSymbol.bonus;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (d.isHigh ? AmazyTheme.accentGold : AmazyTheme.accentOrange)
              .withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 56,
            height: 56,
            child: Image.asset(d.asset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          if (isSpecial)
            Expanded(child: _SpecialDescription(symbol: symbol))
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    _displayName(symbol),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _PayChip(count: 3, value: d.pay3),
                      _PayChip(count: 4, value: d.pay4),
                      _PayChip(count: 5, value: d.pay5),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _displayName(SlotSymbol s) {
    switch (s) {
      case SlotSymbol.ten:
        return 'TEN';
      case SlotSymbol.jack:
        return 'JACK';
      case SlotSymbol.queen:
        return 'QUEEN';
      case SlotSymbol.king:
        return 'KING';
      case SlotSymbol.ace:
        return 'ACE';
      case SlotSymbol.cherry:
        return 'CHERRY';
      case SlotSymbol.bell:
        return 'BELL';
      case SlotSymbol.bar:
        return 'BAR';
      case SlotSymbol.chips:
        return 'CHIPS';
      case SlotSymbol.diamonds:
        return 'DIAMOND';
      case SlotSymbol.crown:
        return 'CROWN';
      case SlotSymbol.amazoncoin:
        return 'A-COIN';
      case SlotSymbol.wild:
        return 'WILD';
      case SlotSymbol.bonus:
        return 'BONUS';
    }
  }
}

class _SpecialDescription extends StatelessWidget {
  const _SpecialDescription({required this.symbol});
  final SlotSymbol symbol;

  @override
  Widget build(BuildContext context) {
    final bool wild = symbol == SlotSymbol.wild;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          wild ? 'WILD' : 'BONUS',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          wild
              ? 'Substitutes for any symbol except BONUS. Also pays like a '
                  'premium symbol on its own.'
              : '3 scatter (1%) → Bronze Wheel (×1 … ×8)\n'
                  '4 scatter (0.75%) → Silver Wheel (×6 … ×50)\n'
                  '5 scatter (0.5%) → Gold Wheel (×25 … ×820)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 11,
            height: 1.35,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PayChip extends StatelessWidget {
  const _PayChip({required this.count, required this.value});
  final int count;
  final double value;

  @override
  Widget build(BuildContext context) {
    final bool none = value <= 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$count×',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          none ? '—' : '×${value.toStringAsFixed(value >= 10 ? 0 : 2)}',
          style: TextStyle(
            color: none
                ? Colors.white.withValues(alpha: 0.3)
                : AmazyTheme.accentOrangeGlow,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AmazyTheme.accentOrange.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'HOW PAYOUTS WORK',
            style: TextStyle(
              color: AmazyTheme.accentOrangeGlow,
              fontSize: 12,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '• Payouts are in fans. NO REAL MONEY.\n'
                '• Figures are multipliers of the bet-per-line '
                '(total bet ÷ 25).\n'
                '• Pays only count from the leftmost reel moving right along '
                'a payline.\n'
                '• The wild substitutes for any symbol except bonus.\n'
                '• Bonus scatters trigger the wheel regardless of position.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.45,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
