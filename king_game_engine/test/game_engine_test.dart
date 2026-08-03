// Focused unit tests for GameEngine's 27-round structure and the
// whole-game "პრემია" (+40) bonus, which is easy to get subtly wrong:
// it must never be paid out per-round, only once, after a player's 6th
// and final fixed contract, and only if none of those 6 ever failed.

import 'package:king_game_engine/king_game_engine.dart';
import 'package:test/test.dart';

List<Player> _freshPlayers() => [
      Player(id: 0, name: 'ავთო'),
      Player(id: 1, name: 'ვასო'),
      Player(id: 2, name: 'გიორგი'),
    ];

void main() {
  group('GameEngine (27-round structure)', () {
    test('runs exactly 27 rounds total: 9 per player (6 fixed + 3 plus)', () {
      final players = _freshPlayers();
      final game = GameEngine(players);
      var rounds = 0;

      while (!game.isGameOver) {
        final declarerIdx = game.currentDeclarerIndex;
        final options = game.legalDeclarationTypes(declarerIdx);
        expect(options, isNotEmpty, reason: 'a player with turns left must always have a legal choice');
        final type = options.first;
        final declaration = type == ContractType.trump
            ? const Declaration(ContractType.trump, trumpSuit: Suit.clubs)
            : Declaration(type);

        final dealt = game.dealNextRound(seed: rounds);
        final round = game.startRound(declaration, dealt);
        game.finishRound(round);
        rounds++;
        expect(rounds, lessThanOrEqualTo(27), reason: 'must not run past 27 rounds');
      }

      expect(rounds, 27);
      for (final p in players) {
        expect(p.remainingFixedContracts, isEmpty, reason: '${p.name} must have declared all 6 fixed contracts');
        expect(p.plusDeclaredCount, 3, reason: '${p.name} must have used all 3 plus turns');

        // The score-sheet history (fixedContractResults/plusResults) is
        // declarer-centric — one entry per round *this player declared*
        // — so it must have exactly one entry per turn regardless of
        // what everyone else scored that round. It deliberately does
        // NOT have to sum to totalScore: fixed/plus rounds can also
        // move points for the other 2 players (e.g. whoever else
        // captures a penalty card, or wins tricks in a plus round), and
        // those swings only ever show up in the OTHER player's own
        // totalScore, never in this player's declared-round history.
        expect(p.fixedContractResults, hasLength(6));
        expect(p.plusResults, hasLength(3));
      }
    });

    test('a player may repeat the same suit (or ბეზი) across all 3 plus turns', () {
      final players = _freshPlayers();
      final game = GameEngine(players);

      // Burn through player 0's 6 fixed contracts first (players 1/2
      // just take whatever's legal for them each turn) so player 0's
      // next 3 turns are all "plus" turns.
      var seed = 0;
      while (players[0].remainingFixedContracts.isNotEmpty) {
        final declarerIdx = game.currentDeclarerIndex;
        final type = declarerIdx == 0
            ? game.legalDeclarationTypes(0).firstWhere((t) => t != ContractType.trump)
            : game.legalDeclarationTypes(declarerIdx).first;
        final declaration = type == ContractType.trump
            ? const Declaration(ContractType.trump, trumpSuit: Suit.spades)
            : Declaration(type);
        final round = game.startRound(declaration, game.dealNextRound(seed: seed++));
        game.finishRound(round);
      }

      // Now declare clubs as trump all 3 times running for player 0 —
      // no uniqueness constraint on the "plus" declarations at all.
      for (var i = 0; i < 3; i++) {
        while (game.currentDeclarerIndex != 0) {
          final declarerIdx = game.currentDeclarerIndex;
          final type = game.legalDeclarationTypes(declarerIdx).first;
          final declaration = type == ContractType.trump
              ? const Declaration(ContractType.trump, trumpSuit: Suit.spades)
              : Declaration(type);
          final round = game.startRound(declaration, game.dealNextRound(seed: seed++));
          game.finishRound(round);
        }
        expect(game.legalDeclarationTypes(0), contains(ContractType.trump));
        final round = game.startRound(
          const Declaration(ContractType.trump, trumpSuit: Suit.clubs),
          game.dealNextRound(seed: seed++),
        );
        game.finishRound(round);
      }

      expect(players[0].plusDeclaredCount, 3);
    });

    test('"ბეზი" (no-trump) is accepted as a trump declaration with a null trumpSuit, '
        'and resolves tricks by highest card of the led suit', () {
      final players = _freshPlayers();
      final game = GameEngine(players);
      final round = game.startRound(const Declaration(ContractType.trump), game.dealNextRound(seed: 1));
      expect(round.trumpSuit, isNull);

      final trick = Trick()
        ..addPlay(0, const PlayingCard(Suit.clubs, Rank.seven))
        ..addPlay(1, const PlayingCard(Suit.hearts, Rank.ace)) // off-suit, can't win
        ..addPlay(2, const PlayingCard(Suit.clubs, Rank.king));
      expect(trick.winner(trumpSuit: round.trumpSuit), 2);
    });

    test('the +40 "პრემია" bonus is awarded exactly once, right after a player\'s '
        '6th and final fixed contract, when all 6 came out perfectly clean', () {
      final players = _freshPlayers();
      final game = GameEngine(players);

      // Player 0 declares all 6 fixed contracts back to back (players
      // 1/2 fill their own turns with trump in between). Nobody ever
      // plays a card, so nobody ever captures anything — every one of
      // player 0's 6 fixed rounds comes out perfectly clean by
      // construction (0 delta each time).
      var seed = 0;
      while (players[0].remainingFixedContracts.isNotEmpty) {
        final declarerIdx = game.currentDeclarerIndex;
        final type = declarerIdx == 0
            ? game.legalDeclarationTypes(0).firstWhere((t) => t != ContractType.trump)
            : game.legalDeclarationTypes(declarerIdx).first;
        final declaration = type == ContractType.trump
            ? const Declaration(ContractType.trump, trumpSuit: Suit.clubs)
            : Declaration(type);
        final round = game.startRound(declaration, game.dealNextRound(seed: seed++));
        game.finishRound(round);
      }

      expect(players[0].cleanFixedContractsSoFar, isTrue);
      expect(players[0].totalScore, 40,
          reason: 'nothing else ever scored (nobody captured anything) — the only '
              'points on the board should be the one-time premium');

      // The premium must show up recorded against whichever round
      // actually completed the clean streak (the 6th), not spread out
      // or attributed to the wrong one.
      expect(players[0].fixedContractResults, hasLength(6));
      expect(players[0].fixedContractResults[ContractType.lastTwo], 40,
          reason: 'lastTwo is declared 6th in remainingFixedContracts order — the premium '
              'must be recorded on that round, since that\'s the one that completed the streak');
      expect(players[0].fixedContractResults[ContractType.king], 0);
    });

    test('a single failed fixed contract permanently rules out the premium bonus, '
        'even if the rest come out clean', () {
      final players = _freshPlayers();
      final game = GameEngine(players);

      var seed = 0;
      var player0FixedTurns = 0;
      while (players[0].remainingFixedContracts.isNotEmpty) {
        final declarerIdx = game.currentDeclarerIndex;
        final type = declarerIdx == 0
            ? game.legalDeclarationTypes(0).firstWhere((t) => t != ContractType.trump)
            : game.legalDeclarationTypes(declarerIdx).first;
        final declaration = type == ContractType.trump
            ? const Declaration(ContractType.trump, trumpSuit: Suit.clubs)
            : Declaration(type);
        final round = game.startRound(declaration, game.dealNextRound(seed: seed++));

        if (declarerIdx == 0) {
          player0FixedTurns++;
          if (player0FixedTurns == 1) {
            // Player 0's first fixed contract is always "king" (declared
            // first out of remainingFixedContracts' fixed order) — make
            // them fail it by having them capture the king of hearts.
            expect(type, ContractType.king);
            players[0].capturedThisRound.add(const PlayingCard(Suit.hearts, Rank.king));
          }
        }

        game.finishRound(round);
      }

      expect(players[0].cleanFixedContractsSoFar, isFalse);
      expect(players[0].totalScore, isNot(40),
          reason: 'one failure among the 6 must permanently disqualify the premium, '
              'no matter how clean the other 5 were');
    });
  });
}
