import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
import '../theme/king_theme.dart';
import '../widgets/card_sort.dart';
import '../widgets/game_table_shell.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/seat_badge.dart';

/// The declarer's 12-card preview (server already folds the 2-card
/// prikoup into 'yourHand' for them during this phase) with 2 to bury.
/// Legality is computed locally via the shared engine's pure
/// [isBurialForbidden] — the same rule the server re-validates, so this
/// is purely an instant-feedback UX layer, never the final word.
class OnlinePrikoupScreen extends StatefulWidget {
  final OnlineGameClient client;
  const OnlinePrikoupScreen({super.key, required this.client});

  @override
  State<OnlinePrikoupScreen> createState() => _OnlinePrikoupScreenState();
}

class _OnlinePrikoupScreenState extends State<OnlinePrikoupScreen> {
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
    final hand = sortedForDisplay(widget.client.yourHand);
    final contract = widget.client.contract!;
    final mySeat = widget.client.mySeat!;
    final rightSeat = (mySeat + 1) % 3;
    final leftSeat = (mySeat + 2) % 3;

    return GameTableShell(
      client: widget.client,
      leftSeat: SeatBadge(client: widget.client, seat: leftSeat),
      rightSeat: SeatBadge(client: widget.client, seat: rightSeat),
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
                width: 140,
                child: FilledButton(
                  onPressed: _selected.length == 2 ? () => widget.client.bury(_selected) : null,
                  child: const Text('Bury'),
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
                  enabled: !isBurialForbidden(contract, card),
                  dimmed: isBurialForbidden(contract, card),
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
