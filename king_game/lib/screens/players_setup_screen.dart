import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import 'game_flow_screen.dart';

class PlayersSetupScreen extends StatefulWidget {
  const PlayersSetupScreen({super.key});

  @override
  State<PlayersSetupScreen> createState() => _PlayersSetupScreenState();
}

class _PlayersSetupScreenState extends State<PlayersSetupScreen> {
  final _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _start() {
    final names = [
      for (var i = 0; i < 3; i++)
        _controllers[i].text.trim().isEmpty
            ? 'Player ${i + 1}'
            : _controllers[i].text.trim(),
    ];
    final controller = GameController()..setupPlayers(names);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameFlowScreen(controller: controller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Players')),
      // The whole form scrolls as one piece (rather than pinning the
      // button below a separately-scrolling field list) so that on a
      // short landscape screen with the keyboard up, the field being
      // typed into can always scroll into view above the keyboard
      // instead of being squeezed into an invisible sliver.
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter 3 player names — the phone will be passed around in turn.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                for (var i = 0; i < 3; i++) ...[
                  TextField(
                    controller: _controllers[i],
                    decoration: InputDecoration(
                      labelText: 'Player ${i + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _start,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Start'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
