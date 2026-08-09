import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../theme/king_theme.dart';

class PlayingCardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool enabled;
  final bool selected;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.enabled = true,
    this.selected = false,
    this.onTap,
  });

  String get _suitSymbol {
    switch (card.suit) {
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
    }
  }

  bool get _isRed => card.suit == Suit.hearts || card.suit == Suit.diamonds;

  @override
  Widget build(BuildContext context) {
    final inkColor = _isRed ? KingColors.brickRed : KingColors.inkNavy;
    final color = enabled ? inkColor : inkColor.withValues(alpha: 0.35);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 80,
        margin: EdgeInsets.only(bottom: selected ? 16 : 0),
        decoration: BoxDecoration(
          color: enabled ? KingColors.cream : KingColors.creamMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? KingColors.gold : KingColors.inkNavy.withValues(alpha: 0.25),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 3, offset: Offset(1, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.rank.georgianName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: card.rank.georgianName.length > 2 ? 13 : 18,
                color: color,
              ),
            ),
            Text(_suitSymbol, style: TextStyle(fontSize: 20, color: color)),
          ],
        ),
      ),
    );
  }
}
