import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
import '../widgets/card_sort.dart';
import '../widgets/game_table_shell.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/seat_badge.dart';
import '../widgets/trick_center.dart';

/// Always shows the table and your own hand — there's no device handoff
/// online, your own screen just waits (cards greyed out) when it's not
/// your turn. Legal cards are computed locally via the shared engine's
/// pure [legalMoves], re-validated authoritatively by the server.
///
/// Table layout mirrors a real seat at a 3-player table: the seat that
/// plays right after you sits to your right, the one that plays before
/// you (i.e. right before it comes back to you) sits to your left, and
/// your own hand runs along the bottom edge.
class OnlineTrickScreen extends StatelessWidget {
  final OnlineGameClient client;
  const OnlineTrickScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final hand = sortedForDisplay(client.yourHand);
    final legal = client.isMyTurnToPlay
        ? legalMoves(
            hand: hand,
            alreadyPlayedThisTrick: client.trick.map((p) => p.card).toList(),
            contract: client.contract!,
          )
        : const <PlayingCard>[];

    final mySeat = client.mySeat!;
    final rightSeat = (mySeat + 1) % 3;
    final leftSeat = (mySeat + 2) % 3;

    PlayingCard? cardPlayedBy(int seat) {
      for (final play in client.trick) {
        if (play.playerId == seat) return play.card;
      }
      return null;
    }

    return GameTableShell(
      client: client,
      leftSeat: SeatBadge(client: client, seat: leftSeat, isTurn: client.turnSeat == leftSeat),
      rightSeat: SeatBadge(client: client, seat: rightSeat, isTurn: client.turnSeat == rightSeat),
      center: TrickCenter(
        turnText: client.isMyTurnToPlay ? 'Your turn' : "${client.nameOf(client.turnSeat!)}'s turn",
        leftCard: cardPlayedBy(leftSeat),
        myCard: cardPlayedBy(mySeat),
        rightCard: cardPlayedBy(rightSeat),
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
                  onTap: () => client.playCard(card),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
