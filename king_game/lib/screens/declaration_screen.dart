import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../models/score_row.dart';
import '../widgets/card_sort.dart';
import '../widgets/declaration_layout.dart';

/// Built off the exact same [DeclarationLayout]/[BigDeclarationGrid]
/// widgets as [OnlineDeclarationScreen] so testing locally shows the
/// same big-grid declaration screen a real online player would see.
class DeclarationScreen extends StatelessWidget {
  final GameController controller;
  const DeclarationScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // controller.players is in seating-POSITION order, unlike the
    // stable Player.id — activePlayerIndex is the position index that
    // matches this list, same construction GameFlowScreen uses for the
    // tap-to-expand ScoreTableScreen.
    final rows = [
      for (final p in controller.players)
        ScoreRow(
          name: p.name,
          fixedResults: p.fixedContractResults,
          plusResults: p.plusResults,
          totalScore: p.totalScore,
        ),
    ];
    return DeclarationLayout(
      legalTypes: controller.legalDeclarations,
      onDeclare: controller.declare,
      hand: sortedForDisplay(controller.activePlayer.hand),
      rows: rows,
      myRowIndex: controller.activePlayerIndex,
    );
  }
}
