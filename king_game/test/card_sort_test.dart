import 'package:flutter_test/flutter_test.dart';
import 'package:king_game_engine/king_game_engine.dart';
import 'package:king_game/widgets/card_sort.dart';

void main() {
  test('sortedForDisplay orders გული, ყვავი, აგური, ჯვარი, each high to low', () {
    const shuffled = [
      PlayingCard(Suit.clubs, Rank.seven),
      PlayingCard(Suit.hearts, Rank.jack),
      PlayingCard(Suit.diamonds, Rank.ace),
      PlayingCard(Suit.clubs, Rank.ace),
      PlayingCard(Suit.hearts, Rank.ace),
      PlayingCard(Suit.spades, Rank.nine),
      PlayingCard(Suit.hearts, Rank.seven),
      PlayingCard(Suit.spades, Rank.ace),
      PlayingCard(Suit.diamonds, Rank.seven),
    ];

    expect(sortedForDisplay(shuffled), [
      const PlayingCard(Suit.hearts, Rank.ace),
      const PlayingCard(Suit.hearts, Rank.jack),
      const PlayingCard(Suit.hearts, Rank.seven),
      const PlayingCard(Suit.spades, Rank.ace),
      const PlayingCard(Suit.spades, Rank.nine),
      const PlayingCard(Suit.diamonds, Rank.ace),
      const PlayingCard(Suit.diamonds, Rank.seven),
      const PlayingCard(Suit.clubs, Rank.ace),
      const PlayingCard(Suit.clubs, Rank.seven),
    ]);
  });

  test('does not mutate the input list', () {
    const original = [
      PlayingCard(Suit.clubs, Rank.seven),
      PlayingCard(Suit.hearts, Rank.ace),
    ];
    final copy = List.of(original);
    sortedForDisplay(original);
    expect(original, copy);
  });
}
