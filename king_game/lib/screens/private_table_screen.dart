import 'package:flutter/material.dart';

import '../config.dart';
import 'online_connect_screen.dart';

/// Lets a group of friends land in the same private match instead of
/// public matchmaking: everyone types the same simple password here, and
/// the server (see MatchmakingQueue's private-table grouping) only starts
/// the game once exactly 3 people have connected with that same code.
class PrivateTableScreen extends StatefulWidget {
  final String username;
  final String avatarId;

  const PrivateTableScreen({super.key, required this.username, required this.avatarId});

  @override
  State<PrivateTableScreen> createState() => _PrivateTableScreenState();
}

class _PrivateTableScreenState extends State<PrivateTableScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _join() {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnlineConnectScreen(
          username: widget.username,
          avatarId: widget.avatarId,
          serverUrl: defaultServerUrl,
          tableCode: code,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Play with Friends')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pick a simple password and share it with your friends. '
              'Once all 3 of you enter the same password, '
              "you'll automatically land at the same table.",
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _join,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Join Table', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
