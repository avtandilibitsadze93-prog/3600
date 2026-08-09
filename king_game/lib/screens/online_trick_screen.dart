import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
import '../theme/king_theme.dart';
import '../widgets/card_sort.dart';
import '../widgets/playing_card_widget.dart';

/// Always shows the table and your own hand — there's no device handoff
/// online, your own screen just waits (cards greyed out) when it's not
/// your turn. Legal cards are computed locally via the shared engine's
/// pure [legalMoves], re-validated authoritatively by the server.
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

    // Landscape layout: what's on the table on the left (its own compact,
    // naturally-sized area — a short landscape screen has no room to
    // spare for a tall fixed-height table strip), your hand on the right.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    client.isMyTurnToPlay ? 'Your turn' : "${client.nameOf(client.turnSeat!)}'s turn",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text('On the table', style: TextStyle(color: KingColors.onFeltSoft)),
                  const SizedBox(height: 8),
                  client.trick.isEmpty
                      ? const Text('No one has played yet', style: TextStyle(color: KingColors.onFeltFaint))
                      : Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final play in client.trick)
                              Column(
                                children: [
                                  Text(
                                    client.nameOf(play.playerId),
                                    style: const TextStyle(fontSize: 11, color: KingColors.onFeltSoft),
                                  ),
                                  PlayingCardWidget(card: play.card, enabled: false),
                                ],
                              ),
                          ],
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Your hand', style: TextStyle(color: KingColors.onFeltSoft)),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final card in hand)
                          PlayingCardWidget(
                            key: ValueKey(card),
                            card: card,
                            enabled: legal.contains(card),
                            onTap: () => client.playCard(card),
                          ),
                      ],
                    ),
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
