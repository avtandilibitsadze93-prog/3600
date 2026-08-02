// End-to-end tests against a *real* running server over *real* WebSocket
// connections (dart:io WebSocket, not fakes) — the server-side analogue
// of the widget test that drove the local pass-and-play UI through a
// full 9-round game. Here, 3 independent socket connections stand in
// for 3 separate phones.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:king_game_server/app.dart';
import 'package:test/test.dart';

/// Mirrors RoundEngine.isBurialForbidden's rule so the test bot can bury
/// legally without needing a RoundEngine instance of its own (only the
/// server holds one) — exactly the same tradeoff a real client faces.
bool _burialForbidden(String contract, Map card) {
  final suit = card['suit'] as String;
  final rank = card['rank'] as String;
  if ((contract == 'king' || contract == 'noHearts') && suit == 'hearts') return true;
  if (contract == 'queen' && rank == 'queen') return true;
  if (contract == 'jack' && rank == 'jack') return true;
  return false;
}

class TestClient {
  final WebSocket socket;
  final String username;
  final bool autoPlay;
  Map<String, dynamic>? latestState;
  final List<Map<String, dynamic>> allStates = [];
  String? lastError;
  final _gameOver = Completer<void>();
  late final StreamSubscription _sub;

  TestClient._(this.socket, this.username, this.autoPlay);

  static Future<TestClient> connect(int port, String username, {bool autoPlay = true}) async {
    final socket = await WebSocket.connect('ws://127.0.0.1:$port/ws?username=$username');
    final client = TestClient._(socket, username, autoPlay);
    client._sub = socket.listen((raw) => client._onMessage(jsonDecode(raw as String)));
    return client;
  }

  void _onMessage(Map<String, dynamic> msg) {
    if (msg['type'] == 'error') {
      lastError = msg['message'] as String;
      return;
    }
    if (msg['type'] != 'state') return;
    latestState = msg;
    allStates.add(msg);
    if (msg['phase'] == 'gameOver' && !_gameOver.isCompleted) {
      _gameOver.complete();
    }
    if (autoPlay) _autoRespond(msg);
  }

  void _autoRespond(Map<String, dynamic> state) {
    final mySeat = state['yourSeat'] as int;
    switch (state['phase'] as String) {
      case 'declaring':
        if (state['declarerSeat'] != mySeat) return;
        final options = (state['legalDeclarations'] as List).cast<String>();
        final nonTrump = options.firstWhere((t) => t != 'trump', orElse: () => options.first);
        final msg = <String, dynamic>{'type': 'declare', 'contract': nonTrump};
        if (nonTrump == 'trump') msg['trumpSuit'] = 'clubs';
        send(msg);
        break;

      case 'prikoup':
        if (state['declarerSeat'] != mySeat) return;
        final hand = (state['yourHand'] as List).cast<Map>();
        final contract = state['contract'] as String;
        final legalToBury = hand.where((c) => !_burialForbidden(contract, c)).take(2).toList();
        send({'type': 'bury', 'cards': legalToBury});
        break;

      case 'trick':
        if (state['turnSeat'] != mySeat) return;
        final hand = (state['yourHand'] as List).cast<Map>();
        final trick = (state['trick'] as List).cast<Map>();
        final contract = state['contract'] as String;
        Map card;
        if (trick.isEmpty) {
          // Leading: king/noHearts forbid leading a heart unless it's all
          // that's left in hand — mirrors RoundEngine's restrictsLeadingHearts.
          final restrictsHearts = contract == 'king' || contract == 'noHearts';
          final nonHearts = hand.where((c) => c['suit'] != 'hearts').toList();
          card = (restrictsHearts && nonHearts.isNotEmpty) ? nonHearts.first : hand.first;
        } else {
          final ledSuit = trick.first['card']['suit'] as String;
          final followable = hand.where((c) => c['suit'] == ledSuit).toList();
          card = followable.isNotEmpty ? followable.first : hand.first;
        }
        send({'type': 'play', 'card': card});
        break;
    }
  }

  void send(Map<String, dynamic> msg) => socket.add(jsonEncode(msg));

  Future<void> waitForGameOver({Duration timeout = const Duration(seconds: 20)}) =>
      _gameOver.future.timeout(timeout);

  Future<void> close() async {
    await _sub.cancel();
    await socket.close();
  }
}

void main() {
  group('online multiplayer server', () {
    late RunningServer server;

    setUp(() async {
      server = await startServer(disconnectGrace: const Duration(milliseconds: 300));
    });

    tearDown(() => server.close());

    test('3 real socket clients get matched and play a full 9-round game, '
        'and no client ever receives another seat\'s hand', () async {
      final clients = <TestClient>[
        await TestClient.connect(server.port, 'ავთო'),
        await TestClient.connect(server.port, 'ვასო'),
        await TestClient.connect(server.port, 'გიორგი'),
      ];

      await Future.wait(clients.map((c) => c.waitForGameOver()));

      // Structural privacy check across EVERY snapshot each client ever
      // received during the whole game: the union of cards any one
      // client saw in 'yourHand' must never include a card any other
      // client also saw in theirs at an overlapping moment. We check the
      // stronger, simpler invariant that holds throughout a round: at any
      // single point in time, the 3 clients' current hands are disjoint.
      for (var i = 0; i < clients[0].allStates.length; i++) {
        final seenCards = <String>{};
        for (final client in clients) {
          if (i >= client.allStates.length) continue;
          final hand = (client.allStates[i]['yourHand'] as List).cast<Map>();
          for (final c in hand) {
            final key = '${c['suit']}_${c['rank']}';
            expect(seenCards.contains(key), isFalse,
                reason: "card $key appeared in more than one client's yourHand "
                    'at snapshot $i');
            seenCards.add(key);
          }
        }
      }

      final finalStandings = clients.first.latestState!['standings'] as Map;
      final total = finalStandings.values.fold<int>(0, (a, b) => a + (b as int));
      expect(total, inInclusiveRange(0, 240));

      for (final c in clients) {
        await c.close();
      }
    });

    test('a disconnect mid-game triggers bot takeover, the other 2 finish '
        'the game, and the disconnector is banned', () async {
      final avto = await TestClient.connect(server.port, 'ავთო');
      final vaso = await TestClient.connect(server.port, 'ვასო');
      final giorgi = await TestClient.connect(server.port, 'გიორგი');

      // Let a round or two play out, then have one player vanish.
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        return (avto.latestState?['roundNumber'] ?? 1) < 2;
      });
      await avto.close();

      await Future.wait([vaso.waitForGameOver(), giorgi.waitForGameOver()]);

      expect(server.registry.find('ავთო')!.isBanned, isTrue,
          reason: 'leaving mid-game must trigger the 4h ban');

      await vaso.close();
      await giorgi.close();
    });

    test('a banned username is rejected at the queue with an error, not matched', () async {
      server.registry.register('ბანილი').bannedUntil = DateTime.now().add(const Duration(hours: 4));

      final banned = await TestClient.connect(server.port, 'ბანილი', autoPlay: false);
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        return banned.lastError == null;
      }).timeout(const Duration(seconds: 5));

      expect(banned.lastError, isNotNull);
      await banned.close();
    });
  });
}
