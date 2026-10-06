import 'package:flutter/material.dart';

import '../screens/webview_screen.dart';
import '../theme.dart';

const String kPrivacyUrl = 'https://amazyzone.store/privacy-policy.html';
const String kSupportUrl = 'https://amazyzone.store/support.html';

/// Settings sheet that slides up from the bottom. Hosts RTP info plus links
/// to the privacy policy and support site opened in a native WebView.
class MenuSheet extends StatelessWidget {
  const MenuSheet({super.key, this.onBackToMenu});

  /// If provided, shows a "Back to menu" button at the top of the sheet.
  final VoidCallback? onBackToMenu;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: AmazyTheme.panelDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AmazyTheme.accentOrange.withValues(alpha: 0.7),
            width: 1.3,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AmazyTheme.accentOrange.withValues(alpha: 0.4),
              blurRadius: 24,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        // The sheet can grow slightly taller than the default modal cap on
        // short screens (notably when the "Main Menu" button is present).
        // Making its body scrollable fixes the "BOTTOM OVERFLOWED BY N px"
        // yellow-black warning without affecting taller phones.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AmazyTheme.accentOrangeGlow.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'SETTINGS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _InfoRow(label: 'LINES', value: '25'),
              const SizedBox(height: 4),
              _InfoRow(label: 'REELS', value: '5 × 4'),
              const SizedBox(height: 4),
              _InfoRow(label: 'RTP', value: '98.00%'),
              const SizedBox(height: 4),
              _InfoRow(label: 'VERSION', value: '1.0.0'),
              const SizedBox(height: 14),
              if (onBackToMenu != null) ...<Widget>[
                _MenuButton(
                  label: 'MAIN MENU',
                  icon: Icons.home_outlined,
                  onTap: onBackToMenu!,
                ),
                const SizedBox(height: 8),
              ],
              _MenuButton(
                label: 'PRIVACY POLICY',
                icon: Icons.shield_outlined,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WebDocScreen(
                        title: 'Privacy Policy',
                        url: kPrivacyUrl,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _MenuButton(
                label: 'SUPPORT',
                icon: Icons.help_outline,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WebDocScreen(
                        title: 'Support',
                        url: kSupportUrl,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MenuButton(
                label: 'CLOSE',
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(),
                outlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AmazyTheme.accentOrangeGlow,
            fontSize: 14,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          gradient: outlined
              ? null
              : const LinearGradient(
                  colors: <Color>[
                    Color(0xFFFFC37A),
                    Color(0xFFFF8A1C),
                    Color(0xFFE55A00),
                  ],
                ),
          color: outlined ? AmazyTheme.bgDark : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AmazyTheme.accentOrange.withValues(alpha: 0.9),
            width: 1.4,
          ),
          boxShadow: outlined
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: AmazyTheme.accentOrange.withValues(alpha: 0.5),
                    blurRadius: 18,
                  ),
                ],
        ),
        child: Row(
          children: <Widget>[
            Icon(icon,
                color: outlined
                    ? AmazyTheme.accentOrangeGlow
                    : Colors.white,
                size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  fontSize: 14,
                  shadows: outlined
                      ? null
                      : const <Shadow>[
                          Shadow(color: Colors.black, blurRadius: 4),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
