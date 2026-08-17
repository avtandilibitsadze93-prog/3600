import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/game_controller.dart';
import '../game/local_table_client.dart';
import '../widgets/card_sort.dart';
import '../widgets/game_table_shell.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/seat_badge.dart';
import '../widgets/trick_center.dart';

/// The active player's turn within a trick: shows what's already been
/// played to the table this trick (public — every player at a real table
/// would already have seen it) and the active player's own hand, with
/// illegal cards (per [GameController.legalMovesForActivePlayer]) greyed
/// out so a wrong tap is never even possible.
///
/// Built off the exact same [GameTableShell]/[SeatBadge] as
/// [OnlineTrickScreen] — see [DeclarationScreen] for why. Since this
/// screen is only ever shown to the player whose turn it currently is
/// (there's no waiting-for-someone-else view locally — that's what
/// device handoff is for), it's always "your turn" from here.
class TrickScreen extends StatelessWidget {
  final GameController controller;
  const TrickScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final client = LocalTableClient(controller);
    final trick = controller.currentTrick!;
    final legal = controller.legalMovesForActivePlayer;
    final hand = sortedForDisplay(controller.activePlayer.hand);

    final mySeat = client.mySeat!;
    final rightSeat = (mySeat + 1) % 3;
    final leftSeat = (mySeat + 2) % 3;

    PlayingCard? cardPlayedBy(int seat) {
      for (final play in trick.plays) {
        if (play.playerId == seat) return play.card;
      }
      return null;
    }

    return GameTableShell(
      client: client,
      leftSeat: SeatBadge(
        client: client,
        seat: leftSeat,
        showCardSlot: true,
        playedCard: cardPlayedBy(leftSeat),
      ),
      rightSeat: SeatBadge(
        client: client,
        seat: rightSeat,
        showCardSlot: true,
        playedCard: cardPlayedBy(rightSeat),
      ),
      center: TrickCenter(
        turnText: 'Your turn',
        myCard: cardPlayedBy(mySeat),
      ),
      hand: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final card in hand)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PlayingCardWidget(
                  key: ValueKey(card),
                  card: card,
                  enabled: legal.contains(card),
                  onTap: () => controller.playCard(card),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
