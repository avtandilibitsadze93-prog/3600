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
///
/// Bottom-anchored with the same 12px clearance as SeatBadge's own
/// card slot, so all 3 played cards — left, mine, right — sit in one
/// straight, symmetric row right above the hand, rather than at
/// whatever height each column's differently-tall content (just "Your
/// turn" here vs. a full avatar+name on the sides) happens to center
/// its content around.
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
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              turnText,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const ValueKey('card_slot_mine'),
              child: myCard != null
                  ? PlayingCardWidget(card: myCard!, enabled: false)
                  : Container(
                      width: 56,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: KingColors.onFeltHairline, width: 1),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
