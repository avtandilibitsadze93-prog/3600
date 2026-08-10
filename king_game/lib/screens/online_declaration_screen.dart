import 'package:flutter/material.dart';

import '../game/online_game_client.dart';
import '../widgets/card_sort.dart';
import '../widgets/contract_grid_picker.dart';
import '../widgets/playing_card_widget.dart';

class OnlineDeclarationScreen extends StatelessWidget {
  final OnlineGameClient client;
  const OnlineDeclarationScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final hand = sortedForDisplay(client.yourHand);

    // Landscape layout: hand on the left (its own scroll area, since a
    // short landscape screen doesn't have room to just grow downward),
    // contract choices on the right.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose a contract',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final card in hand) PlayingCardWidget(key: ValueKey(card), card: card),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: ContractGridPicker(
              legalTypes: client.legalDeclarations,
              onDeclare: client.declare,
            ),
          ),
        ],
      ),
    );
  }
}
