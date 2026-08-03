import 'package:king_game_engine/king_game_engine.dart';

/// Fixed display order for a hand of cards, purely cosmetic (has no
/// bearing on legality/scoring, which the engine handles independently):
/// გული, ყვავი, აგური, ჯვარი — each suit's own cards sorted high to low.
const List<Suit> _displaySuitOrder = [Suit.hearts, Suit.spades, Suit.diamonds, Suit.clubs];

List<PlayingCard> sortedForDisplay(List<PlayingCard> cards) {
  final sorted = List<PlayingCard>.of(cards);
  sorted.sort((a, b) {
    final suitCompare =
        _displaySuitOrder.indexOf(a.suit).compareTo(_displaySuitOrder.indexOf(b.suit));
    if (suitCompare != 0) return suitCompare;
    return b.rank.strength.compareTo(a.rank.strength);
  });
  return sorted;
}
