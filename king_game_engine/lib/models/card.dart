/// The 4 suits used in the 32-card King deck.
enum Suit {
  clubs, // ჯვარი
  spades, // ყვავი
  hearts, // გული
  diamonds, // აგური
}

extension SuitGeorgian on Suit {
  String get georgianName {
    switch (this) {
      case Suit.clubs:
        return 'ჯვარი';
      case Suit.spades:
        return 'ყვავი';
      case Suit.hearts:
        return 'გული';
      case Suit.diamonds:
        return 'აგური';
    }
  }

  String get englishName {
    switch (this) {
      case Suit.clubs:
        return 'Clubs';
      case Suit.spades:
        return 'Spades';
      case Suit.hearts:
        return 'Hearts';
      case Suit.diamonds:
        return 'Diamonds';
    }
  }

  String get symbol {
    switch (this) {
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
    }
  }
}

/// Card ranks 7 through Ace (32-card deck: 7,8,9,10,J,Q,K,A per suit).
enum Rank {
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

extension RankInfo on Rank {
  /// Higher value wins tricks (Ace highest).
  int get strength => index;

  String get georgianName {
    switch (this) {
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'ვალეტი';
      case Rank.queen:
        return 'დამა';
      case Rank.king:
        return 'მეფე';
      case Rank.ace:
        return 'ტუზი';
    }
  }

  String get englishName {
    switch (this) {
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
      case Rank.ace:
        return 'A';
    }
  }
}

class PlayingCard {
  final Suit suit;
  final Rank rank;

  const PlayingCard(this.suit, this.rank);

  bool get isHeart => suit == Suit.hearts;
  bool get isQueen => rank == Rank.queen;
  bool get isJack => rank == Rank.jack;

  /// The King of Hearts specifically ("კაროლ გული") — the card the
  /// King (მეფე) contract cares about.
  bool get isKingOfHearts => suit == Suit.hearts && rank == Rank.king;

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => '${rank.englishName}${suit.symbol}';
}
