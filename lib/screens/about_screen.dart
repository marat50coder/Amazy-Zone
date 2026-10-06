import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/menu_sheet.dart';
import 'info_scaffold.dart';
import 'webview_screen.dart';

/// Game information screen. Describes mechanics, lists the bonus tiers and
/// surfaces Privacy / Support links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoScaffold(
      title: 'ABOUT',
      subtitle: 'Game rules & info',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
        children: <Widget>[
          _InfoCard(
            title: 'OVERVIEW',
            children: <Widget>[
              _StatRow(label: 'REELS', value: '5 × 4'),
              _StatRow(label: 'PAYLINES', value: '25 (fixed)'),
              _StatRow(label: 'RTP', value: '98.00%'),
              _StatRow(label: 'MIN BET', value: '0.25 fans'),
              _StatRow(label: 'MAX BET', value: '100.00 fans'),
              _StatRow(label: 'CURRENCY', value: 'NO REAL MONEY'),
              _StatRow(label: 'VOLATILITY', value: 'HIGH'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'BONUS WHEEL',
            children: <Widget>[
              _TierRow(
                color: Color(0xFFCD7F32),
                label: 'BRONZE',
                condition: '3 BONUS',
                range: '×1 … ×8',
              ),
              _TierRow(
                color: Color(0xFFC0C0D0),
                label: 'SILVER',
                condition: '4 BONUS',
                range: '×6 … ×50',
              ),
              _TierRow(
                color: Color(0xFFFFCA3A),
                label: 'GOLD',
                condition: '5 BONUS',
                range: '×25 … ×820',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'BIG WIN TIERS',
            children: <Widget>[
              _StatRow(label: '20× BET', value: 'BIG WIN'),
              _StatRow(label: '50× BET', value: 'MEGA WIN'),
              _StatRow(label: '100× BET', value: 'EPIC WIN'),
              _StatRow(label: '500× BET', value: 'ULTIMATE WIN'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'HOW TO PLAY',
            children: <Widget>[
              _Para(
                '1.  Choose your total bet with the ‹ and › arrows below the reels.\n'
                '2.  Press the glowing SPIN button to start the reels.\n'
                '3.  Matching symbols on an active payline (left-to-right) pay out instantly.\n'
                '4.  Three or more BONUS scatters trigger the Bonus Wheel for a guaranteed prize.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LinkButton(
            label: 'PRIVACY POLICY',
            icon: Icons.shield_outlined,
            onTap: () => _open(context, 'Privacy Policy', kPrivacyUrl),
          ),
          const SizedBox(height: 10),
          _LinkButton(
            label: 'SUPPORT',
            icon: Icons.help_outline,
            onTap: () => _open(context, 'Support', kSupportUrl),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              '© Amazy Zone • v1.0.0',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext ctx, String title, String url) {
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => WebDocScreen(title: title, url: url),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AmazyTheme.accentOrange.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AmazyTheme.accentOrange.withValues(alpha: 0.2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: AmazyTheme.accentOrangeGlow,
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.color,
    required this.label,
    required this.condition,
    required this.range,
  });

  final Color color;
  final String label;
  final String condition;
  final String range;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: color.withValues(alpha: 0.9), blurRadius: 10),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          SizedBox(
            width: 86,
            child: Text(
              condition,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Spacer(),
          Text(
            range,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Para extends StatelessWidget {
  const _Para(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.82),
        fontSize: 12.5,
        height: 1.5,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AmazyTheme.accentOrange.withValues(alpha: 0.85),
            width: 1.4,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AmazyTheme.accentOrange.withValues(alpha: 0.3),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AmazyTheme.accentOrangeGlow, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.open_in_new,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
