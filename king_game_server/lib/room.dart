import 'dart:async';
import 'dart:convert';

import 'package:king_game_engine/king_game_engine.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'user_registry.dart';

enum RoomPhase { declaring, prikoup, trick, gameOver }

enum _Mode { active, disconnectedGrace, bot }

class _Seat {
  final String username;
  WebSocketChannel? channel;
  _Mode mode = _Mode.active;
  Timer? graceTimer;

  _Seat(this.username, this.channel);
}

/// One live match: 3 seats (stable identity = join order = [Player.id]),
/// wrapping the shared, unmodified rules engine as the sole source of
/// truth. A seat's hand is only ever included in the JSON snapshot sent
/// to *that* seat's own socket — nothing else here would even know how
/// to address another seat's hand, since every engine call is scoped to
/// a specific [Player].
///
/// If a seat's socket drops, it gets [disconnectGrace] to reconnect
/// before falling back to a simple bot (picks the first legal option
/// every time) that plays out that seat's own hand — the same hand data
/// already held server-side for them, nothing borrowed from anyone
/// else. Any explicit leave, or a disconnect that never reconnects
/// before a game ends, bans that username for 4 hours via [registry].
class Room {
  final String id;
  final UserRegistry registry;
  final Duration disconnectGrace;
  final List<_Seat> seats;
  final void Function(String roomId)? onFinished;

  late final GameEngine game;
  RoundEngine? round;
  DealtHands? _dealt;
  Trick? currentTrick;

  RoomPhase phase = RoomPhase.declaring;
  int _turnGamePos = 0;

  int? lastTrickWinnerGamePos;
  List<PlayingCard> lastTrickCards = [];
  Map<int, int> lastRoundDelta = {};
  ContractType? lastRoundContract;

  Room({
    required this.id,
    required List<String> usernames,
    required List<WebSocketChannel> channels,
    required this.registry,
    this.disconnectGrace = const Duration(seconds: 30),
    this.onFinished,
  }) : seats = [for (var i = 0; i < 3; i++) _Seat(usernames[i], channels[i])] {
    final players = [
      for (var i = 0; i < 3; i++) Player(id: i, name: usernames[i]),
    ];
    final seating = determineSeatingByAceDraw([0, 1, 2]);
    game = GameEngine([for (final i in seating) players[i]]);
    for (var i = 0; i < 3; i++) {
      _listen(i, channels[i]);
    }
    _dealNewRound();
  }

  void _listen(int seat, WebSocketChannel channel) {
    channel.stream.listen(
      (raw) => _dispatch(seat, jsonDecode(raw as String) as Map<String, dynamic>),
      onDone: () => _handleDisconnect(seat),
      onError: (_) => _handleDisconnect(seat),
    );
  }

  bool get isFinished => phase == RoomPhase.gameOver;

  /// Seat index for [username] if they're one of this room's 3 players,
  /// else null — lets the matchmaking layer recognize a returning
  /// connection and route it back here instead of a fresh queue entry.
  int? seatForUsername(String username) {
    final i = seats.indexWhere((s) => s.username == username);
    return i == -1 ? null : i;
  }

  /// True only during the disconnect grace window — once a seat has
  /// been fully converted to a bot (and banned), that's final for this
  /// match; reconnecting wouldn't un-ban them, it would just let them
  /// keep playing a match they already abandoned.
  bool canReconnect(int seat) => seats[seat].mode == _Mode.disconnectedGrace;

  /// Lets a player who reconnects (new socket, same username) resume
  /// their seat instead of staying bot-controlled. The matchmaking layer
  /// is responsible for recognizing a returning username belongs to this
  /// room and routing their new connection here.
  void reconnect(int seat, WebSocketChannel channel) {
    final s = seats[seat];
    s.graceTimer?.cancel();
    s.mode = _Mode.active;
    s.channel = channel;
    _listen(seat, channel);
    _broadcastAll();
  }

  int _seatAt(int gamePos) => game.players[gamePos].id;

  void _dealNewRound() {
    _dealt = game.dealNextRound();
    _turnGamePos = game.currentDeclarerIndex;
    phase = RoomPhase.declaring;
    _broadcastAll();
    _maybeRunBotTurn();
  }

