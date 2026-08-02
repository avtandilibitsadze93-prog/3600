import 'card.dart';

class TrickPlay {
  final int playerId;
  final PlayingCard card;
  const TrickPlay(this.playerId, this.card);
}

class Trick {
  final List<TrickPlay> plays = [];

  Suit? get ledSuit => plays.isEmpty ? null : plays.first.card.suit;

  bool get isComplete => plays.length == 3;

  void addPlay(int playerId, PlayingCard card) {
    plays.add(TrickPlay(playerId, card));
  }

  /// Determines the winner of a completed trick.
  /// If [trumpSuit] is provided (trump/"+" round) and any trump was played,
  /// the highest trump wins; otherwise the highest card of the led suit wins.
  int winner({Suit? trumpSuit}) {
    assert(isComplete);
    final led = ledSuit!;
    if (trumpSuit != null) {
      final trumpPlays = plays.where((p) => p.card.suit == trumpSuit);
      if (trumpPlays.isNotEmpty) {
        return trumpPlays
            .reduce((a, b) => a.card.rank.strength > b.card.rank.strength ? a : b)
            .playerId;
      }
    }
    final ledPlays = plays.where((p) => p.card.suit == led);
    return ledPlays
        .reduce((a, b) => a.card.rank.strength > b.card.rank.strength ? a : b)
        .playerId;
  }

  List<PlayingCard> get allCards => plays.map((p) => p.card).toList();
}
