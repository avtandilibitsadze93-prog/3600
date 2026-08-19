import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../theme/king_theme.dart';

/// A standard playing card's own layout — rank+suit as a small "index"
/// in the top-left corner and the same index rotated 180° in the
/// bottom-right, with a single big suit pip centered — instead of a
/// licensed deck's face-card illustrations, which this deliberately
/// doesn't reproduce.
class PlayingCardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool enabled;
  final bool dimmed;
  final bool selected;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.enabled = true,
    this.dimmed = false,
    this.selected = false,
    this.onTap,
  });

  bool get _isRed => card.suit == Suit.hearts || card.suit == Suit.diamonds;

  @override
  Widget build(BuildContext context) {
    final inkColor = _isRed ? KingColors.brickRed : KingColors.inkNavy;
    // dimmed, not enabled, drives how the card LOOKS — a card that's
    // just not tappable (a played card sitting in the trick pile, a
    // hand preview during declaring) is still a real, fully-visible
    // card, not one you're being told you can't currently play.
    final color = dimmed ? inkColor.withValues(alpha: 0.35) : inkColor;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 80,
        margin: EdgeInsets.only(bottom: selected ? 16 : 0),
        decoration: BoxDecoration(
          color: dimmed ? KingColors.creamMuted : KingColors.cream,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? KingColors.gold : KingColors.inkNavy.withValues(alpha: 0.25),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(1, 2)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(top: 4, left: 5, child: _CornerIndex(card: card, color: color)),
            Center(child: Text(card.suit.symbol, style: TextStyle(fontSize: 26, color: color))),
            Positioned(
              bottom: 4,
              right: 5,
              child: Transform.rotate(angle: math.pi, child: _CornerIndex(card: card, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerIndex extends StatelessWidget {
  final PlayingCard card;
  final Color color;
  const _CornerIndex({required this.card, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          card.rank.englishName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, height: 1, color: color),
        ),
        Text(card.suit.symbol, style: TextStyle(fontSize: 10, height: 1, color: color)),
      ],
    );
  }
}
