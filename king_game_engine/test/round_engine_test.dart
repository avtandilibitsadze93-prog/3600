// Some contracts can be decided before all 10 tricks are played: once
// every penalty-relevant card is already captured, no further play can
// change the score, so playing the rest out is pure busywork. These
// tests pin down exactly which contracts get that early-out and which
// ones (noTricks, lastTwo, trump/"+") must always run the full 10
// tricks, since their score depends on the whole trick distribution.

import 'package:king_game_engine/king_game_engine.dart';
import 'package:test/test.dart';

List<Player> _freshPlayers() => [
      Player(id: 0, name: 'ავთო'),
      Player(id: 1, name: 'ვასო'),
      Player(id: 2, name: 'გიორგი'),
    ];

void main() {
  group('RoundEngine.roundIsOver (early termination)', () {
    test('king ends the round as soon as K♥ is captured by anyone', () {
      final game = GameEngine(_freshPlayers());
      final round = game.startRound(const Declaration(ContractType.king), game.dealNextRound(seed: 1));
      expect(round.roundIsOver, isFalse);

      game.players[1].capturedThisRound.add(const PlayingCard(Suit.hearts, Rank.king));
      expect(round.roundIsOver, isTrue);
    });

    test('queen ends the round only once all 4 queens have been captured', () {
      final game = GameEngine(_freshPlayers());
      final round = game.startRound(const Declaration(ContractType.queen), game.dealNextRound(seed: 2));

      game.players[0].capturedThisRound.addAll(const [
        PlayingCard(Suit.clubs, Rank.queen),
        PlayingCard(Suit.spades, Rank.queen),
        PlayingCard(Suit.hearts, Rank.queen),
      ]);
      expect(round.roundIsOver, isFalse, reason: 'only 3 of 4 queens captured so far');

      game.players[2].capturedThisRound.add(const PlayingCard(Suit.diamonds, Rank.queen));
      expect(round.roundIsOver, isTrue, reason: 'all 4 queens are now accounted for');
    });

    test('jack ends the round only once all 4 jacks have been captured', () {
      final game = GameEngine(_freshPlayers());
      final round = game.startRound(const Declaration(ContractType.jack), game.dealNextRound(seed: 3));

      game.players[0].capturedThisRound.addAll(const [
        PlayingCard(Suit.clubs, Rank.jack),
        PlayingCard(Suit.spades, Rank.jack),
        PlayingCard(Suit.hearts, Rank.jack),
      ]);
      expect(round.roundIsOver, isFalse);

      game.players[1].capturedThisRound.add(const PlayingCard(Suit.diamonds, Rank.jack));
      expect(round.roundIsOver, isTrue);
    });

    test('noHearts (გულის არ წაღება) ends the round only once all 8 hearts have been captured', () {
      final game = GameEngine(_freshPlayers());
      final round = game.startRound(const Declaration(ContractType.noHearts), game.dealNextRound(seed: 4));

      final hearts = [Rank.seven, Rank.eight, Rank.nine, Rank.ten, Rank.jack, Rank.queen, Rank.king]
          .map((r) => PlayingCard(Suit.hearts, r));
      game.players[0].capturedThisRound.addAll(hearts);
      expect(round.roundIsOver, isFalse, reason: 'only 7 of 8 hearts captured so far');

      game.players[1].capturedThisRound.add(const PlayingCard(Suit.hearts, Rank.ace));
      expect(round.roundIsOver, isTrue);
    });

    test('noTricks and lastTwo never end early — always require all 10 tricks', () {
      for (final type in [ContractType.noTricks, ContractType.lastTwo]) {
        final game = GameEngine(_freshPlayers());
        final round = game.startRound(Declaration(type), game.dealNextRound(seed: 5));

        // Even with every card a fixed contract would ever care about
        // already captured, these two don't key off specific cards —
        // only the full 10 tricks decide their score.
        game.players[0].capturedThisRound.addAll(const [
          PlayingCard(Suit.hearts, Rank.king),
          PlayingCard(Suit.clubs, Rank.queen),
          PlayingCard(Suit.spades, Rank.queen),
          PlayingCard(Suit.hearts, Rank.queen),
          PlayingCard(Suit.diamonds, Rank.queen),
          PlayingCard(Suit.clubs, Rank.jack),
          PlayingCard(Suit.spades, Rank.jack),
          PlayingCard(Suit.hearts, Rank.jack),
          PlayingCard(Suit.diamonds, Rank.jack),
        ]);
        expect(round.roundIsOver, isFalse, reason: '$type must always play all 10 tricks');
      }
    });

    test('trump/"+" (including ბეზი) never ends early — always requires all 10 tricks', () {
      for (final trumpSuit in [Suit.clubs, null]) {
        final game = GameEngine(_freshPlayers());
        final round =
            game.startRound(Declaration(ContractType.trump, trumpSuit: trumpSuit), game.dealNextRound(seed: 6));

        game.players[0].capturedThisRound.add(const PlayingCard(Suit.hearts, Rank.king));
        expect(round.roundIsOver, isFalse);
      }
    });
  });
}
