import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
import 'online_declaration_screen.dart';
import 'online_prikoup_screen.dart';
import 'online_trick_screen.dart';

/// Hosts every phase of one online match, reading purely off
/// [OnlineGameClient]'s last server broadcast. Unlike the local
/// pass-and-play [GameFlowScreen], there's no device-handoff phase —
/// your own screen simply waits (showing what's public) whenever it's
/// not your turn, since every player has their own device now.
class OnlineGameFlowScreen extends StatelessWidget {
  final OnlineGameClient client;
  const OnlineGameFlowScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: client,
      builder: (context, _) {
        if (client.lastActionError != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(client.lastActionError!)),
            );
            client.clearActionError();
          });
        }
        final connectionIsDead = client.status == ConnectionStatus.closed ||
            client.status == ConnectionStatus.error;
        return PopScope(
          canPop: client.isGameOver || connectionIsDead,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmAndLeave(context);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('რაუნდი ${client.roundNumber} / 27'),
              actions: [
                if (!client.isGameOver && !connectionIsDead)
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    tooltip: 'თამაშის დატოვება',
                    onPressed: () => _confirmAndLeave(context),
                  ),
              ],
            ),
            body: SafeArea(child: _body(context)),
          ),
        );
      },
    );
  }

  Future<void> _confirmAndLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('თამაშის დატოვება?'),
        content: const Text(
          'თუ თამაშს ვადაზე ადრე დატოვებთ, 4 საათით დაიბლოკებით ახალი თამაშის დაწყებაზე. '
          'დანარჩენი 2 მოთამაშე გააგრძელებს — თქვენს ადგილს ბოტი ჩაანაცვლებს.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('გაუქმება'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('დატოვება'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    client.leave();
    client.dispose();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _body(BuildContext context) {
    // A finished game is final regardless of what the socket does next —
    // only apply connection-status views while a match is still active.
    if (client.phase != 'gameOver') {
      switch (client.status) {
        case ConnectionStatus.reconnecting:
          return const _WaitingView(message: 'კავშირი გაწყდა — ვცდილობთ თავიდან დაკავშირებას...');
        case ConnectionStatus.closed:
          return _DisconnectedView(message: 'კავშირი დაიკარგა და ვეღარ აღვადგინეთ.', client: client);
        case ConnectionStatus.error:
          return _DisconnectedView(
            message: client.errorMessage ?? 'დაკავშირების შეცდომა',
            client: client,
          );
        case ConnectionStatus.connecting:
        case ConnectionStatus.queued:
        case ConnectionStatus.inGame:
          break;
      }
    }

    switch (client.phase) {
      case 'declaring':
        return client.isMyTurnToDeclare
            ? OnlineDeclarationScreen(client: client)
            : _WaitingView(message: '${client.nameOf(client.declarerSeat!)} აცხადებს კონტრაქტს...');
      case 'prikoup':
        return client.isMyTurnToBury
            ? OnlinePrikoupScreen(client: client)
            : _WaitingView(message: '${client.nameOf(client.declarerSeat!)} ირჩევს $prikoupName-ს...');
      case 'trick':
        return OnlineTrickScreen(client: client);
      case 'gameOver':
        return _GameOverView(client: client);
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

class _WaitingView extends StatelessWidget {
  final String message;
  const _WaitingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DisconnectedView extends StatelessWidget {
  final String message;
  final OnlineGameClient client;
  const _DisconnectedView({required this.message, required this.client});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.black38),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                client.dispose();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('მთავარ გვერდზე დაბრუნება'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverView extends StatelessWidget {
  final OnlineGameClient client;
  const _GameOverView({required this.client});

  @override
  Widget build(BuildContext context) {
    final standings = client.standings.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('თამაში დასრულდა!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            for (var i = 0; i < standings.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${i + 1}. ${client.nameOf(standings[i].key)} — ${standings[i].value}',
                  style: TextStyle(
                    fontSize: i == 0 ? 22 : 16,
                    fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                client.dispose();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('მთავარ გვერდზე დაბრუნება'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
