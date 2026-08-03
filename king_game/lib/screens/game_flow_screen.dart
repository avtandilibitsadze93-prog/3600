import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/game_controller.dart';
import '../services/ad_service.dart';
import '../widgets/playing_card_widget.dart';
import 'declaration_screen.dart';
import 'prikoup_screen.dart';
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
        return Scaffold(
          appBar: AppBar(title: Text('რაუნდი ${controller.roundNumber} / 27')),
          body: SafeArea(child: _bodyFor(context, controller.phase)),
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

class _SeatingRevealView extends StatelessWidget {
  final GameController controller;
  const _SeatingRevealView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final names = controller.players.map((p) => p.name).toList();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ტუზის დარიგებით დადგინდა ადგილები', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            for (var i = 0; i < names.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${i + 1}. ${names[i]}', style: const TextStyle(fontSize: 18)),
              ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: controller.confirmSeating,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('თამაშის დაწყება'),
              ),
            ),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smartphone, size: 64, color: Colors.black38),
            const SizedBox(height: 16),
            Text(
              'გადააბრუნეთ ტელეფონი',
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
                child: Text('მზად ვარ'),
              ),
            ),
          ],
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
            Text('$winnerName-მ აიღო ხელი', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: controller.continueAfterTrick,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('გაგრძელება'),
              ),
            ),
          ],
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'კონტრაქტი: ${controller.lastRoundContract!.georgianName}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            const Text('ამ რაუნდის ქულები', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final p in controller.players)
              Text('${p.name}: ${_signed(delta[p.id] ?? 0)}'),
            const SizedBox(height: 24),
            const Text('ჯამური ქულები', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final entry in standings.entries) Text('${entry.key}: ${entry.value}'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: controller.continueAfterRoundSummary,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('შემდეგი რაუნდი'),
              ),
            ),
          ],
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
                child: Text('მთავარ გვერდზე დაბრუნება'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
