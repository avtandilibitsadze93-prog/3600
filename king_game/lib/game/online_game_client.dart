import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:king_game_engine/king_game_engine.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { connecting, queued, inGame, error, closed }

class SeatInfo {
  final int seat;
  final String name;
  final bool connected;
  SeatInfo({required this.seat, required this.name, required this.connected});
}

/// Talks to the online King game server over a WebSocket. This class
/// never decides anything about the game itself — every field here is
/// just the server's last broadcast, rendered; every action method just
/// forwards the player's choice back to the server, which is the sole
/// authority on whether it's legal.
class OnlineGameClient extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  ConnectionStatus status = ConnectionStatus.connecting;
  String? errorMessage;

  /// Set when the server rejects a specific action (wrong turn, illegal
  /// card, ...) while the game is already underway — distinct from
  /// [errorMessage], which means the connection itself failed/was
  /// refused (e.g. the leave-early ban) before ever reaching a room.
  String? lastActionError;

  String phase = 'declaring';
  int roundNumber = 1;
  int? mySeat;
  List<SeatInfo> players = [];
  Map<int, int> standings = {};
  int? declarerSeat;
  ContractType? contract;
  Suit? trumpSuit;
  List<ContractType> legalDeclarations = [];
  int? turnSeat;
  List<TrickPlay> trick = [];
  int? lastTrickWinnerSeat;
  List<PlayingCard> lastTrickCards = [];
  ContractType? lastRoundContract;
  Map<int, int> lastRoundDelta = {};
  List<PlayingCard> yourHand = [];

  bool get isMyTurnToDeclare => phase == 'declaring' && declarerSeat == mySeat;
  bool get isMyTurnToBury => phase == 'prikoup' && declarerSeat == mySeat;
  bool get isMyTurnToPlay => phase == 'trick' && turnSeat == mySeat;
  bool get isGameOver => phase == 'gameOver';

  String nameOf(int seat) => players.firstWhere((p) => p.seat == seat).name;

  void connect(String serverUrl, String username) {
    final uri = Uri.parse(serverUrl).replace(queryParameters: {'username': username});
    status = ConnectionStatus.connecting;
    notifyListeners();
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _sub = channel.stream.listen(
      (raw) => _onMessage(jsonDecode(raw as String) as Map<String, dynamic>),
      onDone: () {
        if (status != ConnectionStatus.error) status = ConnectionStatus.closed;
        notifyListeners();
      },
      onError: (Object e) {
        status = ConnectionStatus.error;
        errorMessage = '$e';
        notifyListeners();
      },
    );
  }

  void _onMessage(Map<String, dynamic> msg) {
    switch (msg['type'] as String) {
      case 'queued':
        status = ConnectionStatus.queued;
        break;
      case 'error':
        if (status == ConnectionStatus.inGame) {
          lastActionError = msg['message'] as String;
        } else {
          status = ConnectionStatus.error;
          errorMessage = msg['message'] as String;
        }
        break;
      case 'state':
        status = ConnectionStatus.inGame;
        _applyState(msg);
        break;
    }
    notifyListeners();
  }

  void _applyState(Map<String, dynamic> s) {
    phase = s['phase'] as String;
    roundNumber = s['roundNumber'] as int;
    mySeat = s['yourSeat'] as int;
    players = [
      for (final p in (s['players'] as List).cast<Map<String, dynamic>>())
        SeatInfo(seat: p['seat'] as int, name: p['name'] as String, connected: p['connected'] as bool),
    ];
    standings = {
      for (final e in (s['standings'] as Map).entries) int.parse(e.key as String): e.value as int,
    };
    declarerSeat = s['declarerSeat'] as int?;
    contract = s['contract'] != null ? ContractType.values.byName(s['contract'] as String) : null;
    trumpSuit = s['trumpSuit'] != null ? Suit.values.byName(s['trumpSuit'] as String) : null;
    legalDeclarations = s['legalDeclarations'] != null
        ? (s['legalDeclarations'] as List).cast<String>().map(ContractType.values.byName).toList()
        : [];
    turnSeat = s['turnSeat'] as int?;
    trick = s['trick'] != null
        ? (s['trick'] as List)
            .cast<Map<String, dynamic>>()
            .map((p) => TrickPlay(p['seat'] as int, cardFromJson(p['card'] as Map<String, dynamic>)))
            .toList()
        : [];
    lastTrickWinnerSeat = s['lastTrickWinnerSeat'] as int?;
    lastTrickCards = s['lastTrickCards'] != null ? cardsFromJson(s['lastTrickCards'] as List) : [];
    lastRoundContract =
        s['lastRoundContract'] != null ? ContractType.values.byName(s['lastRoundContract'] as String) : null;
    lastRoundDelta = s['lastRoundDelta'] != null
        ? {for (final e in (s['lastRoundDelta'] as Map).entries) int.parse(e.key as String): e.value as int}
        : {};
    yourHand = cardsFromJson(s['yourHand'] as List);
  }

  void clearActionError() {
    lastActionError = null;
    notifyListeners();
  }

  void declare(ContractType type, {Suit? trumpSuit}) {
    _send({
      'type': 'declare',
      'contract': type.name,
      if (trumpSuit != null) 'trumpSuit': trumpSuit.name,
    });
  }

  void bury(List<PlayingCard> cards) => _send({'type': 'bury', 'cards': cardsToJson(cards)});

  void playCard(PlayingCard card) => _send({'type': 'play', 'card': cardToJson(card)});

  void leave() => _send({'type': 'leave'});

  void _send(Map<String, dynamic> msg) => _channel?.sink.add(jsonEncode(msg));

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
