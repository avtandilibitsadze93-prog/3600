import 'card.dart';

class Player {
  final int id;
  final String name;
  List<PlayingCard> hand;

  /// All cards this player has physically won in tricks across the
  /// current round (used to compute that round's score at the end).
  List<PlayingCard> capturedThisRound;

  /// Number of tricks won this round (needed for trump-round scoring
  /// and for detecting the "last two tricks" of the round).
  int tricksWonThisRound;

  /// Running total across the whole 9-round game.
  int totalScore;

  /// Which contracts this player has already declared (each fixed
  /// contract can only ever be declared once per game; trump can only
  /// be declared once *by this player*, though it happens 3 times overall).
  bool hasDeclaredTrump;

  /// How many of this player's 3 turns have been spent on a fixed
  /// contract. Capped at 2 (see [GameEngine.maxFixedDeclarationsPerPlayer])
  /// since a player has exactly 3 turns and must spend exactly one of
  /// them on trump.
  int fixedContractsDeclaredCount;

  Player({required this.id, required this.name})
      : hand = [],
        capturedThisRound = [],
        tricksWonThisRound = 0,
        totalScore = 0,
        hasDeclaredTrump = false,
        fixedContractsDeclaredCount = 0;

  bool hasSuit(Suit suit) => hand.any((c) => c.suit == suit);

  /// True if every remaining card in hand is a heart (used for the
  /// "can't lead hearts until it's all you have left" rule).
  bool get onlyHeartsLeft => hand.isNotEmpty && hand.every((c) => c.isHeart);
}
