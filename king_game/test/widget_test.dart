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
    await tester.enterText(find.byType(TextField).at(0), 'ავთო');
    await tester.enterText(find.byType(TextField).at(1), 'ვასო');
    await tester.enterText(find.byType(TextField).at(2), 'გიორგი');
    await tester.tap(find.text('დაწყება'));
    await tester.pumpAndSettle();

    expect(find.byType(GameFlowScreen), findsOneWidget);
    expect(find.textContaining('ავთო'), findsOneWidget);
  });

  testWidgets('a full 27-round game can be played end to end via taps',
      (tester) async {
    final controller = GameController()
      ..setupPlayers(['ავთო', 'ვასო', 'გიორგი']);

    await tester.pumpWidget(
      MaterialApp(home: GameFlowScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    // Seating reveal.
    expect(controller.phase, GamePhase.seatingReveal);
    await tester.tap(find.text('თამაშის დაწყება'));
    await tester.pumpAndSettle();

    var safety = 0;
    while (controller.phase != GamePhase.gameOver) {
      safety++;
      expect(safety, lessThan(15000), reason: 'game flow looped without reaching gameOver');

      switch (controller.phase) {
        case GamePhase.deviceHandoff:
          await tester.tap(find.text('მზად ვარ'));
          break;

        case GamePhase.declaring:
          final options = controller.legalDeclarations;
          final nonTrump = options.firstWhere(
            (t) => t != ContractType.trump,
            orElse: () => ContractType.trump,
          );
          if (nonTrump != ContractType.trump) {
            // find.text() alone would also match the same rank name in
            // the hand preview above the list (e.g. "მეფე"/king shown as
            // both a contract choice and a card rank) — scope to the
            // ListTile that actually offers this contract.
            await tester.tap(find.widgetWithText(ListTile, nonTrump.georgianName));
          } else {
            // Only trump is legal for this player right now: pick a suit
            // and confirm.
            await tester.tap(find.text(Suit.clubs.georgianName).first);
            await tester.pump();
            await tester.tap(find.text('გამოცხადება'));
          }
          break;

        case GamePhase.prikoup:
          final hand = controller.prikoupPreviewHand;
          final legalToBury =
              hand.where((c) => !controller.isBurialForbidden(c)).take(2);
          for (final card in legalToBury) {
            await tester.tap(find.byKey(ValueKey(card)));
            await tester.pump();
          }
          await tester.tap(find.text('დამარხვა და დაწყება'));
          break;

        case GamePhase.trick:
          final legal = controller.legalMovesForActivePlayer;
          expect(legal, isNotEmpty);
          await tester.tap(find.byKey(ValueKey(legal.first)));
          break;

        case GamePhase.trickResolved:
          await tester.tap(find.text('გაგრძელება'));
          break;

        case GamePhase.roundSummary:
          await tester.tap(find.text('შემდეგი რაუნდი'));
          break;

        case GamePhase.playersSetup:
        case GamePhase.seatingReveal:
        case GamePhase.gameOver:
          break;
      }
      await tester.pumpAndSettle();
    }

    expect(controller.game.isGameOver, isTrue);
    expect(find.text('თამაში დასრულდა!'), findsOneWidget);

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
