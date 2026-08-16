import 'package:flutter/material.dart';

import '../game/online_game_client.dart';
import '../theme/king_theme.dart';
import 'avatar_circle.dart';

/// A small always-visible standings panel in the corner of every online
/// in-game screen — like Joker's table-side score sheet, but condensed
/// to a running total per player (the full round-by-round breakdown
/// stays one tap away behind the score-table icon already in the
/// AppBar) since a real 27-row grid has no room on a landscape phone
/// screen next to the table itself.
class MiniStandingsPanel extends StatelessWidget {
  final OnlineGameClient client;
  const MiniStandingsPanel({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      // A fixed width — rather than leaving the Row inside to size
      // itself off its parent — since this panel is meant to float
      // inside a Positioned, which hands its child unbounded width;
      // the Flexible name Text below needs a real bound to shrink
      // against, not "as wide as it wants."
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: KingColors.feltDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KingColors.onFeltHairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var seat = 0; seat < 3; seat++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  AvatarCircle(avatarId: client.avatarIdOf(seat), radius: 9),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      client.nameOf(seat),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: seat == client.mySeat ? FontWeight.bold : FontWeight.normal,
                        color: seat == client.mySeat ? KingColors.gold : KingColors.onFeltSoft,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${client.standings[seat] ?? 0}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: KingColors.creamMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
