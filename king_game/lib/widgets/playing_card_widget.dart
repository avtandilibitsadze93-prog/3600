import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

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
    final baseColor = _isRed ? Colors.red.shade700 : Colors.black87;
    final color = enabled ? baseColor : Colors.grey.shade500;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 80,
        margin: EdgeInsets.only(bottom: selected ? 16 : 0),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.blueAccent : Colors.black26,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 2, offset: Offset(1, 1)),
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