  void _dispatch(int seat, Map<String, dynamic> msg) {
    try {
      switch (msg['type'] as String) {
        case 'declare':
          _requireTurn(seat, RoomPhase.declaring);
          final type = ContractType.values.byName(msg['contract'] as String);
          final trumpSuit = msg['trumpSuit'] != null
              ? Suit.values.byName(msg['trumpSuit'] as String)
              : null;
          round = game.startRound(Declaration(type, trumpSuit: trumpSuit), _dealt!);
          phase = RoomPhase.prikoup;
          _broadcastAll();
          _maybeRunBotTurn();
          break;

        case 'bury':
          _requireTurn(seat, RoomPhase.prikoup);
          round!.exchangePrikoup(_dealt!.prikoup, cardsFromJson(msg['cards'] as List));
          _startNextTrick();
          break;

        case 'play':
          _requireTurn(seat, RoomPhase.trick);
          _playCard(cardFromJson(msg['card'] as Map<String, dynamic>));
          break;

        case 'leave':
          _convertToBot(seat, banned: true);
          break;

        default:
          _sendError(seat, 'უცნობი შეტყობინება: ${msg['type']}');
      }
    } on IllegalMoveException catch (e) {
      _sendError(seat, e.message);
    } on StateError catch (e) {
      _sendError(seat, e.message);
    } catch (e) {
      _sendError(seat, 'შეცდომა: $e');
    }
  }

  void _requireTurn(int seat, RoomPhase expectedPhase) {
    if (phase != expectedPhase) {
      throw StateError('ეს მოქმედება ახლა შეუძლებელია');
    }
    final turnSeat =
        expectedPhase == RoomPhase.prikoup ? _seatAt(game.currentDeclarerIndex) : _seatAt(_turnGamePos);
    if (seat != turnSeat) {
      throw StateError('ახლა თქვენი ჯერი არ არის');
    }
  }

  void _startNextTrick() {
    currentTrick = Trick();
    _turnGamePos = round!.currentLeaderIndex;
    phase = RoomPhase.trick;
    _broadcastAll();
    _maybeRunBotTurn();
  }

  void _playCard(PlayingCard card) {
    final player = game.players[_turnGamePos];
    round!.playCard(player, currentTrick!, card);

    if (!currentTrick!.isComplete) {
      _turnGamePos = (_turnGamePos + 1) % 3;
      _broadcastAll();
      _maybeRunBotTurn();
      return;
    }

    lastTrickWinnerGamePos = round!.resolveTrick(currentTrick!);
    lastTrickCards = currentTrick!.allCards;

    if (!round!.roundIsOver) {
      _startNextTrick();
      return;
    }

    lastRoundDelta = round!.computeRoundScore();
    lastRoundContract = round!.declaration.type;
    game.finishRound(round!);

    if (game.isGameOver) {
      phase = RoomPhase.gameOver;
      _broadcastAll();
      onFinished?.call(id);
    } else {
      _dealNewRound();
    }
  }

  // --- disconnect / bot takeover / ban -------------------------------

  void _handleDisconnect(int seat) {
    final s = seats[seat];
    if (s.mode != _Mode.active) return;
    s.mode = _Mode.disconnectedGrace;
    s.channel = null;
    _broadcastAll();
    s.graceTimer = Timer(disconnectGrace, () {
      if (s.mode == _Mode.disconnectedGrace) {
        _convertToBot(seat, banned: true);
      }
    });
  }

  void _convertToBot(int seat, {required bool banned}) {
    final s = seats[seat];
    if (s.mode == _Mode.bot) return;
    s.graceTimer?.cancel();
    s.mode = _Mode.bot;
    s.channel = null;
    if (banned && phase != RoomPhase.gameOver) {
      registry.banForLeavingEarly(s.username);
    }
    _broadcastAll();
    _maybeRunBotTurn();
  }

