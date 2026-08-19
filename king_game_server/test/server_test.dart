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

  static Future<TestClient> connect(
    int port,
    String username, {
    bool autoPlay = true,
    String? tableCode,
  }) async {
    final query = tableCode != null ? '&tableCode=$tableCode' : '';
    final socket = await WebSocket.connect('ws://127.0.0.1:$port/ws?username=$username$query');
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

  Future<void> waitForGameOver({Duration timeout = const Duration(seconds: 45)}) =>
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
      server = await startServer(
        disconnectGrace: const Duration(milliseconds: 300),
        trickCompleteDelay: Duration.zero,
      );
    });

    tearDown(() => server.close());

    test('3 real socket clients get matched and play a full 27-round game, '
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

      // Regression check: the declarer must see their own actual 10-card
      // hand for THIS round as soon as declaring starts, not whatever
      // was left over (often nonzero now, thanks to early-terminated
      // rounds) from whichever round they last played a card in — see
      // GameEngine.dealNextRound, which now deals hands immediately
      // instead of waiting until after a declaration is chosen.
      for (final client in clients) {
        for (final state in client.allStates) {
          if (state['phase'] == 'declaring' && state['declarerSeat'] == state['yourSeat']) {
            expect((state['yourHand'] as List).length, 10,
                reason: 'the declarer must see all 10 of their own cards while declaring, not a stale hand');
          }
        }
      }

      final finalStandings = clients.first.latestState!['standings'] as Map;
      final total = finalStandings.values.fold<int>(0, (a, b) => a + (b as int));
      // See the identical check in online_widget_test.dart for why this
      // must always land on a multiple of 40 between 0 and 120.
      expect(total % 40, 0);
      expect(total, inInclusiveRange(0, 120));

      // The score sheet (ცხრილი) sent alongside standings is
      // declarer-centric — one recorded result per round *that seat
      // declared* — so every seat ends with exactly 6 fixed-contract
      // results and 3 plus results, one per turn they used, regardless
      // of what the other 2 seats scored during those same rounds.
      final finalScoreTable = clients.first.latestState!['scoreTable'] as Map;
      for (final seat in finalScoreTable.keys) {
        final entry = finalScoreTable[seat] as Map;
        final fixed = (entry['fixed'] as Map).values.cast<int>();
        final plus = (entry['plus'] as List).cast<int>();
        expect(fixed, hasLength(6), reason: 'seat $seat must have all 6 fixed contracts recorded');
        expect(plus, hasLength(3), reason: 'seat $seat must have all 3 plus turns recorded');
      }

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

    test('a quick reconnect (within the grace period) resumes the same seat, '
        'no ban applied, and the game still finishes', () async {
      final reconnectServer = await startServer(
        disconnectGrace: const Duration(seconds: 2),
        trickCompleteDelay: Duration.zero,
      );
      addTearDown(reconnectServer.close);

      final avto = await TestClient.connect(reconnectServer.port, 'ავთო');
      final vaso = await TestClient.connect(reconnectServer.port, 'ვასო');
      final giorgi = await TestClient.connect(reconnectServer.port, 'გიორგი');

      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        return (avto.latestState?['roundNumber'] ?? 1) < 2;
      });

      final avtoSeat = avto.latestState!['yourSeat'] as int;
      await avto.close();

      // Reconnect quickly — well inside the 2s grace window — with a new
      // socket but the same username, simulating a phone briefly losing
      // and regaining network.
      final avtoAgain = await TestClient.connect(reconnectServer.port, 'ავთო');
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        return avtoAgain.latestState == null;
      });
      expect(avtoAgain.latestState!['yourSeat'], avtoSeat,
          reason: 'reconnecting must resume the same seat, not join a new match');

      await Future.wait([
        avtoAgain.waitForGameOver(),
        vaso.waitForGameOver(),
        giorgi.waitForGameOver(),
      ]);

      expect(reconnectServer.registry.find('ავთო')!.isBanned, isFalse,
          reason: 'reconnecting within the grace period must not trigger the ban');

      await avtoAgain.close();
      await vaso.close();
      await giorgi.close();
    });

    test('private tables: only players who share the same password get matched, '
        'and separate tables never mix', () async {
      final tableA = [
        await TestClient.connect(server.port, 'ავთოA', tableCode: 'friends1'),
        await TestClient.connect(server.port, 'ვასოA', tableCode: 'friends1'),
      ];
      final tableB = [
        await TestClient.connect(server.port, 'ავთოB', tableCode: 'friends2'),
        await TestClient.connect(server.port, 'ვასოB', tableCode: 'friends2'),
      ];

      // Neither table has its 3rd member yet — nobody should be in a
      // game, and definitely not mixed with the other table.
      await Future.delayed(const Duration(milliseconds: 100));
      for (final c in [...tableA, ...tableB]) {
        expect(c.latestState, isNull, reason: '${c.username} should still be waiting for its own table to fill');
      }

      final giorgiA = await TestClient.connect(server.port, 'გიორგიA', tableCode: 'friends1');
      await Future.wait([...tableA.map((c) => c.waitForGameOver()), giorgiA.waitForGameOver()]);

      final namesInA = <String>{
        for (final c in [...tableA, giorgiA])
          for (final p in (c.latestState!['players'] as List)) (p as Map)['name'] as String,
      };
      expect(namesInA, {'ავთოA', 'ვასოA', 'გიორგიA'},
          reason: 'table "friends1" must only ever contain the 3 players who used that password');

      // Table B is still short a player — must not have been dragged into
      // table A's game just because both tables filled around the same time.
      for (final c in tableB) {
        expect(c.latestState, isNull);
      }

      for (final c in [...tableA, giorgiA, ...tableB]) {
        await c.close();
      }
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
