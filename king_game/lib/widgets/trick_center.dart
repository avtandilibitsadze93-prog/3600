import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import 'playing_card_widget.dart';

// One fixed slot per play order (not per seat) — the same 3 offsets
// every trick, however few or many cards are down so far. Matches the
// "cards tossed into a small pile" look real trick-taking apps use
// instead of scattering cards next to each player's own avatar. Spread
// wide/rotated enough that each card is clearly its own card, not a
// barely-offset stack that reads as one card with a sliver behind it.
const List<Offset> _slotOffsets = [Offset(-28, 14), Offset(0, -10), Offset(28, 16)];
const List<double> _slotRotations = [-0.30, 0.08, 0.34];

/// The middle of the table during a trick: whose turn it is, and every
/// card played so far this trick, piled together — the first card
/// played sits at the back of the pile, each next one lands on top of
/// it, the way actually tossing cards onto a table would stack them.
/// [playedCardsInOrder] must already be in play order (index 0 = led
/// first).
class TrickCenter extends StatelessWidget {
  final String turnText;
  final List<PlayingCard> playedCardsInOrder;

  const TrickCenter({
    super.key,
    required this.turnText,
    required this.playedCardsInOrder,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              turnText,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              // Wide/tall enough for the fan's offsets plus a full card
              // on every side, regardless of how many cards are down —
              // padded further than the raw offsets need, since
              // rotating a card also grows its own bounding box.
              width: 56 + 2 * 40,
              height: 80 + 2 * 30,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Stack paints children in list order, later on top —
                  // that alone gives the "first played sits at the
                  // back" ordering, no explicit z-index needed.
                  for (var i = 0; i < playedCardsInOrder.length; i++)
                    Transform.translate(
                      offset: _slotOffsets[i],
                      child: Transform.rotate(
                        angle: _slotRotations[i],
                        child: PlayingCardWidget(card: playedCardsInOrder[i], enabled: false),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
