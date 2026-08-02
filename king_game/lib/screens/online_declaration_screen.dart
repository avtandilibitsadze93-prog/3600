import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';

class OnlineDeclarationScreen extends StatefulWidget {
  final OnlineGameClient client;
  const OnlineDeclarationScreen({super.key, required this.client});

  @override
  State<OnlineDeclarationScreen> createState() => _OnlineDeclarationScreenState();
}

class _OnlineDeclarationScreenState extends State<OnlineDeclarationScreen> {
  Suit? _chosenTrumpSuit;

  @override
  Widget build(BuildContext context) {
    final options = widget.client.legalDeclarations;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'აირჩიეთ კონტრაქტი',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                for (final type in options)
                  if (type != ContractType.trump)
                    Card(
                      child: ListTile(
                        title: Text(type.georgianName),
                        onTap: () => widget.client.declare(type),
                      ),
                    ),
                if (options.contains(ContractType.trump))
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('კოზირი', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final suit in Suit.values)
                                ChoiceChip(
                                  label: Text(suit.georgianName),
                                  selected: _chosenTrumpSuit == suit,
                                  onSelected: (_) => setState(() => _chosenTrumpSuit = suit),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _chosenTrumpSuit == null
                                  ? null
                                  : () => widget.client
                                      .declare(ContractType.trump, trumpSuit: _chosenTrumpSuit),
                              child: const Text('კოზირის გამოცხადება'),
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
