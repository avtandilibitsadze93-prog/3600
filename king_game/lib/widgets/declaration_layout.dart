import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../theme/king_theme.dart';
import 'contract_grid_picker.dart';
import 'playing_card_widget.dart';

/// The declaring phase gets the grid as big as the screen allows —
/// unlike the trick/prikoup phases, nothing about the opponent seats
/// is actionable here (no turn indicator, no card to show), so this
/// skips GameTableShell's left/right seat columns entirely and gives
/// that space to the grid instead, with just a compact hand preview
/// strip along the bottom for reference.
class DeclarationLayout extends StatelessWidget {
  final List<ContractType> legalTypes;
  final void Function(ContractType type, {Suit? trumpSuit}) onDeclare;
  final List<PlayingCard> hand;

  const DeclarationLayout({
    super.key,
    required this.legalTypes,
    required this.onDeclare,
    required this.hand,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Top padding clears the standings-panel/contract-badge overlay
      // the parent screen floats over this (~76px tall) — see
      // GameTableShell. Trimmed tighter than GameTableShell's own
      // padding since this layout has no seat columns competing for
      // the same vertical space, so every pixel here goes straight to
      // making the grid bigger.
      padding: const EdgeInsets.fromLTRB(16, 84, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ContractGridPicker(legalTypes: legalTypes, onDeclare: onDeclare),
          ),
          const SizedBox(height: 6),
          const Text('Your hand', style: TextStyle(color: KingColors.onFeltSoft, fontSize: 12)),
          const SizedBox(height: 4),
          SizedBox(
            height: 84,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final card in hand)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PlayingCardWidget(key: ValueKey(card), card: card, enabled: false),
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
