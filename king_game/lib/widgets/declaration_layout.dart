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
          // Always exactly 10 cards pre-declare (never the 12-card
          // post-prikoup hand, which needs its own screen's scrolling
          // strip), so on any normal-width screen this centers the row
          // instead of leaving it stuck flush left with empty space on
          // the right. Still wrapped in a horizontal scroll view, with
          // ConstrainedBox(minWidth) forcing it to at least fill the
          // viewport — the only way to get "centered when it fits,
          // scrollable instead of overflowing when it doesn't" — since a
          // real narrow window (a phone in a cramped split-screen, for
          // instance) can end up too narrow for 10 cards side by side.
          SizedBox(
            height: 84,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < hand.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            PlayingCardWidget(key: ValueKey(hand[i]), card: hand[i], enabled: false),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
