import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../theme/king_theme.dart';
import 'playing_card_widget.dart';

/// The middle of the table during a trick: whose turn it is, and your
/// own card for the current trick — sitting right above your own
/// avatar/hand below, the same way each opponent's card now sits right
/// under their own seat (see SeatBadge's showCardSlot) instead of every
/// played card being piled together in one spot unconnected to whose
/// card is whose.
class TrickCenter extends StatelessWidget {
  final String turnText;
  final PlayingCard? myCard;

  const TrickCenter({
    super.key,
    required this.turnText,
    required this.myCard,
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
            myCard != null
                ? PlayingCardWidget(card: myCard!, enabled: false)
                : Container(
                    width: 56,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: KingColors.onFeltHairline, width: 1),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
