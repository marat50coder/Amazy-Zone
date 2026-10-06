import 'package:flutter/material.dart';

/// Play-money unit. Nothing in the game is redeemable for cash.
const String kNoRealMoney = 'NO REAL MONEY';

String formatFans(double value) => '${value.toStringAsFixed(2)} fans';

class AmazyTheme {
  static const Color bgDark = Color(0xFF0A0A0C);
  static const Color panelDark = Color(0xFF131319);
  static const Color accentOrange = Color(0xFFFF8A1C);
  static const Color accentOrangeDeep = Color(0xFFE55A00);
  static const Color accentOrangeGlow = Color(0xFFFFC37A);
  static const Color accentSilver = Color(0xFFCFCFD4);
  static const Color accentGold = Color(0xFFFFD56A);
  static const Color accentRed = Color(0xFFFF3B4A);
  static const Color accentGreen = Color(0xFF35E07E);

  static const List<Color> fireGradient = <Color>[
    Color(0xFFFFDBA1),
    Color(0xFFFFA23A),
    Color(0xFFFF6A00),
    Color(0xFFC13A00),
  ];

  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentOrange,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      );
}
