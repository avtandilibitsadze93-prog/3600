// Verifies OnlineGameClient's auto-reconnect path directly (no widget
// tree needed) against a real server: a simulated connection drop
// mid-game should transparently resume the same seat, without ever
// falling back to 'closed'/'error', and without needing the player to
// do anything.

import 'package:flutter_test/flutter_test.dart';
import 'package:king_game_engine/king_game_engine.dart';
import 'package:king_game/game/online_game_client.dart';
import 'package:king_game_server/app.dart';

void _autoPlay(OnlineGameClient client) {
  client.addListener(() {
    if (client.isMyTurnToDeclare) {
      final nonTrump = client.legalDeclarations.firstWhere(
        (t) => t != ContractType.trump,
        orElse: () => ContractType.trump,
      );
      client.declare(nonTrump, trumpSuit: nonTrump == ContractType.trump ? Suit.clubs : null);
    } else if (client.isMyTurnToBury) {
      final legal = client.yourHand.where((c) => !isBurialForbidden(client.contract!, c)).take(2);
      client.bury(legal.toList());
    } else if (client.isMyTurnToPlay) {
      final legal = legalMoves(
        hand: client.yourHand,
        alreadyPlayedThisTrick: client.trick.map((p) => p.card).toList(),
        contract: client.contract!,
      );
      if (legal.isNotEmpty) client.playCard(legal.first);
    }
  });
}

void main() {
  test('a simulated connection drop mid-game auto-reconnects to the same seat, '
      'and the game still finishes', () async {
    final server = await startServer(
      disconnectGrace: const Duration(seconds: 2),
      trickCompleteDelay: Duration.zero,
    );
    addTearDown(server.close);

    final clients = [OnlineGameClient(), OnlineGameClient(), OnlineGameClient()];
    addTearDown(() {
      for (final c in clients) {
        c.dispose();
      }
    });
    for (final c in clients) {
      _autoPlay(c);
    }

    final names = ['ავთო', 'ვასო', 'გიორგი'];
    for (var i = 0; i < 3; i++) {
      clients[i].connect('ws://127.0.0.1:${server.port}/ws', names[i]);
    }

    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 20));
      return clients[0].roundNumber < 2;
    }).timeout(const Duration(seconds: 15));

    final seatBeforeDrop = clients[0].mySeat;
    clients[0].debugSimulateConnectionDrop();

    // Should transiently show 'reconnecting', never 'closed'/'error'.
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 10));
      return clients[0].status == ConnectionStatus.inGame;
    }).timeout(const Duration(seconds: 2));
    expect(clients[0].status, isNot(ConnectionStatus.closed));
    expect(clients[0].status, isNot(ConnectionStatus.error));

    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 20));
      return clients[0].status != ConnectionStatus.inGame;
    }).timeout(const Duration(seconds: 10));
    expect(clients[0].mySeat, seatBeforeDrop, reason: 'must resume the same seat after reconnecting');

    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 20));
      return !clients.every((c) => c.isGameOver);
    }).timeout(const Duration(seconds: 90));

    expect(server.registry.find('ავთო')!.isBanned, isFalse,
        reason: 'a reconnect within the grace period must not trigger the ban');
  });

  test('an unreachable server address fails fast with a clear error, '
      'instead of spinning on "connecting" forever', () async {
    final client = OnlineGameClient();
    addTearDown(client.dispose);

    // A private, non-routable address per RFC 5737 — guaranteed to never
    // answer, standing in for a misconfigured or not-yet-deployed server.
    client.connect('ws://192.0.2.1:8080/ws', 'ავთო');
    expect(client.status, ConnectionStatus.connecting);

    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return client.status == ConnectionStatus.connecting;
    }).timeout(const Duration(seconds: 15));

    expect(client.status, ConnectionStatus.error);
    expect(client.errorMessage, isNotNull);
  });
}
