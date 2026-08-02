import '../models/contract.dart';
import '../models/player.dart';
import 'deck.dart';
import 'round_engine.dart';

/// Orchestrates the full 9-round game: seating order, dealer/declarer
/// rotation, which fixed contracts remain available, and running totals.
class GameEngine {
  final List<Player> players; // seating order [first, second, last]
  final List<ContractType> remainingFixedContracts = [
    ContractType.king,
    ContractType.queen,
    ContractType.jack,
    ContractType.noTricks,
    ContractType.noHearts,
    ContractType.lastTwo,
  ];

  int roundsPlayed = 0;
  static const int totalRounds = 9;

  /// Each player gets exactly 3 turns across the game and must spend
  /// exactly one of them on trump, so at most 2 can go to fixed
  /// contracts. Without this cap, one player could hog more than their
  /// fair share of the shared 6-contract fixed pool, leaving another
  /// player (who already used trump) with zero legal declarations on a
  /// later turn.
  static const int maxFixedDeclarationsPerPlayer = 2;

  /// Index (into [players]) of whoever declares the *current* round.
  /// Round 1: seat 0 (first). Then rotates seat by seat each round.
  int currentDeclarerIndex = 0;

  GameEngine(this.players) {
    assert(players.length == 3);
  }

  bool get isGameOver => roundsPlayed >= totalRounds;

  /// The contract types [playerIndex] may legally declare right now.
  /// Always non-empty while the game isn't over: a player who has hit
  /// the fixed-contract cap and hasn't used trump yet can only pick
  /// trump; a player who has already used trump can only pick from
  /// whatever's left in the shared fixed pool (guaranteed non-empty by
  /// the cap above).
  List<ContractType> legalDeclarationTypes(int playerIndex) {
    final player = players[playerIndex];
    final canDeclareFixed =
        player.fixedContractsDeclaredCount < maxFixedDeclarationsPerPlayer;
    return [
      if (canDeclareFixed) ...remainingFixedContracts,
      if (!player.hasDeclaredTrump) ContractType.trump,
    ];
  }

  /// Deals a fresh shuffled deck for the next round.
  DealtHands dealNextRound({int? seed}) {
    final deck = Deck.fresh(seed: seed);
    return Deck.deal(deck);
  }

  /// Starts a round with the given [declaration], chosen by whoever's
  /// turn it currently is. Validates that the choice is still legal
  /// (fixed contracts can only be used once per game; trump only once
  /// per player).
  RoundEngine startRound(Declaration declaration, DealtHands dealt) {
    if (isGameOver) {
      throw StateError('თამაში უკვე დასრულებულია (9 რაუნდი გათამაშდა)');
    }
    final declarer = players[currentDeclarerIndex];

    if (declaration.type == ContractType.trump) {
      if (declarer.hasDeclaredTrump) {
        throw StateError('${declarer.name}-მ უკვე გამოაცხადა კოზირი ამ თამაშში');
      }
    } else {
      if (!remainingFixedContracts.contains(declaration.type)) {
        throw StateError('${declaration.type.georgianName} უკვე ითამაშა ამ თამაშში');
      }
      if (declarer.fixedContractsDeclaredCount >=
          maxFixedDeclarationsPerPlayer) {
        throw StateError(
            '${declarer.name}-ს უკვე გამოცხადებული აქვს $maxFixedDeclarationsPerPlayer '
            'ფიქსირებული კონტრაქტი — ეს ხელი კოზირი უნდა იყოს');
      }
    }

    // Reset per-round player state and deal hands.
    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      p.hand = List.of(dealt.hands[i]!);
      p.capturedThisRound = [];
      p.tricksWonThisRound = 0;
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

    if (engine.declaration.type == ContractType.trump) {
      players[engine.declarerIndex].hasDeclaredTrump = true;
    } else {
      remainingFixedContracts.remove(engine.declaration.type);
      players[engine.declarerIndex].fixedContractsDeclaredCount += 1;
    }

    roundsPlayed += 1;
    currentDeclarerIndex = (currentDeclarerIndex + 1) % players.length;
  }

  Map<String, int> get standings => {
        for (final p in players) p.name: p.totalScore,
      };
}
