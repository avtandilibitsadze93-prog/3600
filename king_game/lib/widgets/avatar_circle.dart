import 'package:flutter/material.dart';

import '../models/avatar.dart';
import '../theme/king_theme.dart';

/// Renders a player's chosen [AvatarOption] as a gold-rimmed circle —
/// the small per-seat portrait shown next to names across the online
/// screens, standing in for a real profile photo.
class AvatarCircle extends StatelessWidget {
  final String? avatarId;
  final double radius;
  final bool dimmed;

  const AvatarCircle({super.key, this.avatarId, this.radius = 20, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    // Blended into each layer's own color/alpha rather than wrapping
    // everything in an Opacity widget — Opacity's conditional semantics
    // node has been observed to trip a debug-mode semantics assertion
    // when this widget sits inside a Positioned (e.g. the standings
    // panel floating over the table).
    final borderAlpha = dimmed ? 0.5 : 1.0;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KingColors.feltLight.withValues(alpha: borderAlpha),
        border: Border.all(color: KingColors.gold.withValues(alpha: borderAlpha), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        avatarById(avatarId).emoji,
        style: TextStyle(fontSize: radius, color: Colors.white.withValues(alpha: borderAlpha)),
      ),
    );
  }
}
