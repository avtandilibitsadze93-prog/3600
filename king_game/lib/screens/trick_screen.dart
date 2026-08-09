import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../theme/king_theme.dart';
import '../widgets/card_sort.dart';
import '../widgets/playing_card_widget.dart';

/// The active player's turn within a trick: shows what's already been
/// played to the table this trick (public — every player at a real table
/// would already have seen it) and the active player's own hand, with
/// illegal cards (per [GameController.legalMovesForActivePlayer]) greyed
/// out so a wrong tap is never even possible.
class TrickScreen extends StatelessWidget {
  final GameController controller;
  const TrickScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final trick = controller.currentTrick!;
    final legal = controller.legalMovesForActivePlayer;
    final hand = sortedForDisplay(controller.activePlayer.hand);

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
                    "${controller.activePlayer.name}'s turn",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text('On the table', style: TextStyle(color: KingColors.onFeltSoft)),
                  const SizedBox(height: 8),
                  trick.plays.isEmpty
                      ? const Text('No one has played yet', style: TextStyle(color: KingColors.onFeltFaint))
                      : Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final play in trick.plays)
                              Column(
                                children: [
                                  Text(
                                    controller.players.firstWhere((p) => p.id == play.playerId).name,
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
                            onTap: () => controller.playCard(card),
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
