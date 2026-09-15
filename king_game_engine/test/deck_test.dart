// determineSeatingByAceDraw's exact rule, pinned down against a fixed
// seed: whoever is dealt the deciding Ace takes *last*, the player to
// their left (next in the dealing rotation) goes first, and the
// remaining player goes second. Also checks the reveal sequence itself
// is consistent with the seating it produces.

import 'package:king_game_engine/king_game_engine.dart';
import 'package:test/test.dart';

void main() {
  group('determineSeatingByAceDraw', () {
    test('the player dealt the deciding Ace is last; the player to their '
        'left (next in rotation) is first; the remaining player is second', () {
      // Try enough seeds to hit every possible "ace lands on seat N"
      // case at least once, rather than pinning to one lucky/unlucky seed.
      final seenAceSeat = <int>{};
      for (var seed = 0; seed < 200 && seenAceSeat.length < 3; seed++) {
        final draw = determineSeatingByAceDraw([0, 1, 2], seed: seed);
        final aceSeat = draw.revealed.last.playerIndex;
        expect(draw.revealed.last.card.rank, Rank.ace,
            reason: 'the reveal must end exactly on the deciding Ace');
        seenAceSeat.add(aceSeat);

        final expectedFirst = (aceSeat + 1) % 3;
        final expectedSecond = (aceSeat + 2) % 3;
        expect(draw.seating, [expectedFirst, expectedSecond, aceSeat],
            reason: 'seat $aceSeat drew the Ace, so seating must be '
                '[$expectedFirst, $expectedSecond, $aceSeat]');

        // No earlier card in the reveal may have been an Ace — the draw
        // stops at the very first one.
        for (final step in draw.revealed.sublist(0, draw.revealed.length - 1)) {
          expect(step.card.rank, isNot(Rank.ace));
        }
      }
      expect(seenAceSeat, {0, 1, 2}, reason: 'sanity check on the seed sweep above');
    });

    test('players list order is respected, not assumed to be [0, 1, 2]', () {
      // Same rule, but with arbitrary player identifiers instead of raw
      // seat indices, to confirm the function maps by *position* in the
      // players list, not by the identifier values themselves.
      final draw = determineSeatingByAceDraw([7, 8, 9], seed: 1);
      expect(draw.seating.toSet(), {7, 8, 9});
      final aceSeatPosition = draw.revealed.last.playerIndex;
      final expectedFirst = [7, 8, 9][(aceSeatPosition + 1) % 3];
      final expectedSecond = [7, 8, 9][(aceSeatPosition + 2) % 3];
      expect(draw.seating, [expectedFirst, expectedSecond, [7, 8, 9][aceSeatPosition]]);
    });
  });
}
