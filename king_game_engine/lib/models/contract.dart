import 'card.dart';

/// The 7 declarable contracts. Across a full 27-round game, each of the
/// 3 players declares every one of the 6 fixed contracts exactly once
/// (18 rounds total, in whatever order that player chooses), plus 3
/// "plus" turns each (trump — a named suit, or "ბეზი"/no-trump when
/// [Declaration.trumpSuit] is null — repeats allowed, 9 rounds per
/// player, 27 total).
enum ContractType {
  king, // მეფე — king of hearts penalty
  queen, // დამა — penalty per queen taken
  jack, // ვალეტი — penalty per jack taken
  noTricks, // არაფრის არ წაღება — penalty per trick taken
  noHearts, // გულის არ წაღება — penalty per heart taken
  lastTwo, // ბოლო 2 — penalty per last-two-tricks taken
  trump, // კოზირი / "+" — positive scoring round with a named trump suit
}

extension ContractInfo on ContractType {
  String get georgianName {
    switch (this) {
      case ContractType.king:
        return 'მეფე';
      case ContractType.queen:
        return 'დამა';
      case ContractType.jack:
        return 'ვალეტი';
      case ContractType.noTricks:
        return 'არაფრის არ წაღება';
      case ContractType.noHearts:
        return 'გულის არ წაღება';
      case ContractType.lastTwo:
        return 'ბოლო 2';
      case ContractType.trump:
        return 'კოზირი';
    }
  }

  /// English label, per the Russian naming this game is usually known by
  /// (Кинг/Дама/Валет/Взятки/Черви/Две последние/+): trump is just "+",
  /// not "Trump".
  String get englishName {
    switch (this) {
      case ContractType.king:
        return 'King';
      case ContractType.queen:
        return 'Queen';
      case ContractType.jack:
        return 'Jack';
      case ContractType.noTricks:
        return 'No Tricks';
      case ContractType.noHearts:
        return 'Hearts';
      case ContractType.lastTwo:
        return 'Last Two';
      case ContractType.trump:
        return '+';
    }
  }

  /// Whether leading a heart is restricted in this contract to only when
  /// no other suit remains in the leader's hand. Applies to king & noHearts.
  bool get restrictsLeadingHearts =>
      this == ContractType.king || this == ContractType.noHearts;

  bool get isFixedContract => this != ContractType.trump;
}

/// Display name for the 2 face-down cards the declarer takes into their
/// hand before burying 2 back. Not a [ContractType] itself, but named
/// here alongside the rest of the game's terminology so there's one
/// place UI code looks this up. Always shown as "Widow" — this is the
/// one term the UI intentionally keeps in English rather than Georgian.
const String prikoupName = 'Widow';

/// Display name for a trump declaration with no named suit ("ბეზი") —
/// tricks are won by highest card of the led suit only.
const String noTrumpName = 'No Trump';

/// A declared contract for a round. [trumpSuit] is only meaningful when
/// [type] == ContractType.trump: a named suit for an ordinary "+" round,
/// or null for "ბეზი" (no-trump — tricks are won by highest card of the
/// led suit only, same as [Trick.winner] already does when no trump is
/// in play).
class Declaration {
  final ContractType type;
  final Suit? trumpSuit;

  const Declaration(this.type, {this.trumpSuit});
}
