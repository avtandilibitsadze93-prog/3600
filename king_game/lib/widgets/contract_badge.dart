import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
import '../theme/king_theme.dart';

/// Top-right status: what's being declared/played right now — "Choose
/// a contract" or "X is declaring..." before one exists, then the
/// declared contract (and trump suit, or "No Trump") once it does.
/// Keeps that information in the same spot across every phase instead
/// of each screen inventing its own header text.
class ContractBadge extends StatelessWidget {
  final OnlineGameClient client;
  const ContractBadge({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final contract = client.contract;
    if (contract == null) {
      final text = client.isMyTurnToDeclare ? 'Choose a contract' : "${client.nameOf(client.declarerSeat!)} is declaring...";
      return Text(
        text,
        textAlign: TextAlign.right,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(fontSize: 12, color: KingColors.onFeltFaint),
      );
    }
    final suitLabel =
        contract == ContractType.trump ? (client.trumpSuit?.symbol ?? noTrumpName) : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: KingColors.goldLight, borderRadius: BorderRadius.circular(10)),
      child: Text(
        suitLabel != null ? '${contract.englishName} $suitLabel' : contract.englishName,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KingColors.inkNavy),
      ),
    );
  }
}
