import 'models/card.dart';

/// JSON encoding for cards, shared verbatim by the client and the
/// server — the wire format has exactly one definition, so neither side
/// can silently drift out of sync with the other.
Map<String, dynamic> cardToJson(PlayingCard c) =>
    {'suit': c.suit.name, 'rank': c.rank.name};

PlayingCard cardFromJson(Map<String, dynamic> json) => PlayingCard(
      Suit.values.byName(json['suit'] as String),
      Rank.values.byName(json['rank'] as String),
    );

List<Map<String, dynamic>> cardsToJson(Iterable<PlayingCard> cards) =>
    cards.map(cardToJson).toList();

List<PlayingCard> cardsFromJson(List<dynamic> json) =>
    json.map((c) => cardFromJson(c as Map<String, dynamic>)).toList();
