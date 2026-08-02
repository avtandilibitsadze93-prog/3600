import 'card.dart';

/// The 7 declarable contracts. Across a full game, the 6 fixed contracts
/// are each declared exactly once in total (by whoever's turn it is),
/// and each of the 3 players declares [trump] exactly once — 9 rounds total.
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

/// A declared contract for a round; [trumpSuit] is only set when
/// [type] == ContractType.trump.
class Declaration {
  final ContractType type;
  final Suit? trumpSuit;

  const Declaration(this.type, {this.trumpSuit})
      : assert(type != ContractType.trump || trumpSuit != null,
            'Trump round requires a trump suit');
}
