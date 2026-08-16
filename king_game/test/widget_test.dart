// Drives a full 27-round game through the real UI (GameFlowScreen), tapping
// exactly the widgets a player would: contract choice, prikoup burial,
// device handoff, and every single card play. This is the widget-level
// equivalent of bin/simulate.dart — it proves the screens are wired
// correctly to GameController/GameEngine/RoundEngine, not just that the
// rules engine works in isolation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:king_game_engine/king_game_engine.dart';

import 'package:king_game/game/game_controller.dart';
import 'package:king_game/screens/game_flow_screen.dart';
import 'package:king_game/screens/players_setup_screen.dart';

void main() {
  testWidgets('players setup screen navigates into a game', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PlayersSetupScreen()));
    await tester.enterText(find.byType(TextField).at(0), 'Alice');
    await tester.enterText(find.byType(TextField).at(1), 'Bob');
    await tester.enterText(find.byType(TextField).at(2), 'Cara');
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.byType(GameFlowScreen), findsOneWidget);
    // "Alice" now legitimately appears more than once (seating list,
    // standings panel, contract badge) — just confirm it's there.
    expect(find.textContaining('Alice'), findsWidgets);
  });

  testWidgets('a full 27-round game can be played end to end via taps',
      (tester) async {
    final controller = GameController()
      ..setupPlayers(['Alice', 'Bob', 'Cara']);

    await tester.pumpWidget(
      MaterialApp(home: GameFlowScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    // Seating reveal.
    expect(controller.phase, GamePhase.seatingReveal);
    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    var safety = 0;
    while (controller.phase != GamePhase.gameOver) {
      safety++;
      expect(safety, lessThan(15000), reason: 'game flow looped without reaching gameOver');

      switch (controller.phase) {
        case GamePhase.deviceHandoff:
          await tester.tap(find.text('Ready'));
          break;

        case GamePhase.declaring:
          // The declarer must see their own real 10-card hand for THIS
          // round while declaring — not a stale hand left over from
          // whatever round they last played a card in.
          expect(controller.activePlayer.hand.length, 10,
              reason: 'declarer must see all 10 of their own cards while declaring');

          final options = controller.legalDeclarations;
          final nonTrump = options.firstWhere(
            (t) => t != ContractType.trump,
            orElse: () => ContractType.trump,
          );
          if (nonTrump != ContractType.trump) {
            await tester.tap(find.byKey(ValueKey('contract_${nonTrump.name}')));
          } else {
            // Only trump is legal for this player right now: open the "+"
            // suit picker, pick a suit, and confirm.
            await tester.tap(find.byKey(const ValueKey('contract_plus')));
            await tester.pump();
            await tester.tap(find.byKey(ValueKey('suit_${Suit.clubs.name}')));
            await tester.pump();
            await tester.tap(find.byKey(const ValueKey('declare_button')));
          }
          break;

        case GamePhase.prikoup:
          final hand = controller.prikoupPreviewHand;
          final legalToBury =
              hand.where((c) => !controller.isBurialForbidden(c)).take(2);
          for (final card in legalToBury) {
            // The hand now runs as a single scrollable row (matching the
            // online table) rather than wrapping to fit — a card past
            // the visible edge needs to be scrolled into view first.
            final finder = find.byKey(ValueKey(card));
            await tester.ensureVisible(finder);
            await tester.pump();
            await tester.tap(finder);
            await tester.pump();
          }
          await tester.tap(find.text('Bury & Start'));
          break;

        case GamePhase.trick:
          final legal = controller.legalMovesForActivePlayer;
          expect(legal, isNotEmpty);
          final finder = find.byKey(ValueKey(legal.first));
          await tester.ensureVisible(finder);
          await tester.pump();
          await tester.tap(finder);
          break;

        case GamePhase.trickResolved:
          await tester.tap(find.text('Continue'));
          break;

        case GamePhase.roundSummary:
          await tester.tap(find.text('Next Round'));
          break;

        case GamePhase.playersSetup:
        case GamePhase.seatingReveal:
        case GamePhase.gameOver:
          break;
      }
      await tester.pumpAndSettle();
    }

    expect(controller.game.isGameOver, isTrue);
    expect(find.text('Game Over!'), findsOneWidget);

    // Sanity check straight from the engine: burial restrictions
    // guarantee every one of the 9 "plus" rounds (3 per player) always
    // totals exactly +80 across all 3 players, and every one of the 18
    // fixed-contract rounds (6 per player) always totals exactly -40 —
    // so before premiums the game total is always exactly 0, plus up to
    // +40 per player (max 3) for the whole-game "პრემია" bonus.
    final total = controller.standings.values.fold<int>(0, (a, b) => a + b);
    expect(total % 40, 0);
    expect(total, inInclusiveRange(0, 120));
  });
}
