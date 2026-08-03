// Spins up a REAL king_game_server (in-process, ephemeral local port) and
// drives 3 independent OnlineGameFlowScreen widget trees — one per seat,
// standing in for 3 separate phones — through a full 27-round game via
// real taps over real WebSocket connections. This is the online
// counterpart to the local pass-and-play widget test: it proves the
// actual screens are wired correctly to OnlineGameClient and the real
// server, not just that the two talk to each other at the protocol level.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:king_game_engine/king_game_engine.dart';
import 'package:king_game_server/app.dart' as king_game_server;

import 'package:king_game/game/online_game_client.dart';
import 'package:king_game/screens/online_game_flow_screen.dart';

// Flutter's widget-test binding runs pump() against a *fake* clock — real
// socket I/O never gets a chance to complete unless real time is allowed
// to pass via tester.runAsync(), followed by a pump() to let the widget
// tree react to whatever state changes already happened.
Future<void> _settleNetwork(WidgetTester tester) async {
  await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
  await tester.pump();
}

// tester.tap() alone doesn't scroll a target into view first — it just
// taps wherever the widget currently is, which can be clipped outside a
// SingleChildScrollView's visible viewport (e.g. a 10+ card hand on the
// cramped 3-way-split test window). A real finger would scroll first;
// ensureVisible() is the test-harness equivalent of that.
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxIterations = 400,
}) async {
  for (var i = 0; i < maxIterations; i++) {
    if (condition()) return;
    await _settleNetwork(tester);
  }
  throw StateError('condition not met after $maxIterations pumps');
}

void main() {
  testWidgets(
    '3 online clients play a full game through the real screens against a real local server',
    (tester) async {
      final server =
          await king_game_server.startServer(disconnectGrace: const Duration(milliseconds: 300));
      addTearDown(server.close);

      final names = ['ავთო', 'ვასო', 'გიორგი'];
      final clients = [for (var i = 0; i < 3; i++) OnlineGameClient()];
      addTearDown(() {
        for (final c in clients) {
          c.dispose();
        }
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey('seat-$i'),
                    child: MaterialApp(
                      home: OnlineGameFlowScreen(client: clients[i]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

      for (var i = 0; i < 3; i++) {
        clients[i].connect('ws://127.0.0.1:${server.port}/ws', names[i]);
      }
      await _pumpUntil(tester, () => clients.every((c) => c.status == ConnectionStatus.inGame));

      // Structural privacy check, refreshed on every iteration below too:
      // no two clients' current hands may share a card.
      void assertHandsDisjoint() {
        final seen = <String>{};
        for (final c in clients) {
          for (final card in c.yourHand) {
            final key = '${card.suit}_${card.rank}';
            expect(seen.contains(key), isFalse, reason: 'card $key leaked across clients');
            seen.add(key);
          }
        }
      }

      var safety = 0;
      while (!clients.every((c) => c.isGameOver)) {
        safety++;
        expect(safety, lessThan(9000), reason: 'game did not reach gameOver in time');
        assertHandsDisjoint();

        for (var i = 0; i < 3; i++) {
          final client = clients[i];
          final seat = find.byKey(ValueKey('seat-$i'));

          if (client.isMyTurnToDeclare) {
            final nonTrump = client.legalDeclarations.firstWhere(
              (t) => t != ContractType.trump,
              orElse: () => ContractType.trump,
            );
            if (nonTrump != ContractType.trump) {
              final f = find.descendant(of: seat, matching: find.text(nonTrump.georgianName));
              if (tester.any(f)) await _tapVisible(tester, f.first);
            } else {
              final suitF = find.descendant(of: seat, matching: find.text(Suit.clubs.georgianName));
              if (tester.any(suitF)) {
                await _tapVisible(tester, suitF.first);
                await tester.pump();
                final confirmF = find.descendant(of: seat, matching: find.text('გამოცხადება'));
                if (tester.any(confirmF)) await _tapVisible(tester, confirmF.first);
              }
            }
          } else if (client.isMyTurnToBury) {
            final legalToBury =
                client.yourHand.where((c) => !isBurialForbidden(client.contract!, c)).take(2);
            for (final card in legalToBury) {
              final f = find.descendant(of: seat, matching: find.byKey(ValueKey(card)));
              if (tester.any(f)) {
                await _tapVisible(tester, f.first);
                await tester.pump();
              }
            }
            final confirmF = find.descendant(of: seat, matching: find.text('დამარხვა'));
            if (tester.any(confirmF)) await _tapVisible(tester, confirmF.first);
          } else if (client.isMyTurnToPlay) {
            final legal = legalMoves(
              hand: client.yourHand,
              alreadyPlayedThisTrick: client.trick.map((p) => p.card).toList(),
              contract: client.contract!,
            );
            if (legal.isNotEmpty) {
              final f = find.descendant(of: seat, matching: find.byKey(ValueKey(legal.first)));
              if (tester.any(f)) await _tapVisible(tester, f.first);
            }
          }
        }

        await _settleNetwork(tester);
      }

      expect(find.text('თამაში დასრულდა!'), findsNWidgets(3));

      // Burial restrictions guarantee every fixed-contract round's total
      // delta across all 3 players is always exactly -40 (the relevant
      // penalty cards/tricks can never be buried away), and every "plus"
      // round's is always exactly +80 (8 points × 10 tricks, however
      // they're split) — so 18 fixed + 9 plus rounds always sum to
      // exactly 0 before premiums, plus up to +40 per player (max 3) for
      // the whole-game "პრემია" bonus.
      final total = clients.first.standings.values.fold<int>(0, (a, b) => a + b);
      expect(total % 40, 0);
      expect(total, inInclusiveRange(0, 120));
    },
  );
}
