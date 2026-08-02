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
            ? 'მოთამაშე ${i + 1}'
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
      appBar: AppBar(title: const Text('მოთამაშეები')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'შეიყვანეთ 3 მოთამაშის სახელი — ტელეფონი მორიგეობით გადაეცემა.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < 3; i++) ...[
                TextField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    labelText: 'მოთამაშე ${i + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _start,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('დაწყება'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
