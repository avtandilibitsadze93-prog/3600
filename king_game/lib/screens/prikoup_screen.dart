import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/game_controller.dart';
import '../game/local_table_client.dart';
import '../theme/king_theme.dart';
import '../widgets/card_sort.dart';
import '../widgets/game_table_shell.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/seat_badge.dart';

/// The declarer sees their 10 cards plus the 2-card prikoup (12 total)
/// and picks exactly 2 to bury face-down. Cards forbidden by this round's
/// contract (per [GameController.isBurialForbidden]) are shown greyed out.
/// Built off the same [GameTableShell] as the online prikoup screen —
/// see [DeclarationScreen] for why.
class PrikoupScreen extends StatefulWidget {
  final GameController controller;
  const PrikoupScreen({super.key, required this.controller});

  @override
  State<PrikoupScreen> createState() => _PrikoupScreenState();
}

class _PrikoupScreenState extends State<PrikoupScreen> {
  final List<PlayingCard> _selected = [];

  void _toggle(PlayingCard card) {
    setState(() {
      if (_selected.contains(card)) {
        _selected.remove(card);
      } else if (_selected.length < 2) {
        _selected.add(card);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = LocalTableClient(widget.controller);
    final hand = sortedForDisplay(widget.controller.prikoupPreviewHand);
    final mySeat = client.mySeat!;
    final rightSeat = (mySeat + 1) % 3;
    final leftSeat = (mySeat + 2) % 3;

    return GameTableShell(
      client: client,
      leftSeat: SeatBadge(client: client, seat: leftSeat),
      rightSeat: SeatBadge(client: client, seat: rightSeat),
      center: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(prikoupName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Choose 2 cards to bury',
                style: TextStyle(fontSize: 14, color: KingColors.onFeltSoft),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                child: FilledButton(
                  onPressed: _selected.length == 2
                      ? () => widget.controller.buryAndStartTricks(_selected)
                      : null,
                  child: const Text('Bury & Start'),
                ),
              ),
            ],
          ),
        ),
      ),
      // 12 cards (the usual 10-card hand plus the 2-card widow) don't
      // reliably fit at full size — scale the whole row down together
      // rather than making it scrollable, so all 12 are visible at once.
      hand: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            for (final card in hand)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PlayingCardWidget(
                  key: ValueKey(card),
                  card: card,
                  enabled: !widget.controller.isBurialForbidden(card),
                  dimmed: widget.controller.isBurialForbidden(card),
                  selected: _selected.contains(card),
                  onTap: () => _toggle(card),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
