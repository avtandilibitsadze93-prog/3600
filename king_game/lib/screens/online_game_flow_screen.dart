import 'dart:async';

import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
import '../theme/king_theme.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/card_sort.dart';
import '../widgets/contract_badge.dart';
import '../widgets/corner_icon_button.dart';
import '../widgets/game_table_shell.dart';
import '../widgets/mini_standings_panel.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/seat_badge.dart';
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
        // The standings panel and contract badge need a real server
        // snapshot to read from (seat, players, declarer...) — same
        // guard as _body()'s phase switch, so they never render before
        // the first 'state' message arrives.
        final hasGameData = client.status == ConnectionStatus.inGame && !client.isGameOver;
        final scoreRows = hasGameData
            ? [
                for (final p in client.players)
                  ScoreRow(
                    name: p.name,
                    fixedResults: client.fixedContractResults[p.seat] ?? {},
                    plusResults: client.plusResults[p.seat] ?? [],
                    totalScore: client.standings[p.seat] ?? 0,
                  ),
              ]
            : const <ScoreRow>[];
        return PopScope(
          canPop: client.isGameOver || connectionIsDead,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmAndLeave(context);
          },
          child: Scaffold(
            // No AppBar — the table fills the whole screen, with just a
            // small standings panel and contract/leave cluster floating
            // in the corners, the way Joker's table screen does.
            body: SafeArea(
              child: Stack(
                children: [
                  _body(context),
                  // The declaring phase's own BigDeclarationGrid IS the
                  // score sheet, shown big — this small corner copy would
                  // just be a redundant, distracting second one, so it
                  // steps aside for the duration.
                  if (hasGameData && client.phase != 'declaring')
                    Positioned(
                      top: 0,
                      left: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ScoreTableScreen(rows: scoreRows)),
                        ),
                        child: MiniStandingsPanel(rows: scoreRows),
                      ),
                    ),
                  if (hasGameData)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ContractBadge(client: client),
                          if (!connectionIsDead) ...[
                            const SizedBox(width: 6),
                            CornerIconButton(
                              icon: Icons.exit_to_app,
                              tooltip: 'Leave Game',
                              onTap: () => _confirmAndLeave(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
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
      case 'aceDraw':
        return _AceDrawView(client: client);
      case 'declaring':
        return client.isMyTurnToDeclare
            ? OnlineDeclarationScreen(client: client)
            : _TableWaitingView(
                client: client,
                message: '${client.nameOf(client.declarerSeat!)} is declaring a contract...',
                avatarId: client.avatarIdOf(client.declarerSeat!),
              );
      case 'prikoup':
        return client.isMyTurnToBury
            ? OnlinePrikoupScreen(client: client)
            : _TableWaitingView(
                client: client,
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

/// Replays the "ვინ როგორ აიტუზოს" seating draw card by card in the
/// middle of the table, on all 3 phones at once — the server already
/// decided the real result (and holds this phase open just long enough
/// for the animation below to finish before moving on), this is purely
/// each device showing the same already-known sequence locally. Whoever
/// is dealt the deciding Ace takes last; the player to their left goes
/// first.
class _AceDrawView extends StatefulWidget {
  final OnlineGameClient client;
  const _AceDrawView({required this.client});

  @override
  State<_AceDrawView> createState() => _AceDrawViewState();
}

class _AceDrawViewState extends State<_AceDrawView> {
  Timer? _timer;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    if (_shown >= widget.client.aceDrawCards.length) return;
    _timer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _shown++);
      _scheduleNext();
    });
  }

  void _revealAll() {
    _timer?.cancel();
    setState(() => _shown = widget.client.aceDrawCards.length);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final done = _shown >= client.aceDrawCards.length;
    final lastCardOf = <int, PlayingCard>{};
    for (final c in client.aceDrawCards.take(_shown)) {
      lastCardOf[c.playerIndex] = c.card;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: done ? null : _revealAll,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Drawing aces for seats...', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var seat = 0; seat < 3; seat++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              Text(client.nameOf(seat), style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 56,
                                height: 80,
                                child: lastCardOf.containsKey(seat)
                                    ? PlayingCardWidget(card: lastCardOf[seat]!, enabled: false)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!done)
                  const Text('(tap to skip)', style: TextStyle(fontSize: 12, color: KingColors.onFeltFaint))
                else
                  for (var i = 0; i < client.aceDrawSeating.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${i + 1}. ${client.nameOf(client.aceDrawSeating[i])}',
                          style: const TextStyle(fontSize: 18)),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Someone else is declaring or choosing the widow — nothing for you to
/// do yet, but your own hand is exactly as real as when it's your turn,
/// so it stays on screen at the table (same GameTableShell every other
/// phase uses) instead of a blank loading screen replacing it. Only for
/// mid-match waits with a live snapshot already applied — a genuine
/// connection drop (see [_WaitingView]) has no table worth trusting.
class _TableWaitingView extends StatelessWidget {
  final OnlineGameClient client;
  final String message;
  final String? avatarId;
  const _TableWaitingView({required this.client, required this.message, this.avatarId});

  @override
  Widget build(BuildContext context) {
    final hand = sortedForDisplay(client.yourHand);
    final mySeat = client.mySeat!;
    final rightSeat = (mySeat + 1) % 3;
    final leftSeat = (mySeat + 2) % 3;

    return GameTableShell(
      client: client,
      leftSeat: SeatBadge(client: client, seat: leftSeat),
      rightSeat: SeatBadge(client: client, seat: rightSeat),
      center: Center(
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
      ),
      hand: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            for (final card in hand)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PlayingCardWidget(key: ValueKey(card), card: card, enabled: false),
              ),
          ],
        ),
      ),
    );
  }
}

/// A genuine connection drop (or the initial connect, before any
/// snapshot has ever arrived) — unlike [_TableWaitingView], there's no
/// trustworthy hand/table to show here.
class _WaitingView extends StatelessWidget {
  final String message;
  const _WaitingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
