import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../widgets/card_sort.dart';
import '../widgets/contract_grid_picker.dart';
import '../widgets/playing_card_widget.dart';

class DeclarationScreen extends StatelessWidget {
  final GameController controller;
  const DeclarationScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final declarerName = controller.activePlayer.name;
    final hand = sortedForDisplay(controller.activePlayer.hand);

    // Landscape layout: hand on the left (its own scroll area, since a
    // short landscape screen doesn't have room to just grow downward),
    // the contract grid on the right. Extra top clearance keeps the
    // grid's top-right cell from sitting under the score-table corner
    // icon GameFlowScreen floats over this screen.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$declarerName, choose a contract',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              legalTypes: controller.legalDeclarations,
              onDeclare: controller.declare,
            ),
          ),
        ],
      ),
    );
  }
}
