import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
import '../theme/king_theme.dart';
import '../widgets/card_sort.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/plus_chip.dart';

class OnlineDeclarationScreen extends StatefulWidget {
  final OnlineGameClient client;
  const OnlineDeclarationScreen({super.key, required this.client});

  @override
  State<OnlineDeclarationScreen> createState() => _OnlineDeclarationScreenState();
}

class _OnlineDeclarationScreenState extends State<OnlineDeclarationScreen> {
  Suit? _chosenTrumpSuit;
  bool _bezChosen = false;

  bool get _hasChosenPlus => _chosenTrumpSuit != null || _bezChosen;

  @override
  Widget build(BuildContext context) {
    final options = widget.client.legalDeclarations;
    final hand = sortedForDisplay(widget.client.yourHand);

    // Landscape layout: hand on the left (its own scroll area, since a
    // short landscape screen doesn't have room to just grow downward),
    // contract choices on the right.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose a contract',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final card in hand) PlayingCardWidget(key: ValueKey(card), card: card),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: ListView(
              children: [
                for (final type in options)
                  if (type != ContractType.trump)
                    Card(
                      child: ListTile(
                        title: Text(type.englishName),
                        onTap: () => widget.client.declare(type),
                      ),
                    ),
                if (options.contains(ContractType.trump))
                  Card(
                    color: KingColors.goldLight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '+',
                            style: TextStyle(fontWeight: FontWeight.bold, color: KingColors.inkNavy, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final suit in Suit.values)
                                PlusChip(
                                  label: suit.englishName,
                                  selected: _chosenTrumpSuit == suit && !_bezChosen,
                                  onSelected: () => setState(() {
                                    _chosenTrumpSuit = suit;
                                    _bezChosen = false;
                                  }),
                                ),
                              PlusChip(
                                label: noTrumpName,
                                selected: _bezChosen,
                                onSelected: () => setState(() {
                                  _bezChosen = true;
                                  _chosenTrumpSuit = null;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: KingColors.inkNavy,
                                foregroundColor: KingColors.cream,
                                disabledBackgroundColor: KingColors.inkNavy.withValues(alpha: 0.35),
                                disabledForegroundColor: KingColors.cream.withValues(alpha: 0.6),
                              ),
                              onPressed: !_hasChosenPlus
                                  ? null
                                  : () => widget.client.declare(
                                        ContractType.trump,
                                        trumpSuit: _bezChosen ? null : _chosenTrumpSuit,
                                      ),
                              child: const Text('Declare'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
