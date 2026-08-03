import 'package:flutter/material.dart';

import '../game/online_game_client.dart';
import 'online_game_flow_screen.dart';

/// Connects to the online server and waits for 2 opponents. Once matched,
/// replaces itself with [OnlineGameFlowScreen] — there's no local setup
/// step here (unlike the pass-and-play mode's PlayersSetupScreen), since
/// matchmaking picks your opponents for you.
class OnlineConnectScreen extends StatefulWidget {
  final String username;
  final String serverUrl;

  /// If set, this is a private table (a password shared with friends) —
  /// the game only starts once 3 people connect with this same code,
  /// instead of joining public matchmaking.
  final String? tableCode;

  const OnlineConnectScreen({
    super.key,
    required this.username,
    required this.serverUrl,
    this.tableCode,
  });

  @override
  State<OnlineConnectScreen> createState() => _OnlineConnectScreenState();
}

class _OnlineConnectScreenState extends State<OnlineConnectScreen> {
  late final OnlineGameClient _client;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _client = OnlineGameClient()..connect(widget.serverUrl, widget.username, tableCode: widget.tableCode);
    _client.addListener(_onClientChanged);
  }

  void _onClientChanged() {
    if (_navigated) return;
    if (_client.status == ConnectionStatus.inGame) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnlineGameFlowScreen(client: _client)),
      );
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _client.removeListener(_onClientChanged);
    if (!_navigated) _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPrivate = widget.tableCode != null && widget.tableCode!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(isPrivate ? 'მაგიდა მეგობრებთან' : 'ონლაინ თამაში')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_client.status == ConnectionStatus.error) ...[
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(_client.errorMessage ?? 'შეცდომა', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('უკან დაბრუნება'),
                ),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  _client.status == ConnectionStatus.queued
                      ? (isPrivate
                          ? 'ველოდებით დანარჩენ მეგობრებს იგივე პაროლით...'
                          : 'ველოდებით 2 მოწინააღმდეგეს...')
                      : 'დაკავშირება სერვერთან...',
                ),
                if (isPrivate && _client.status == ConnectionStatus.queued) ...[
                  const SizedBox(height: 8),
                  Text(
                    'პაროლი: ${widget.tableCode}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
