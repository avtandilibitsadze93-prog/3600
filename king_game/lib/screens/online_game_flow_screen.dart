import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
import '../theme/king_theme.dart';
import '../widgets/avatar_circle.dart';
import 'online_declaration_screen.dart';
import 'online_prikoup_screen.dart';
import 'online_trick_screen.dart';
import 'score_table_screen.dart';

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
              title: Text('Round ${client.roundNumber} / 27'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.grid_on),
                  tooltip: 'Score Table',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScoreTableScreen(
                        rows: [
                          for (final p in client.players)
                            ScoreRow(
                              name: p.name,
                              fixedResults: client.fixedContractResults[p.seat] ?? {},
                              plusResults: client.plusResults[p.seat] ?? [],
                              totalScore: client.standings[p.seat] ?? 0,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!client.isGameOver && !connectionIsDead)
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    tooltip: 'Leave Game',
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
        title: const Text('Leave the game?'),
        content: const Text(
          "If you leave before the game ends, you'll be blocked from starting a new game for 4 hours. "
          'The other 2 players will continue — a bot will take your seat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
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
          return const _WaitingView(message: 'Connection lost — trying to reconnect...');
        case ConnectionStatus.closed:
          return _DisconnectedView(message: "Connection lost and couldn't be restored.", client: client);
        case ConnectionStatus.error:
          return _DisconnectedView(
            message: client.errorMessage ?? 'Connection error',
            client: client,
          );
        case ConnectionStatus.connecting:
        case ConnectionStatus.queued:
          // No 'state' snapshot has been applied yet at this point — seat,
          // declarer, hand etc. are all still unset defaults, so the
          // phase switch below (which assumes real game data) must not
          // run until the first snapshot actually arrives.
          return const Center(child: CircularProgressIndicator());
        case ConnectionStatus.inGame:
          break;
      }
    }

    switch (client.phase) {
      case 'declaring':
        return client.isMyTurnToDeclare
            ? OnlineDeclarationScreen(client: client)
            : _WaitingView(
                message: '${client.nameOf(client.declarerSeat!)} is declaring a contract...',
                avatarId: client.avatarIdOf(client.declarerSeat!),
              );
      case 'prikoup':
        return client.isMyTurnToBury
            ? OnlinePrikoupScreen(client: client)
            : _WaitingView(
                message: '${client.nameOf(client.declarerSeat!)} is choosing the $prikoupName...',
                avatarId: client.avatarIdOf(client.declarerSeat!),
              );
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
  final String? avatarId;
  const _WaitingView({required this.message, this.avatarId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatarId != null) ...[
                AvatarCircle(avatarId: avatarId, radius: 28),
                const SizedBox(height: 12),
              ],
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: KingColors.onFeltFaint),
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
                  child: Text('Back to Home'),
                ),
              ),
            ],
          ),
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Game Over!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              for (var i = 0; i < standings.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarCircle(avatarId: client.avatarIdOf(standings[i].key), radius: i == 0 ? 18 : 14),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${i + 1}. ${client.nameOf(standings[i].key)} — ${standings[i].value}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: i == 0 ? 22 : 16,
                            fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
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
                  child: Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
