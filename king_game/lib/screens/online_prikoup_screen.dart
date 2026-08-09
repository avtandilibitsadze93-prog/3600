import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
import '../theme/king_theme.dart';
import '../widgets/card_sort.dart';
import '../widgets/playing_card_widget.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            prikoupName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'აირჩიეთ 2 კარტი დასამარხად',
            style: TextStyle(fontSize: 16, color: KingColors.onFeltSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final card in hand)
                    PlayingCardWidget(
                      key: ValueKey(card),
                      card: card,
                      enabled: !isBurialForbidden(contract, card),
                      selected: _selected.contains(card),
                      onTap: () => _toggle(card),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selected.length == 2 ? () => widget.client.bury(_selected) : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('დამარხვა'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
