import 'package:flutter/material.dart';

import '../game/online_game_client.dart';
import '../models/score_row.dart';
import '../widgets/card_sort.dart';
import '../widgets/declaration_layout.dart';

class OnlineDeclarationScreen extends StatelessWidget {
  final OnlineGameClient client;
  const OnlineDeclarationScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    // Online players list is always in seat order (seat == index), so
    // mySeat doubles as the row index — same construction the parent
    // OnlineGameFlowScreen uses for the tap-to-expand ScoreTableScreen.
    final rows = [
      for (final p in client.players)
        ScoreRow(
          name: p.name,
          fixedResults: client.fixedContractResults[p.seat] ?? {},
          plusResults: client.plusResults[p.seat] ?? [],
          totalScore: client.standings[p.seat] ?? 0,
        ),
    ];
    return DeclarationLayout(
      legalTypes: client.legalDeclarations,
      onDeclare: client.declare,
      hand: sortedForDisplay(client.yourHand),
      rows: rows,
      myRowIndex: client.mySeat!,
    );
  }
}
