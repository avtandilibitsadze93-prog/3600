import 'package:flutter/foundation.dart';
import 'package:king_game_engine/king_game_engine.dart';

enum GamePhase {
  playersSetup,
  seatingReveal,
  deviceHandoff,
  declaring,
  prikoup,
  trick,
  trickResolved,
  roundSummary,
  gameOver,
}

enum _AfterHandoff { declaring, trick }

/// Drives the whole pass-and-play flow: one shared device handed between
/// 3 local players, gated by a "give the phone to X" screen before every
/// turn so nobody sees a hand that isn't theirs. Wraps [GameEngine] /
/// [RoundEngine] (the pure rules engine) and exposes just what the
/// screens need, notifying listeners on every state change.
class GameController extends ChangeNotifier {
  GamePhase phase = GamePhase.playersSetup;

  late GameEngine game;
  RoundEngine? round;
  DealtHands? _dealt;
  Trick? currentTrick;

  int activePlayerIndex = 0;
  _AfterHandoff _afterHandoff = _AfterHandoff.declaring;

  int? lastTrickWinnerIndex;
  List<PlayingCard> lastTrickCards = [];

  Map<int, int> lastRoundDelta = {};
  ContractType? lastRoundContract;

  List<Player> get players => game.players;
  Player get activePlayer => players[activePlayerIndex];
  int get roundNumber => game.roundsPlayed + 1;
  Map<String, int> get standings => game.standings;

  void setupPlayers(List<String> names) {
    final entered = [
      for (var i = 0; i < 3; i++) Player(id: i, name: names[i]),
    ];
    final seating = determineSeatingByAceDraw([0, 1, 2]);
    game = GameEngine([for (final i in seating) entered[i]]);
    phase = GamePhase.seatingReveal;
    notifyListeners();
  }

  void confirmSeating() => _dealNewRound();

  void _dealNewRound() {
    _dealt = game.dealNextRound();
    activePlayerIndex = game.currentDeclarerIndex;
    _afterHandoff = _AfterHandoff.declaring;
    phase = GamePhase.deviceHandoff;
    notifyListeners();
  }

  void confirmHandoff() {
    phase = _afterHandoff == _AfterHandoff.declaring
        ? GamePhase.declaring
        : GamePhase.trick;
    notifyListeners();
  }

  List<ContractType> get legalDeclarations =>
      game.legalDeclarationTypes(activePlayerIndex);

  void declare(ContractType type, {Suit? trumpSuit}) {
    round = game.startRound(Declaration(type, trumpSuit: trumpSuit), _dealt!);
    phase = GamePhase.prikoup;
    notifyListeners();
  }

  List<PlayingCard> get prikoupPreviewHand =>
      [...activePlayer.hand, ..._dealt!.prikoup];

  bool isBurialForbidden(PlayingCard card) => round!.isBurialForbidden(card);

  void buryAndStartTricks(List<PlayingCard> toBury) {
    round!.exchangePrikoup(_dealt!.prikoup, toBury);
    _startNextTrick();
  }

  void _startNextTrick() {
    currentTrick = Trick();
    activePlayerIndex = round!.currentLeaderIndex;
    _afterHandoff = _AfterHandoff.trick;
    phase = GamePhase.deviceHandoff;
    notifyListeners();
  }

  List<PlayingCard> get legalMovesForActivePlayer =>
      round!.legalMoves(activePlayer, currentTrick!);

  void playCard(PlayingCard card) {
    round!.playCard(activePlayer, currentTrick!, card);
    if (currentTrick!.isComplete) {
      lastTrickWinnerIndex = round!.resolveTrick(currentTrick!);
      lastTrickCards = currentTrick!.allCards;
      phase = GamePhase.trickResolved;
    } else {
      activePlayerIndex = (activePlayerIndex + 1) % 3;
      _afterHandoff = _AfterHandoff.trick;
      phase = GamePhase.deviceHandoff;
    }
    notifyListeners();
  }

  void continueAfterTrick() {
    if (round!.roundIsOver) {
      lastRoundDelta = round!.computeRoundScore();
      lastRoundContract = round!.declaration.type;
      game.finishRound(round!);
      phase = GamePhase.roundSummary;
      notifyListeners();
    } else {
      _startNextTrick();
    }
  }

  void continueAfterRoundSummary() {
    if (game.isGameOver) {
      phase = GamePhase.gameOver;
      notifyListeners();
    } else {
      _dealNewRound();
    }
  }
}
