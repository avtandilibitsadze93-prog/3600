import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            client.isMyTurnToPlay ? 'თქვენი ჯერია' : '${client.nameOf(client.turnSeat!)}-ს ჯერი',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('მაგიდაზე', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          SizedBox(
            height: 112,
            child: Center(
              child: client.trick.isEmpty
                  ? const Text('ჯერ არავის ჩამოუგდია', style: TextStyle(color: Colors.black38))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final play in client.trick)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                Text(
                                  client.nameOf(play.playerId),
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                                PlayingCardWidget(card: play.card, enabled: false),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const Divider(height: 32),
          const Text('თქვენი ხელი', style: TextStyle(color: Colors.black54)),
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
    );
  }
}
