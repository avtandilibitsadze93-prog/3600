import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:king_game_engine/king_game_engine.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus { connecting, queued, inGame, reconnecting, error, closed }

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
  String? _serverUrl;
  String? _username;
  String? _tableCode;
  bool _intentionalClose = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  /// A dropped connection is only worth auto-retrying if we'd actually
  /// gotten into a match — a failure while still connecting/queued is a
  /// real error, not a network blip mid-game.
  static const int _maxReconnectAttempts = 6;
  static const List<Duration> _reconnectBackoff = [
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 5),
    Duration(seconds: 5),
  ];

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
  /// Score sheet: for each seat, their completed fixed-contract results
  /// (keyed by contract type) and completed "plus" results in play
  /// order — backs the ცხრილი (score table) view.
  Map<int, Map<ContractType, int>> fixedContractResults = {};
  Map<int, List<int>> plusResults = {};
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

  /// [tableCode] is an optional password agreed on with friends (e.g. over
  /// messenger) so the three of you land in the same private match
  /// instead of public matchmaking — see [MatchmakingQueue] server-side.
  void connect(String serverUrl, String username, {String? tableCode}) {
    _serverUrl = serverUrl;
    _username = username;
    _tableCode = tableCode;
    _intentionalClose = false;
    _connect();
  }

  static const Duration _connectTimeout = Duration(seconds: 10);

  void _connect() {
    final uri = Uri.parse(_serverUrl!).replace(queryParameters: {
      'username': _username!,
      if (_tableCode != null && _tableCode!.isNotEmpty) 'tableCode': _tableCode!,
    });
    status = _reconnectAttempt > 0 ? ConnectionStatus.reconnecting : ConnectionStatus.connecting;
    notifyListeners();
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    // WebSocketChannel.connect() returns immediately and connects lazily —
    // without this, an unreachable/misconfigured server address (or a
    // real server that's simply down) leaves the UI spinning on
    // "connecting..." forever instead of ever reaching onDone/onError.
    channel.ready.timeout(_connectTimeout).then(
      (_) {},
      onError: (Object e) {
        if (!identical(_channel, channel)) return;
        _handleDrop(
          error: e is TimeoutException ? 'სერვერთან დაკავშირება ვერ მოხერხდა (timeout)' : '$e',
        );
      },
    );
    _sub = channel.stream.listen(
      (raw) => _onMessage(jsonDecode(raw as String) as Map<String, dynamic>),
      onDone: _handleDrop,
      onError: (Object e) => _handleDrop(error: '$e'),
    );
  }

  /// A connection that was actually in a match — as opposed to one that
  /// never got past connecting/queued — is worth quietly retrying a few
  /// times before giving up: on a real phone this is what a brief wifi
  /// hiccup looks like, and the server holds the seat open for exactly
  /// this (see Room's disconnect grace period).
  void _handleDrop({String? error}) {
    if (_intentionalClose) return;
    final wasInGame = status == ConnectionStatus.inGame || status == ConnectionStatus.reconnecting;
    if (!wasInGame || _reconnectAttempt >= _maxReconnectAttempts) {
      status = error != null ? ConnectionStatus.error : ConnectionStatus.closed;
      errorMessage = error;
      notifyListeners();
      return;
    }
    final delay = _reconnectBackoff[_reconnectAttempt.clamp(0, _reconnectBackoff.length - 1)];
    _reconnectAttempt++;
    status = ConnectionStatus.reconnecting;
    notifyListeners();
    _reconnectTimer = Timer(delay, _connect);
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
        _reconnectAttempt = 0;
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
    fixedContractResults = {
      for (final e in (s['scoreTable'] as Map).entries)
        int.parse(e.key as String): {
          for (final fe in (e.value['fixed'] as Map).entries)
            ContractType.values.byName(fe.key as String): fe.value as int,
        },
    };
    plusResults = {
      for (final e in (s['scoreTable'] as Map).entries)
        int.parse(e.key as String): (e.value['plus'] as List).cast<int>(),
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

  void leave() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _send({'type': 'leave'});
  }

  /// Best-effort: a channel can die at any moment between a listener
  /// checking e.g. [isMyTurnToPlay] and this actually running (that gap
  /// is exactly how a disconnect mid-turn looks). Losing this specific
  /// message is fine — either the server never got it and this seat's
  /// turn will simply time out into the bot/reconnect path, or it did
  /// and this was a harmless double-send race; there's nothing useful to
  /// retry here since [_handleDrop] already owns recovering the socket.
  void _send(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (_) {
      // Swallowed on purpose — see doc comment above.
    }
  }

  /// Test-only hook to simulate an unexpected connection drop (a phone
  /// losing signal, wifi/cellular handoff, ...) without going through a
  /// real network failure — exercises the exact same auto-reconnect path
  /// [_handleDrop] would take for a genuine drop.
  @visibleForTesting
  void debugSimulateConnectionDrop() => _channel?.sink.close();

  @override
  void dispose() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
