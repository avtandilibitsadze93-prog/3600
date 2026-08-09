import '../models/card.dart';
import '../models/contract.dart';
import '../models/player.dart';
import '../models/trick.dart';
import 'legality.dart' as legality;

class IllegalMoveException implements Exception {
  final String message;
  IllegalMoveException(this.message);
  @override
  String toString() => 'IllegalMoveException: $message';
}

/// Runs a single round (one of the 27 in a game): prikoup exchange,
/// all 10 tricks, and the round's scoring.
class RoundEngine {
  final List<Player> players; // length 3, index = seat order
  final Declaration declaration;
  final int declarerIndex;

  /// Whether a heart has been *led* yet this round (only relevant for
  /// bookkeeping/UI; the leading restriction itself is per-player, see
  /// [legalLeads]).
  bool heartHasBeenLed = false;

  int currentLeaderIndex;
  int trickNumber = 0; // 1-indexed once tricks start being played
  final List<Trick> completedTricks = [];

  RoundEngine({
    required this.players,
    required this.declaration,
    required this.declarerIndex,
  }) : currentLeaderIndex = declarerIndex;

  Suit? get trumpSuit =>
      declaration.type == ContractType.trump ? declaration.trumpSuit : null;

  /// Whether [card] may not be buried in the prikoup this round (the
  /// declarer must keep and eventually play it instead).
  bool isBurialForbidden(PlayingCard card) =>
      legality.isBurialForbidden(declaration.type, card);

  /// Step 1: declarer takes the 2-card prikoup into hand (now holds 12),
  /// then buries 2 cards face-down, subject to the burial restrictions.
  /// The buried cards are removed from the game entirely.
  void exchangePrikoup(List<PlayingCard> prikoup, List<PlayingCard> toBury) {
    if (toBury.length != 2) {
      throw IllegalMoveException('Exactly 2 cards must be buried');
    }
    final declarer = players[declarerIndex];
    declarer.hand.addAll(prikoup);

    for (final card in toBury) {
      if (!declarer.hand.contains(card)) {
        throw IllegalMoveException('This card is not in hand: $card');
      }
      if (isBurialForbidden(card)) {
        throw IllegalMoveException('This card cannot be buried this round: $card');
      }
    }
    for (final card in toBury) {
      declarer.hand.remove(card);
    }
    // toBury cards are simply discarded — they take no further part.
    assert(declarer.hand.length == 10);
  }

  /// Cards [player] is legally allowed to play right now, given the
  /// in-progress [trick] (empty trick means this player is leading).
  List<PlayingCard> legalMoves(Player player, Trick trick) => legality.legalMoves(
        hand: player.hand,
        alreadyPlayedThisTrick: trick.allCards,
        contract: declaration.type,
      );

  /// Validates and applies a single card play into the current [trick].
  void playCard(Player player, Trick trick, PlayingCard card) {
    final legal = legalMoves(player, trick);
    if (!legal.contains(card)) {
      throw IllegalMoveException('${player.name} cannot play $card right now');
    }
    player.hand.remove(card);
    trick.addPlay(player.id, card);
    if (trick.plays.length == 1 && card.isHeart) {
      heartHasBeenLed = true;
    }
  }

  /// Resolves a completed trick: finds the winner, gives them the cards,
  /// and sets them as the next leader. Returns the winner's seat index.
  int resolveTrick(Trick trick) {
    final winnerId = trick.winner(trumpSuit: trumpSuit);
    final winnerIndex = players.indexWhere((p) => p.id == winnerId);
    final winner = players[winnerIndex];
    winner.capturedThisRound.addAll(trick.allCards);
    winner.tricksWonThisRound += 1;
    completedTricks.add(trick);
    trickNumber += 1;
    currentLeaderIndex = winnerIndex;
    return winnerIndex;
  }

  /// A round ends either when all 10 tricks are played, or — for
  /// king/queen/jack/noHearts — as soon as every penalty-relevant card
  /// has already been captured by someone, since no further play can
  /// change that contract's score at that point. noTricks, lastTwo and
  /// trump/"+" all depend on the full distribution of tricks won right
  /// up to the last one, so those always play out completely.
  bool get roundIsOver => completedTricks.length == 10 || _isDecidedEarly;

  bool get _isDecidedEarly {
    switch (declaration.type) {
      case ContractType.king:
        return players.any((p) => p.capturedThisRound.any((c) => c.isKingOfHearts));
      case ContractType.queen:
        return _totalCaptured((c) => c.isQueen) == 4;
      case ContractType.jack:
        return _totalCaptured((c) => c.isJack) == 4;
      case ContractType.noHearts:
        return _totalCaptured((c) => c.isHeart) == 8;
      case ContractType.noTricks:
      case ContractType.lastTwo:
      case ContractType.trump:
        return false;
    }
  }

  int _totalCaptured(bool Function(PlayingCard) test) =>
      players.fold(0, (sum, p) => sum + p.capturedThisRound.where(test).length);

  bool isLastTwoTrick(int oneIndexedTrickNumber) =>
      oneIndexedTrickNumber == 9 || oneIndexedTrickNumber == 10;

  /// Computes this round's score delta per player (playerId -> points,
  /// negative for fixed contracts, positive for trump).
  Map<int, int> computeRoundScore() {
    final scores = <int, int>{for (final p in players) p.id: 0};

    switch (declaration.type) {
      case ContractType.king:
        for (final p in players) {
          if (p.capturedThisRound.any((c) => c.isKingOfHearts)) {
            scores[p.id] = scores[p.id]! - 40;
          }
        }
        break;

      case ContractType.queen:
        for (final p in players) {
          final queensTaken = p.capturedThisRound.where((c) => c.isQueen).length;
          scores[p.id] = scores[p.id]! - 10 * queensTaken;
        }
        break;

      case ContractType.jack:
        for (final p in players) {
          final jacksTaken = p.capturedThisRound.where((c) => c.isJack).length;
          scores[p.id] = scores[p.id]! - 10 * jacksTaken;
        }
        break;

      case ContractType.noTricks:
        for (final p in players) {
          scores[p.id] = scores[p.id]! - 4 * p.tricksWonThisRound;
        }
        break;

      case ContractType.noHearts:
        for (final p in players) {
          final heartsTaken = p.capturedThisRound.where((c) => c.isHeart).length;
          scores[p.id] = scores[p.id]! - 5 * heartsTaken;
        }
        break;

      case ContractType.lastTwo:
        for (var i = 0; i < completedTricks.length; i++) {
          final trickNo = i + 1;
          if (isLastTwoTrick(trickNo)) {
            final winnerId = completedTricks[i].winner(trumpSuit: trumpSuit);
            scores[winnerId] = scores[winnerId]! - 20;
          }
        }
        break;

      case ContractType.trump:
        for (final p in players) {
          scores[p.id] = scores[p.id]! + 8 * p.tricksWonThisRound;
        }
        break;
    }

    // NOTE: the "პრემია" (+40) bonus is intentionally NOT computed here.
    // It isn't a per-round bonus at all — it's a whole-game achievement
    // (perfectly clean across all 6 of a player's fixed contracts), so
    // it's tracked and credited in GameEngine.finishRound instead, which
    // is the only place that knows about a player's full history.

    return scores;
  }
}
