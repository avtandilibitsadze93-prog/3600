import 'dart:async';
import 'dart:convert';

import 'package:king_game_engine/king_game_engine.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'user_registry.dart';

enum RoomPhase { declaring, prikoup, trick, gameOver }

enum _Mode { active, disconnectedGrace, bot }

class _Seat {
  final String username;
  final String avatarId;
  WebSocketChannel? channel;
  _Mode mode = _Mode.active;
  Timer? graceTimer;

  _Seat(this.username, this.avatarId, this.channel);
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
  final Duration trickCompleteDelay;
  final Duration turnTimeLimit;
  final Duration timeBankTotal;
  final List<_Seat> seats;
  final void Function(String roomId)? onFinished;

  late final GameEngine game;
  RoundEngine? round;
  DealtHands? _dealt;
  Trick? currentTrick;

  RoomPhase phase = RoomPhase.declaring;
  int _turnGamePos = 0;

  // True from the instant a trick's 3rd card lands until
  // trickCompleteDelay has elapsed and the next trick actually starts —
  // guards against a stray 'play' (a double-tap racing the server) or
  // _maybeRunBotTurn looping back before that reset happens, either of
  // which would try to add a 4th play to an already-complete Trick.
  bool _awaitingNextTrick = false;

  int? lastTrickWinnerGamePos;
  List<PlayingCard> lastTrickCards = [];
  Map<int, int> lastRoundDelta = {};
  ContractType? lastRoundContract;

  // --- move clock -------------------------------------------------------
  //
  // Each seat gets turnTimeLimit (20s) to act on their own turn before
  // dipping into their timeBankTotal (90s) — a single shared budget that
  // persists across the whole game, not refilled per turn. If a seat's
  // bank ever hits zero mid-turn, they're permanently handed to the bot
  // for the rest of the match (same mechanism a disconnect uses, just
  // never banned — being slow isn't the same as leaving).
  //
  // Only one seat's turn clock ever runs at a time, matching _turnGamePos
  // itself being a single value — _armedForSeat tracks which one.
  final List<Duration> _timeBankRemaining;
  int? _armedForSeat;
  Timer? _turnTimer;
  Timer? _bankTimer;
  DateTime? _turnDeadline;
  DateTime? _bankDeadline;
  DateTime? _bankPhaseStartedAt;

