import 'package:flutter/material.dart';

import '../game/online_game_client.dart';
import '../widgets/card_sort.dart';
import '../widgets/contract_grid_picker.dart';
import '../widgets/game_table_shell.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/seat_badge.dart';

class OnlineDeclarationScreen extends StatelessWidget {
  final OnlineGameClient client;
  const OnlineDeclarationScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final hand = sortedForDisplay(client.yourHand);
    final mySeat = client.mySeat!;
    final rightSeat = (mySeat + 1) % 3;
    final leftSeat = (mySeat + 2) % 3;

    return GameTableShell(
      client: client,
      leftSeat: SeatBadge(client: client, seat: leftSeat),
      rightSeat: SeatBadge(client: client, seat: rightSeat),
      center: ContractGridPicker(
        legalTypes: client.legalDeclarations,
        onDeclare: client.declare,
      ),
      hand: SingleChildScrollView(
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
    );
  }
}
