import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../theme/king_theme.dart';
import 'playing_card_widget.dart';

/// The middle of the table during a trick: whose turn it is, and all 3
/// seats' cards for the current trick shown together as one shared
/// pile — left seat's card on the left, your own in the middle, right
/// seat's on the right — rather than scattered next to each avatar.
/// Empty seats get a faint outline the same size as a card, so the row
/// stays in the same symmetric layout as cards fill in one by one.
class TrickCenter extends StatelessWidget {
  final String turnText;
  final PlayingCard? leftCard;
  final PlayingCard? myCard;
  final PlayingCard? rightCard;

  const TrickCenter({
    super.key,
    required this.turnText,
    required this.leftCard,
    required this.myCard,
    required this.rightCard,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              turnText,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // FittedBox guards against a narrow center column (a short
            // landscape phone splits width 3 ways: opponent, this, the
            // other opponent) — three fixed card-sized slots side by
            // side don't always fit at full size, so this scales the
            // whole row down together rather than letting it overflow.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _slot(leftCard),
                  const SizedBox(width: 10),
                  _slot(myCard),
                  const SizedBox(width: 10),
                  _slot(rightCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slot(PlayingCard? card) {
    if (card != null) return PlayingCardWidget(card: card, enabled: false);
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KingColors.onFeltHairline, width: 1),
      ),
    );
  }
}
