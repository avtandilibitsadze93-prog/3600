import 'package:flutter/material.dart';

import '../theme/king_theme.dart';

/// A small round icon button that sits directly on the felt — no
/// AppBar surface behind it — for controls (leave game, score table)
/// that used to live in an AppBar before the game screens went
/// full-bleed.
class CornerIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;

  const CornerIconButton({super.key, required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: KingColors.feltDark,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: KingColors.onFeltSoft),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
