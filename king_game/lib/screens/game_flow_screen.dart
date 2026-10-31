import 'dart:async';

import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/game_controller.dart';
import '../game/local_table_client.dart';
import '../services/ad_service.dart';
import '../theme/king_theme.dart';
import '../widgets/ace_draw_pile.dart';
import '../widgets/contract_badge.dart';
import '../widgets/game_table_shell.dart';
import '../widgets/mini_standings_panel.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/seat_badge.dart';
import 'declaration_screen.dart';
import 'prikoup_screen.dart';
import 'score_table_screen.dart';
import 'trick_screen.dart';

/// Hosts every phase of one game inside a single Scaffold, switching body
/// content off [GameController.phase]. Simple, low-stakes phases (seating
/// reveal, device handoff, a trick's result flash, round summary, game
/// over) are built inline here; the three phases with real player
/// interaction (declaring, prikoup, trick) delegate to their own screens.
class GameFlowScreen extends StatelessWidget {
  final GameController controller;

  const GameFlowScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        // No AppBar — the table fills the whole screen, with the same
        // standings-panel/contract-badge corner furniture as the online
        // table (see OnlineGameFlowScreen) so testing locally shows
        // exactly what a real online player would see.
        final showOverlay = controller.phase != GamePhase.playersSetup;
        final scoreRows = showOverlay
            ? [
                for (final p in controller.players)
                  ScoreRow(
                    name: p.name,
                    fixedResults: p.fixedContractResults,
                    plusResults: p.plusResults,
                    totalScore: p.totalScore,
                  ),
              ]
            : const <ScoreRow>[];
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                _bodyFor(context, controller.phase),
                // The declaring phase's own BigDeclarationGrid IS the
                // score sheet, shown big — this small corner copy would
                // just be a redundant, distracting second one, so it
                // steps aside for the duration.
                if (showOverlay && controller.phase != GamePhase.declaring)
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
                // Same reasoning as OnlineGameFlowScreen: a null contract
                // during seatingReveal means "no round exists yet", not
                // "declaring is in progress" — ContractBadge would
                // otherwise show a stale "X is declaring..." here.
                if (showOverlay && controller.phase != GamePhase.seatingReveal)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ContractBadge(client: LocalTableClient(controller)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bodyFor(BuildContext context, GamePhase phase) {
    switch (phase) {
      case GamePhase.playersSetup:
        return const SizedBox.shrink();
      case GamePhase.seatingReveal:
        return _SeatingRevealView(controller: controller);
      case GamePhase.deviceHandoff:
        return _DeviceHandoffView(controller: controller);
      case GamePhase.declaring:
        return DeclarationScreen(controller: controller);
      case GamePhase.prikoup:
        return PrikoupScreen(controller: controller);
      case GamePhase.trick:
        return TrickScreen(controller: controller);
      case GamePhase.trickResolved:
        return _TrickResolvedView(controller: controller);
      case GamePhase.roundSummary:
        return _RoundSummaryView(controller: controller);
      case GamePhase.gameOver:
        return _GameOverView(controller: controller);
    }
  }
}

/// Replays the "ვინ როგორ აიტუზოს" seating draw card by card, right in
/// the middle of the table, instead of jumping straight to the result —
/// whoever gets dealt the deciding Ace takes last; the player to their
/// left goes first. Laid out on the same [GameTableShell] every other
/// phase uses — [LocalTableClient.mySeat] already resolves to the first
/// declarer during this phase (see its doc comment), so "the bottom
/// seat" here is the same seat the device hands off to the moment
/// "Start Game" is pressed.
class _SeatingRevealView extends StatefulWidget {
  final GameController controller;
  const _SeatingRevealView({required this.controller});

  @override
  State<_SeatingRevealView> createState() => _SeatingRevealViewState();
}

class _SeatingRevealViewState extends State<_SeatingRevealView> {
  static const _cardInterval = Duration(milliseconds: 783);
  Timer? _timer;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    if (_shown >= widget.controller.aceDraw.revealed.length) return;
    _timer = Timer(_cardInterval, () {
      if (!mounted) return;
      setState(() => _shown++);
      _scheduleNext();
    });
  }

  void _revealAll() {
    _timer?.cancel();
    setState(() => _shown = widget.controller.aceDraw.revealed.length);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final client = LocalTableClient(controller);
    final aceDraw = controller.aceDraw;
    final done = _shown >= aceDraw.revealed.length;
    final mySeat = client.mySeat!;
    final rightSeat = (mySeat + 1) % 3;
    final leftSeat = (mySeat + 2) % 3;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: done ? null : _revealAll,
      child: GameTableShell(
        client: client,
        leftSeat: SeatBadge(client: client, seat: leftSeat),
        rightSeat: SeatBadge(client: client, seat: rightSeat),
        center: AceDrawPile(
          revealed: aceDraw.revealed.take(_shown).toList(),
          done: done,
          seating: aceDraw.seating,
          nameOf: client.nameOf,
        ),
        hand: done
            ? Center(
                child: FilledButton(
                  onPressed: controller.confirmSeating,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text('Start Game'),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _DeviceHandoffView extends StatelessWidget {
  final GameController controller;
  const _DeviceHandoffView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.smartphone, size: 64, color: KingColors.onFeltFaint),
              const SizedBox(height: 16),
              Text(
                'Pass the phone to',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                controller.activePlayer.name,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: controller.confirmHandoff,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Ready'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrickResolvedView extends StatelessWidget {
  final GameController controller;
  const _TrickResolvedView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final winnerName = controller.players[controller.lastTrickWinnerIndex!].name;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final c in controller.lastTrickCards) PlayingCardWidget(card: c, enabled: false),
                ],
              ),
              const SizedBox(height: 24),
              Text('$winnerName won the trick', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: controller.continueAfterTrick,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundSummaryView extends StatelessWidget {
  final GameController controller;
  const _RoundSummaryView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final delta = controller.lastRoundDelta;
    final standings = controller.standings;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contract: ${controller.lastRoundContract!.englishName}',
                style: const TextStyle(fontSize: 16, color: KingColors.onFeltSoft),
              ),
              const SizedBox(height: 16),
              const Text("This round's points", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final p in controller.players)
                Text('${p.name}: ${_signed(delta[p.id] ?? 0)}'),
              const SizedBox(height: 24),
              const Text('Total scores', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final entry in standings.entries) Text('${entry.key}: ${entry.value}'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: controller.continueAfterRoundSummary,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Next Round'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _signed(int n) => n > 0 ? '+$n' : '$n';
}

class _GameOverView extends StatefulWidget {
  final GameController controller;
  const _GameOverView({required this.controller});

  @override
  State<_GameOverView> createState() => _GameOverViewState();
}

class _GameOverViewState extends State<_GameOverView> {
  @override
  void initState() {
    super.initState();
    AdService.instance.showInterstitialIfReady();
  }

  @override
  Widget build(BuildContext context) {
    final standings = widget.controller.standings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
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
                  child: Text(
                    '${i + 1}. ${standings[i].key} — ${standings[i].value}',
                    style: TextStyle(
                      fontSize: i == 0 ? 22 : 16,
                      fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
