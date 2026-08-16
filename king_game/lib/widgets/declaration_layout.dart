import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../models/score_row.dart';
import '../theme/king_theme.dart';
import 'big_declaration_grid.dart';
import 'playing_card_widget.dart';

/// The declaring phase gets the score sheet itself as big as the screen
/// allows, doubling as the contract picker — unlike the trick/prikoup
/// phases, nothing about the opponent seats is actionable here (no turn
/// indicator, no card to show), so this skips GameTableShell's
/// left/right seat columns entirely and gives that space to the grid
/// instead, with just a compact hand preview strip along the bottom for
/// reference. [MiniStandingsPanel] hides itself during this phase (see
/// the game-flow screens) so only [ContractBadge] floats on top here —
/// much shorter than the standings panel it usually shares the corner
/// with, so this needs far less top padding than GameTableShell's.
class DeclarationLayout extends StatelessWidget {
  final List<ContractType> legalTypes;
  final void Function(ContractType type, {Suit? trumpSuit}) onDeclare;
  final List<PlayingCard> hand;
  final List<ScoreRow> rows;
  final int myRowIndex;

  const DeclarationLayout({
    super.key,
    required this.legalTypes,
    required this.onDeclare,
    required this.hand,
    required this.rows,
    required this.myRowIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: BigDeclarationGrid(
              rows: rows,
              myRowIndex: myRowIndex,
              legalTypes: legalTypes,
              onDeclare: onDeclare,
            ),
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
