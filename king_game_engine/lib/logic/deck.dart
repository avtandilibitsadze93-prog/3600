import 'dart:math';
import '../models/card.dart';

/// Builds and shuffles the standard 32-card King deck (7 through Ace).
class Deck {
  final List<PlayingCard> cards;

  Deck._(this.cards);

  factory Deck.fresh({int? seed}) {
    final cards = <PlayingCard>[
      for (final suit in Suit.values)
        for (final rank in Rank.values) PlayingCard(suit, rank),
    ];
    final rng = seed != null ? Random(seed) : Random();
    cards.shuffle(rng);
    return Deck._(cards);
  }

  /// Deals 10 cards to each of the 3 [playerOrder] positions and returns
  /// the 2 remaining cards as the hidden widow (see [prikoupName]).
  ///
  /// Returns a map from player index -> hand, plus the widow under key -1.
  static DealtHands deal(Deck deck) {
    assert(deck.cards.length == 32);
    final hands = <int, List<PlayingCard>>{0: [], 1: [], 2: []};
    for (var i = 0; i < 30; i++) {
      hands[i % 3]!.add(deck.cards[i]);
    }
    final prikoup = deck.cards.sublist(30, 32);
    return DealtHands(hands: hands, prikoup: prikoup);
  }
}

class DealtHands {
  final Map<int, List<PlayingCard>> hands;
  final List<PlayingCard> prikoup;

  DealtHands({required this.hands, required this.prikoup});
}

/// Determines seating order (1st/2nd/last) via the classic "ვინ როგორი
/// აიტუზოს" draw: deal cards one at a time from a shuffled deck until
/// each player has drawn an Ace. The player who draws their Ace *last*
/// takes last position; the other two keep the order they drew their aces in.
///
/// Returns a list of player indices (0,1,2 as given) in seating order:
/// [first, second, last].
List<int> determineSeatingByAceDraw(List<int> players, {int? seed}) {
  final rng = seed != null ? Random(seed) : Random();
  final drawDeck = <PlayingCard>[
    for (final suit in Suit.values)
      for (final rank in Rank.values) PlayingCard(suit, rank),
  ]..shuffle(rng);

  final aceOrder = <int>[];
  // Cards are dealt one at a time to whoever's turn it is *among players
  // still waiting for their ace* — once a player draws one, they drop out
  // of the rotation and every subsequent card goes only to the rest. This
  // guarantees termination as long as the deck has at least as many aces
  // as there are players (4 aces, 3 players here): the single player left
  // active at the end receives every remaining card, and at least one
  // unclaimed ace is guaranteed to still be among them.
  final active = List<int>.from(players);
  var cursor = 0;
  var turn = 0;

  while (active.isNotEmpty) {
    final card = drawDeck[cursor++];
    final slot = turn % active.length;
    if (card.rank == Rank.ace) {
      aceOrder.add(active.removeAt(slot));
    } else {
      turn++;
    }
  }

  return aceOrder; // [first-to-draw-ace, second, last]
}