  /// A bot only ever calls into the engine using its OWN seat's [Player]
  /// object — the same restriction a real client has, just automated.
  /// It never reads another seat's hand because nothing here passes one.
  void _maybeRunBotTurn() {
    while (phase != RoomPhase.gameOver) {
      switch (phase) {
        case RoomPhase.declaring:
          final seat = _seatAt(_turnGamePos);
          if (seats[seat].mode != _Mode.bot) return;
          _botDeclare();
          break;
        case RoomPhase.prikoup:
          final seat = _seatAt(game.currentDeclarerIndex);
          if (seats[seat].mode != _Mode.bot) return;
          _botBury();
          break;
        case RoomPhase.trick:
          final seat = _seatAt(_turnGamePos);
          if (seats[seat].mode != _Mode.bot) return;
          _botPlay();
          break;
        case RoomPhase.gameOver:
          return;
      }
    }
  }

  void _botDeclare() {
    final options = game.legalDeclarationTypes(game.currentDeclarerIndex);
    final type = options.firstWhere((t) => t != ContractType.trump, orElse: () => options.first);
    final trumpSuit = type == ContractType.trump ? Suit.values.first : null;
    round = game.startRound(Declaration(type, trumpSuit: trumpSuit), _dealt!);
    phase = RoomPhase.prikoup;
    _broadcastAll();
  }

  void _botBury() {
    final declarer = game.players[game.currentDeclarerIndex];
    final preview = [...declarer.hand, ..._dealt!.prikoup];
    final toBury = preview.where((c) => !round!.isBurialForbidden(c)).take(2).toList();
    round!.exchangePrikoup(_dealt!.prikoup, toBury);
    _startNextTrick();
  }

  void _botPlay() {
    final player = game.players[_turnGamePos];
    final legal = round!.legalMoves(player, currentTrick!);
    _playCard(legal.first);
  }

  // --- wire protocol ---------------------------------------------------

  void _sendError(int seat, String message) {
    seats[seat].channel?.sink.add(jsonEncode({'type': 'error', 'message': message}));
  }

  void _broadcastAll() {
    for (var seat = 0; seat < 3; seat++) {
      final channel = seats[seat].channel;
      if (channel == null) continue;
      channel.sink.add(jsonEncode(_snapshotFor(seat)));
    }
  }

  Map<String, dynamic> _snapshotFor(int seat) {
    final gamePos = game.players.indexWhere((p) => p.id == seat);
    final me = game.players[gamePos];
    final iAmDeclarer = seat == _seatAt(game.currentDeclarerIndex);

    return {
      'type': 'state',
      'phase': phase.name,
      'roundNumber': game.roundsPlayed + (game.isGameOver ? 0 : 1),
      'yourSeat': seat,
      'players': [
        for (var i = 0; i < 3; i++)
          {'seat': i, 'name': seats[i].username, 'connected': seats[i].mode != _Mode.bot},
      ],
      'standings': {for (final p in game.players) '${p.id}': p.totalScore},
      'declarerSeat': _seatAt(game.currentDeclarerIndex),
      if (round != null) 'contract': round!.declaration.type.name,
      if (round?.declaration.trumpSuit != null) 'trumpSuit': round!.declaration.trumpSuit!.name,
      if (phase == RoomPhase.declaring)
        'legalDeclarations': [
          for (final t in game.legalDeclarationTypes(game.currentDeclarerIndex)) t.name,
        ],
      if (phase == RoomPhase.trick) 'turnSeat': _seatAt(_turnGamePos),
      if (phase == RoomPhase.trick && currentTrick != null)
        'trick': [
          for (final p in currentTrick!.plays) {'seat': p.playerId, 'card': cardToJson(p.card)},
        ],
      if (lastTrickWinnerGamePos != null) 'lastTrickWinnerSeat': _seatAt(lastTrickWinnerGamePos!),
      if (lastTrickCards.isNotEmpty) 'lastTrickCards': cardsToJson(lastTrickCards),
      if (lastRoundContract != null) 'lastRoundContract': lastRoundContract!.name,
      if (lastRoundDelta.isNotEmpty)
        'lastRoundDelta': {for (final e in lastRoundDelta.entries) '${e.key}': e.value},
      'yourHand': cardsToJson(
        phase == RoomPhase.prikoup && iAmDeclarer ? [...me.hand, ..._dealt!.prikoup] : me.hand,
      ),
    };
  }
}