  Room({
    required this.id,
    required List<String> usernames,
    required List<String> avatarIds,
    required List<WebSocketChannel> channels,
    required this.registry,
    this.disconnectGrace = const Duration(seconds: 30),
    this.trickCompleteDelay = const Duration(seconds: 2),
    this.turnTimeLimit = const Duration(seconds: 20),
    this.timeBankTotal = const Duration(seconds: 90),
    this.onFinished,
  })  : seats = [for (var i = 0; i < 3; i++) _Seat(usernames[i], avatarIds[i], channels[i])],
        _timeBankRemaining = List.filled(3, timeBankTotal) {
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
    _startNewTurn();
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
          _startNewTurn();
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
          // Not awaited: a completed trick's trickCompleteDelay pause
          // happens inside _playCard itself, and the dispatch loop must
          // stay free to keep handling other seats' messages (a leave,
          // a reconnect) while that plays out. _playCard has its own
          // try/catch (see below) since this outer one can't observe
          // errors from a fire-and-forget async call.
          unawaited(_playCard(seat, cardFromJson(msg['card'] as Map<String, dynamic>)));
          break;

        case 'leave':
          _convertToBot(seat, banned: true);
          break;

        default:
          _sendError(seat, 'Unknown message: ${msg['type']}');
      }
    } on IllegalMoveException catch (e) {
      _sendError(seat, e.message);
    } on StateError catch (e) {
      _sendError(seat, e.message);
    } catch (e) {
      _sendError(seat, 'Error: $e');
    }
  }

  void _requireTurn(int seat, RoomPhase expectedPhase) {
    if (phase != expectedPhase) {
      throw StateError('This action is not possible right now');
    }
    final turnSeat =
        expectedPhase == RoomPhase.prikoup ? _seatAt(game.currentDeclarerIndex) : _seatAt(_turnGamePos);
    if (seat != turnSeat) {
      throw StateError("It's not your turn right now");
    }
  }

  void _startNextTrick() {
    currentTrick = Trick();
    _turnGamePos = round!.currentLeaderIndex;
    phase = RoomPhase.trick;
    _awaitingNextTrick = false;
    _startNewTurn();
    _broadcastAll();
    _maybeRunBotTurn();
  }

  // Fire-and-forget (see call sites): an async function's exceptions are
  // always captured into its own Future's error state rather than thrown
  // synchronously to the caller, so _dispatch's try/catch can no longer
  // catch anything this throws — e.g. a stale/duplicate 'play' racing in
  // right as a trick resolves. Handle errors here instead, the same way
  // _dispatch used to, so the offending client gets a graceful rejection
  // instead of an unhandled Future error.
  Future<void> _playCard(int seat, PlayingCard card) async {
    try {
      if (_awaitingNextTrick) return;

      final player = game.players[_turnGamePos];
      round!.playCard(player, currentTrick!, card);

      if (!currentTrick!.isComplete) {
        _turnGamePos = (_turnGamePos + 1) % 3;
        _startNewTurn();
        _broadcastAll();
        _maybeRunBotTurn();
        return;
      }

      lastTrickWinnerGamePos = round!.resolveTrick(currentTrick!);
      lastTrickCards = currentTrick!.allCards;

      // Broadcast the completed trick — all 3 cards, still down on the
      // table — before doing anything else, and hold it there a moment so
      // every player actually sees what was played and who won it,
      // instead of the pile jumping straight to empty for the next trick.
      // No one's turn during this pause, so the move clock is disarmed
      // too (_currentTurnSeat() reads _awaitingNextTrick).
      _awaitingNextTrick = true;
      _startNewTurn();
      _broadcastAll();
      await Future.delayed(trickCompleteDelay);

      if (!round!.roundIsOver) {
        _startNextTrick();
        return;
      }

      lastRoundDelta = round!.computeRoundScore();
      lastRoundContract = round!.declaration.type;
      game.finishRound(round!);
      _awaitingNextTrick = false;

      if (game.isGameOver) {
        phase = RoomPhase.gameOver;
        _startNewTurn();
        _broadcastAll();
        onFinished?.call(id);
      } else {
        _dealNewRound();
      }
    } on IllegalMoveException catch (e) {
      _sendError(seat, e.message);
    } on StateError catch (e) {
      _sendError(seat, e.message);
    }
  }

  // --- move clock --------------------------------------------------------

  int? _currentTurnSeat() {
    switch (phase) {
      case RoomPhase.declaring:
        return _seatAt(_turnGamePos);
      case RoomPhase.prikoup:
        return _seatAt(game.currentDeclarerIndex);
      case RoomPhase.trick:
        return _awaitingNextTrick ? null : _seatAt(_turnGamePos);
      case RoomPhase.gameOver:
        return null;
    }
  }

  void _disarmTimer() {
    _turnTimer?.cancel();
    _bankTimer?.cancel();
    _turnTimer = null;
    _bankTimer = null;
    final seat = _armedForSeat;
    final bankStart = _bankPhaseStartedAt;
    if (seat != null && bankStart != null) {
      final elapsed = DateTime.now().difference(bankStart);
      final remaining = _timeBankRemaining[seat] - elapsed;
      _timeBankRemaining[seat] = remaining.isNegative ? Duration.zero : remaining;
    }
    _armedForSeat = null;
    _turnDeadline = null;
    _bankDeadline = null;
    _bankPhaseStartedAt = null;
  }

  /// Called at every point "whose move is it" actually changes — a fresh
  /// declare, bury, or trick-card turn, or no one's turn at all (mid
  /// trick-complete pause, game over). Always resets the clock, even
  /// when the same seat gets two turns in a row (a declarer immediately
  /// buries too) — each is its own decision and earns its own
  /// turnTimeLimit, not a continuation of the last one.
  void _startNewTurn() {
    _disarmTimer();
    final seat = _currentTurnSeat();
    if (seat == null || seats[seat].mode != _Mode.active) return;
    _armedForSeat = seat;
    _turnDeadline = DateTime.now().add(turnTimeLimit);
    _turnTimer = Timer(turnTimeLimit, () => _onTurnTimeExpired(seat));
  }

  void _onTurnTimeExpired(int seat) {
    if (_armedForSeat != seat) return; // stale timer from a turn that already moved on
    _turnTimer = null;
    final remaining = _timeBankRemaining[seat];
    if (remaining <= Duration.zero) {
      _armedForSeat = null;
      _turnDeadline = null;
      _convertToBot(seat, banned: false);
      return;
    }
    _bankPhaseStartedAt = DateTime.now();
    _bankDeadline = _bankPhaseStartedAt!.add(remaining);
    _bankTimer = Timer(remaining, () => _onBankTimeExpired(seat));
    _broadcastAll();
  }

  void _onBankTimeExpired(int seat) {
    if (_armedForSeat != seat) return; // stale timer from a turn that already moved on
    _timeBankRemaining[seat] = Duration.zero;
    _armedForSeat = null;
    _bankTimer = null;
    _bankDeadline = null;
    _bankPhaseStartedAt = null;
    // Same mechanism a disconnect uses, just never banned — running out
    // of time isn't the same as leaving, and the whole-game bank is
    // already the harsher consequence: this seat is bot-controlled for
    // the rest of the match, not just this one decision.
    _convertToBot(seat, banned: false);
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
    // Only drop the channel for a real disconnect or an explicit leave
    // (the only two callers that pass banned: true) — a seat converted
    // to a bot purely for running out of move-clock time may still have
    // a perfectly live socket, and should keep watching the rest of the
    // match play out instead of going dark.
    if (banned) s.channel = null;
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
          // A completed trick is sitting on the table for
          // trickCompleteDelay before _startNextTrick() resets it and
          // calls back in here itself — nothing to do until then.
          if (_awaitingNextTrick) return;
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
    _startNewTurn();
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
    final seat = _seatAt(_turnGamePos);
    final player = game.players[_turnGamePos];
    final legal = round!.legalMoves(player, currentTrick!);
    unawaited(_playCard(seat, legal.first));
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
          {
            'seat': i,
            'name': seats[i].username,
            'avatarId': seats[i].avatarId,
            'connected': seats[i].mode != _Mode.bot,
          },
      ],
      'standings': {for (final p in game.players) '${p.id}': p.totalScore},
      // Score sheet: each player's completed fixed-contract/plus rounds
      // so far, for the ცხრილი (score table) view — purely a display
      // concern, never consulted for scoring itself.
      'scoreTable': {
        for (final p in game.players)
          '${p.id}': {
            'fixed': {for (final e in p.fixedContractResults.entries) e.key.name: e.value},
            'plus': p.plusResults,
          },
      },
      'declarerSeat': _seatAt(game.currentDeclarerIndex),
      if (round != null) 'contract': round!.declaration.type.name,
      if (round?.declaration.trumpSuit != null) 'trumpSuit': round!.declaration.trumpSuit!.name,
      if (phase == RoomPhase.declaring)
        'legalDeclarations': [
          for (final t in game.legalDeclarationTypes(game.currentDeclarerIndex)) t.name,
        ],
      // Omitted (rather than still naming the player who just played the
      // trick's 3rd card) while _awaitingNextTrick — no one's turn while
      // the completed trick sits on the table, and a client naively
      // reacting to "phase is still trick, turnSeat is still mine" would
      // otherwise try to play again into an already-complete Trick.
      if (phase == RoomPhase.trick && !_awaitingNextTrick) 'turnSeat': _seatAt(_turnGamePos),
      if (phase == RoomPhase.trick && currentTrick != null)
        'trick': [
          for (final p in currentTrick!.plays) {'seat': p.playerId, 'card': cardToJson(p.card)},
        ],
      if (lastTrickWinnerGamePos != null) 'lastTrickWinnerSeat': _seatAt(lastTrickWinnerGamePos!),
      if (lastTrickCards.isNotEmpty) 'lastTrickCards': cardsToJson(lastTrickCards),
      // Move clock: which seat (if any) currently has a live 20s/time-bank
      // countdown running, and the deadline(s) — always the same 3 values
      // in every seat's own snapshot, so opponents' clocks render too.
      // bankDeadlineMs only appears once the base 20s has run out and the
      // shared, whole-game time bank has taken over.
      if (_armedForSeat != null) 'timedSeat': _armedForSeat,
      if (_turnDeadline != null) 'turnDeadlineMs': _turnDeadline!.millisecondsSinceEpoch,
      if (_bankDeadline != null) 'bankDeadlineMs': _bankDeadline!.millisecondsSinceEpoch,
      if (lastRoundContract != null) 'lastRoundContract': lastRoundContract!.name,
      if (lastRoundDelta.isNotEmpty)
        'lastRoundDelta': {for (final e in lastRoundDelta.entries) '${e.key}': e.value},
      'yourHand': cardsToJson(
        phase == RoomPhase.prikoup && iAmDeclarer ? [...me.hand, ..._dealt!.prikoup] : me.hand,
      ),
    };
  }
}
