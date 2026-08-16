import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/local_table_client.dart';
import '../widgets/card_sort.dart';
import '../widgets/contract_grid_picker.dart';
import '../widgets/game_table_shell.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/seat_badge.dart';

/// Built off the exact same [GameTableShell]/[SeatBadge]/
/// [ContractGridPicker] widgets as [OnlineDeclarationScreen] — via
/// [LocalTableClient] — so testing locally shows the same table a real
/// online player would see, just with "my seat" following whichever
/// player is currently holding the phone.
class DeclarationScreen extends StatelessWidget {
  final GameController controller;
  const DeclarationScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final client = LocalTableClient(controller);
    final hand = sortedForDisplay(controller.activePlayer.hand);
    final mySeat = client.mySeat!;
    final rightSeat = (mySeat + 1) % 3;
    final leftSeat = (mySeat + 2) % 3;

    return GameTableShell(
      client: client,
      leftSeat: SeatBadge(client: client, seat: leftSeat),
      rightSeat: SeatBadge(client: client, seat: rightSeat),
      center: ContractGridPicker(
        legalTypes: controller.legalDeclarations,
        onDeclare: controller.declare,
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
