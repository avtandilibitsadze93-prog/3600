// legalMoves' trump-following rule, pinned down directly against the
// pure function: follow suit if you can, otherwise trump is mandatory
// if you hold any, otherwise anything goes. Regression test for a real
// bug found in production — a trump ("+") round with a named trump
// suit let a player who couldn't follow the led suit play *any* card
// even while still holding trump, because legalMoves never looked at
// trumpSuit at all.

import 'package:king_game_engine/king_game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('legalMoves trump-following', () {
    const led = [PlayingCard(Suit.spades, Rank.eight), PlayingCard(Suit.spades, Rank.seven)];

    test('must play trump when unable to follow suit and holding trump', () {
      const hand = [
        PlayingCard(Suit.hearts, Rank.king),
        PlayingCard(Suit.hearts, Rank.jack),
        PlayingCard(Suit.diamonds, Rank.eight), // the trump suit
        PlayingCard(Suit.clubs, Rank.king),
      ];
      final legal = legalMoves(
        hand: hand,
        alreadyPlayedThisTrick: led,
        contract: ContractType.trump,
        trumpSuit: Suit.diamonds,
      );
      expect(legal, [const PlayingCard(Suit.diamonds, Rank.eight)],
          reason: 'holding no spades but one diamond (trump) — only the trump card is legal');
    });

    test('any card is legal when holding neither the led suit nor trump', () {
      const hand = [
        PlayingCard(Suit.hearts, Rank.king),
        PlayingCard(Suit.hearts, Rank.jack),
        PlayingCard(Suit.clubs, Rank.king),
      ];
      final legal = legalMoves(
        hand: hand,
        alreadyPlayedThisTrick: led,
        contract: ContractType.trump,
        trumpSuit: Suit.diamonds,
      );
      expect(legal, hand, reason: 'no spades and no diamonds — every card is legal');
    });

    test('following the led suit is still required even ahead of trump', () {
      const hand = [
        PlayingCard(Suit.spades, Rank.nine),
        PlayingCard(Suit.diamonds, Rank.eight), // the trump suit
      ];
      final legal = legalMoves(
        hand: hand,
        alreadyPlayedThisTrick: led,
        contract: ContractType.trump,
        trumpSuit: Suit.diamonds,
      );
      expect(legal, [const PlayingCard(Suit.spades, Rank.nine)],
          reason: 'can follow suit — trump is irrelevant while that is possible');
    });

    test('no trump-following requirement in ბეზი (no-trump) rounds', () {
      const hand = [
        PlayingCard(Suit.hearts, Rank.king),
        PlayingCard(Suit.diamonds, Rank.eight),
      ];
      final legal = legalMoves(
        hand: hand,
        alreadyPlayedThisTrick: led,
        contract: ContractType.trump,
        trumpSuit: null,
      );
      expect(legal, hand, reason: 'ბეზი has no trump suit at all — any card is legal once unable to follow');
    });

    test('no trump-following requirement in a fixed (non-plus) contract', () {
      const hand = [
        PlayingCard(Suit.hearts, Rank.king),
        PlayingCard(Suit.diamonds, Rank.eight),
      ];
      final legal = legalMoves(
        hand: hand,
        alreadyPlayedThisTrick: led,
        contract: ContractType.king,
      );
      expect(legal, hand);
    });
  });
}
