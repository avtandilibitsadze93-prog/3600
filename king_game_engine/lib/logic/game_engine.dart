import '../models/contract.dart';
import '../models/player.dart';
import 'deck.dart';
import 'round_engine.dart';

/// Runs a whole game: 3 players, 9 rounds each (their own 6 fixed
/// contracts once apiece, in whatever order they choose, plus 3 "plus"
/// turns — trump with a named suit, or "ბეზი"/no-trump — repeats
/// allowed) — 27 rounds total. Turn order rotates through the 3 players
/// every round, same as always; a player simply keeps coming back
/// around until all 9 of their own turns are used.
class GameEngine {
  final List<Player> players; // seating order [first, second, last]
  int roundsPlayed = 0;
  static const int totalRounds = 27;
  static const int maxPlusPerPlayer = 3;

  /// Index (into [players]) of whoever declares the *current* round.
  /// Round 1: seat 0 (first). Then rotates seat by seat each round.
  int currentDeclarerIndex = 0;

  GameEngine(this.players) {
    assert(players.length == 3);
  }

  bool get isGameOver => roundsPlayed >= totalRounds;

  /// Contract types [playerIndex] may legally declare right now: any of
  /// their own not-yet-played fixed contracts, plus trump/ბეზი if they
  /// still have "plus" turns left. Always non-empty while the game
  /// isn't over, since every player has exactly 9 turns and this list
  /// only shrinks once each of those 9 is actually used.
  List<ContractType> legalDeclarationTypes(int playerIndex) {
    final player = players[playerIndex];
    return [
      ...player.remainingFixedContracts,
      if (player.plusDeclaredCount < maxPlusPerPlayer) ContractType.trump,
    ];
  }

  /// Deals a fresh shuffled deck for the next round and immediately
  /// assigns each player's 10 cards (plus resets their per-round
  /// captured-cards/tricks-won state) — *before* anyone has declared
  /// anything. This matters: the declarer needs to actually see their
  /// own hand to decide what to declare, so dealing can't wait until
  /// after [startRound] validates a choice.
  DealtHands dealNextRound({int? seed}) {
    final dealt = Deck.deal(Deck.fresh(seed: seed));
    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      p.hand = List.of(dealt.hands[i]!);
      p.capturedThisRound = [];
      p.tricksWonThisRound = 0;
    }
    return dealt;
  }

  /// Starts a round with the given [declaration], chosen by whoever's
  /// turn it currently is, against hands already dealt by
  /// [dealNextRound]. Validates that the choice is still legal for
  /// *this* player (each fixed contract once per player; at most 3
  /// "plus" turns per player).
  RoundEngine startRound(Declaration declaration, DealtHands dealt) {
    if (isGameOver) {
      throw StateError('The game is already over (27 rounds played)');
    }
    final declarer = players[currentDeclarerIndex];

    if (declaration.type == ContractType.trump) {
      if (declarer.plusDeclaredCount >= maxPlusPerPlayer) {
        throw StateError('${declarer.name} has already used all 3 of their "plus" turns');
      }
    } else {
      if (!declarer.remainingFixedContracts.contains(declaration.type)) {
        throw StateError('${declarer.name} has already declared ${declaration.type.englishName} this game');
      }
    }

    return RoundEngine(
      players: players,
      declaration: declaration,
      declarerIndex: currentDeclarerIndex,
    );
  }

  /// Call after a round's 10 tricks are complete to apply its score and
  /// advance to the next round's declarer.
  void finishRound(RoundEngine engine) {
    final scores = engine.computeRoundScore();
    for (final p in players) {
      p.totalScore += scores[p.id] ?? 0;
    }

    final declarer = players[engine.declarerIndex];
    final declarerDelta = scores[declarer.id] ?? 0;
    if (engine.declaration.type == ContractType.trump) {
      declarer.plusDeclaredCount += 1;
      declarer.plusResults.add(declarerDelta);
    } else {
      declarer.remainingFixedContracts.remove(engine.declaration.type);

      // "პრემია" (+40): a whole-game bonus, not a per-round one. It's
      // only ever credited once, right after this player's 6th and
      // final fixed contract finishes, and only if the declarer's own
      // delta was 0 (perfectly clean) on every single one of their 6 —
      // one failure anywhere among the 6 rules it out for good.
      if (declarerDelta != 0) {
        declarer.cleanFixedContractsSoFar = false;
      }
      var recordedDelta = declarerDelta;
      if (declarer.remainingFixedContracts.isEmpty && declarer.cleanFixedContractsSoFar) {
        declarer.totalScore += 40;
        recordedDelta += 40;
      }
      declarer.fixedContractResults[engine.declaration.type] = recordedDelta;
    }

    roundsPlayed += 1;
    currentDeclarerIndex = (currentDeclarerIndex + 1) % players.length;
  }

  Map<String, int> get standings => {
        for (final p in players) p.name: p.totalScore,
      };
}
