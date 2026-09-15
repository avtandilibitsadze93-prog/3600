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

/// One card of an [AceDraw]'s reveal, in dealt order.
class AceDrawCard {
  /// Index into the [AceDraw]'s original `players` list — which seat this
  /// card was dealt to, not a table position.
  final int playerIndex;
  final PlayingCard card;
  const AceDrawCard(this.playerIndex, this.card);
}

/// The full "ვინ როგორ აიტუზოს" ("who draws which ace") reveal: every card
/// dealt on the way to the first Ace, plus the seating it produced — kept
/// together so a UI can replay the whole deal, not just jump to the result.
class AceDraw {
  final List<AceDrawCard> revealed;
  /// Seating order: [first, second, last] — see [determineSeatingByAceDraw].
  final List<int> seating;
  const AceDraw(this.revealed, this.seating);
}

/// Determines seating order (1st/2nd/last) via the classic "ვინ როგორი
/// აიტუზოს" draw: cards are dealt one at a time, in rotation, from a
/// shuffled deck until an Ace comes up. Whoever is dealt that Ace takes
/// *last* position; the player to their left (next in the dealing
/// rotation) goes first, and the remaining player goes second.
AceDraw determineSeatingByAceDraw(List<int> players, {int? seed}) {
  final rng = seed != null ? Random(seed) : Random();
  final drawDeck = <PlayingCard>[
    for (final suit in Suit.values)
      for (final rank in Rank.values) PlayingCard(suit, rank),
  ]..shuffle(rng);

  final revealed = <AceDrawCard>[];
  var cursor = 0;
  var slot = 0;
  // A 32-card deck always has 4 Aces, so dealing one card at a time in
  // rotation is guaranteed to turn one up well before the deck runs out.
  while (true) {
    final card = drawDeck[cursor++];
    revealed.add(AceDrawCard(slot, card));
    if (card.rank == Rank.ace) {
      final first = (slot + 1) % players.length;
      final second = (slot + 2) % players.length;
      return AceDraw(revealed, [players[first], players[second], players[slot]]);
    }
    slot = (slot + 1) % players.length;
  }
}
