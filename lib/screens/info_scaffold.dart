import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/animated_background.dart';

/// Shared chrome for secondary screens (Paylines, Pay Table, About).
/// Provides the themed app bar, animated background and a back arrow.
class InfoScaffold extends StatelessWidget {
  const InfoScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmazyTheme.bgDark,
      body: AnimatedGameBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _TitleBar(title: title, subtitle: subtitle),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 14),
      child: Row(
        children: <Widget>[
          _BackPill(onTap: () => Navigator.of(context).maybePop()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    shadows: <Shadow>[
                      Shadow(
                        color:
                            AmazyTheme.accentOrange.withValues(alpha: 0.85),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackPill extends StatelessWidget {
  const _BackPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.55),
          border: Border.all(
            color: AmazyTheme.accentOrange.withValues(alpha: 0.85),
            width: 1.4,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AmazyTheme.accentOrange.withValues(alpha: 0.45),
              blurRadius: 14,
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AmazyTheme.accentOrangeGlow,
          size: 22,
        ),
      ),
    );
  }
}
