import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/game_controller.dart';
import '../widgets/playing_card_widget.dart';

/// The declarer sees their 10 cards plus the 2-card prikoup (12 total)
/// and picks exactly 2 to bury face-down. Cards forbidden by this round's
/// contract (per [GameController.isBurialForbidden]) are shown greyed out.
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
    final hand = widget.controller.prikoupPreviewHand;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            prikoupName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.controller.activePlayer.name}, აირჩიეთ 2 კარტი დასამარხად',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
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
                      enabled: !widget.controller.isBurialForbidden(card),
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
              onPressed: _selected.length == 2
                  ? () => widget.controller.buryAndStartTricks(_selected)
                  : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('დამარხვა და დაწყება'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
