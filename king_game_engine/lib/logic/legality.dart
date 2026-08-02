import '../models/card.dart';
import '../models/contract.dart';

/// Whether [card] may not be buried in the prikoup under [contract].
/// Pure, data-only version of [RoundEngine.isBurialForbidden] — usable by
/// a remote client (which only has JSON, not a live RoundEngine/Player)
/// to grey out illegal choices before the player even taps one, with the
/// server re-validating the same rule authoritatively.
bool isBurialForbidden(ContractType contract, PlayingCard card) {
  if ((contract == ContractType.king || contract == ContractType.noHearts) && card.isHeart) {
    return true;
  }
  if (contract == ContractType.queen && card.isQueen) return true;
  if (contract == ContractType.jack && card.isJack) return true;
  return false;
}

/// Cards [hand] may lead with, given [contract]'s heart-leading
/// restriction (king/noHearts: can't lead a heart unless it's all
/// that's left in hand).
List<PlayingCard> legalLeads(List<PlayingCard> hand, ContractType contract) {
  if (!contract.restrictsLeadingHearts) return List.of(hand);
  final onlyHeartsLeft = hand.isNotEmpty && hand.every((c) => c.isHeart);
  if (onlyHeartsLeft) return List.of(hand);
  return hand.where((c) => !c.isHeart).toList();
}

/// Cards [hand] may legally play into a trick, given [alreadyPlayedThisTrick]
/// (empty means this player is leading) and [contract]. Pure data-only
/// version of [RoundEngine.legalMoves].
List<PlayingCard> legalMoves({
  required List<PlayingCard> hand,
  required List<PlayingCard> alreadyPlayedThisTrick,
  required ContractType contract,
}) {
  if (alreadyPlayedThisTrick.isEmpty) return legalLeads(hand, contract);
  final led = alreadyPlayedThisTrick.first.suit;
  final canFollow = hand.any((c) => c.suit == led);
  if (canFollow) return hand.where((c) => c.suit == led).toList();
  return List.of(hand);
}
