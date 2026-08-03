import 'card.dart';
import 'contract.dart';

const List<ContractType> _allFixedContracts = [
  ContractType.king,
  ContractType.queen,
  ContractType.jack,
  ContractType.noTricks,
  ContractType.noHearts,
  ContractType.lastTwo,
];

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

  /// Running total across the whole 27-round game.
  int totalScore;

  /// This player's own fixed ("minus") contracts not yet declared. Each
  /// player declares each of these 6 exactly once, in whatever order
  /// they like — this list simply shrinks as they do.
  List<ContractType> remainingFixedContracts;

  /// How many of this player's 3 "plus" turns (trump — a named suit or
  /// "ბეზი") have been used. Unlike the fixed contracts, there's no
  /// uniqueness constraint here — the same suit or "ბეზი" may be
  /// declared all 3 times.
  int plusDeclaredCount;

  /// Whether every one of this player's fixed-contract rounds so far has
  /// come out perfectly clean (their own delta was 0 each time — see
  /// [GameEngine.finishRound]). Backs the "პრემია" (+40) bonus, which is
  /// a whole-game achievement: it's only ever awarded once, right after
  /// this player's 6th and final fixed contract, and only if none of
  /// the 6 ever failed — never per round.
  bool cleanFixedContractsSoFar;

  /// This player's completed fixed-contract rounds, keyed by contract
  /// type, with the exact point delta each one contributed to
  /// [totalScore] (including the "პრემია" bonus, credited to whichever
  /// round completed the clean streak). Absent key = not yet declared.
  /// Purely a display/history concern — the score sheet shown to
  /// players — the engine's own scoring logic never reads this back.
  Map<ContractType, int> fixedContractResults;

  /// This player's completed "plus" round deltas, in the order they
  /// were played (up to 3 entries). Same display-only purpose as
  /// [fixedContractResults].
  List<int> plusResults;

  Player({required this.id, required this.name})
      : hand = [],
        capturedThisRound = [],
        tricksWonThisRound = 0,
        totalScore = 0,
        remainingFixedContracts = List.of(_allFixedContracts),
        plusDeclaredCount = 0,
        cleanFixedContractsSoFar = true,
        fixedContractResults = {},
        plusResults = [];

  bool hasSuit(Suit suit) => hand.any((c) => c.suit == suit);

  /// True if every remaining card in hand is a heart (used for the
  /// "can't lead hearts until it's all you have left" rule).
  bool get onlyHeartsLeft => hand.isNotEmpty && hand.every((c) => c.isHeart);
}
