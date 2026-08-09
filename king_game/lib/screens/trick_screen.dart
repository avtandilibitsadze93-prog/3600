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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '${controller.activePlayer.name}-ს ჯერი',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('მაგიდაზე', style: TextStyle(color: KingColors.onFeltSoft)),
          const SizedBox(height: 8),
          SizedBox(
            height: 112,
            child: Center(
              child: trick.plays.isEmpty
                  ? const Text('ჯერ არავის ჩამოუგდია', style: TextStyle(color: KingColors.onFeltFaint))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final play in trick.plays)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                Text(
                                  controller.players.firstWhere((p) => p.id == play.playerId).name,
                                  style: const TextStyle(fontSize: 11, color: KingColors.onFeltSoft),
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
          const Text('თქვენი ხელი', style: TextStyle(color: KingColors.onFeltSoft)),
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
    );
  }
}
