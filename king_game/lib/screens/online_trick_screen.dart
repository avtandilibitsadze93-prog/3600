import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
import '../theme/king_theme.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/card_sort.dart';
import '../widgets/playing_card_widget.dart';

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

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: _SeatBadge(client: client, seat: leftSeat),
                ),
                Expanded(
                  flex: 3,
                  child: _TableCenter(client: client),
                ),
                Expanded(
                  flex: 2,
                  child: _SeatBadge(client: client, seat: rightSeat),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Your hand', style: TextStyle(color: KingColors.onFeltSoft)),
          const SizedBox(height: 6),
          SingleChildScrollView(
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
        ],
      ),
    );
  }
}

/// One opponent's seat: avatar (gold-ringed brighter when it's their
/// turn, dimmed if they've disconnected and a bot has taken over), name,
/// and their card for the current trick if they've already played it.
class _SeatBadge extends StatelessWidget {
  final OnlineGameClient client;
  final int seat;
  const _SeatBadge({required this.client, required this.seat});

  @override
  Widget build(BuildContext context) {
    final isTurn = client.turnSeat == seat;
    final connected = client.players.firstWhere((p) => p.seat == seat).connected;
    PlayingCard? playedCard;
    for (final play in client.trick) {
      if (play.playerId == seat) playedCard = play.card;
    }
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isTurn ? Border.all(color: KingColors.goldLight, width: 2) : null,
              ),
              child: AvatarCircle(avatarId: client.avatarIdOf(seat), radius: 22, dimmed: !connected),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 84,
              child: Text(
                client.nameOf(seat),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isTurn ? KingColors.gold : KingColors.onFeltSoft,
                  fontWeight: isTurn ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (playedCard != null) ...[
              const SizedBox(height: 6),
              PlayingCardWidget(card: playedCard, enabled: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// The middle of the table: whose turn it is, and — once you've played —
/// your own card for this trick (the two opponents' cards show next to
/// their own seats instead).
class _TableCenter extends StatelessWidget {
  final OnlineGameClient client;
  const _TableCenter({required this.client});

  @override
  Widget build(BuildContext context) {
    PlayingCard? myCard;
    for (final play in client.trick) {
      if (play.playerId == client.mySeat) myCard = play.card;
    }
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              client.isMyTurnToPlay ? 'Your turn' : "${client.nameOf(client.turnSeat!)}'s turn",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (myCard != null)
              PlayingCardWidget(card: myCard, enabled: false)
            else if (client.trick.isEmpty)
              const Text('No one has played yet', style: TextStyle(color: KingColors.onFeltFaint), textAlign: TextAlign.center)
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
