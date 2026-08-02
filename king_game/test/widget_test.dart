// Drives a full 9-round game through the real UI (GameFlowScreen), tapping
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

  testWidgets('a full 9-round game can be played end to end via taps',
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
      expect(safety, lessThan(5000), reason: 'game flow looped without reaching gameOver');

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
            await tester.tap(find.text(nonTrump.georgianName));
          } else {
            // Only trump is legal for this player right now: pick a suit
            // and confirm.
            await tester.tap(find.text(Suit.clubs.georgianName).first);
            await tester.pump();
            await tester.tap(find.text('კოზირის გამოცხადება'));
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

    // Sanity check straight from the engine: with exactly 3 mandatory
    // trump rounds (always +80 total) and 6 fixed-contract rounds (each
    // between -40 and 0), the game total is always in [0, 240] — see the
    // scoring walkthrough already verified against bin/simulate.dart.
    final total = controller.standings.values.fold<int>(0, (a, b) => a + b);
    expect(total, inInclusiveRange(0, 240));
  });
}
