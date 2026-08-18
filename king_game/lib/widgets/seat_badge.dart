import 'package:flutter/material.dart';

import '../game/table_client.dart';
import '../theme/king_theme.dart';
import 'avatar_circle.dart';

/// One seat's avatar + name — ringed gold when it's their turn, dimmed
/// if a bot has taken over for a disconnected player. Shared by every
/// in-game screen, local or online (declaring, prikoup, trick), so a
/// player's spot at the table — left opponent, right opponent — stays
/// in the same place across phases, the way a real seat would. Played
/// cards for the current trick pile up together in the center (see
/// [TrickCenter]), not here.
class SeatBadge extends StatelessWidget {
  final TableClient client;
  final int seat;
  final bool isTurn;

  const SeatBadge({
    super.key,
    required this.client,
    required this.seat,
    this.isTurn = false,
  });

  @override
  Widget build(BuildContext context) {
    final connected = client.isConnected(seat);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isTurn ? Border.all(color: KingColors.goldLight, width: 2) : null,
              ),
              child: AvatarCircle(avatarId: client.avatarIdOf(seat), radius: 22, dimmed: !connected),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 84,
              child: Text(
                client.nameOf(seat),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isTurn ? KingColors.gold : KingColors.onFeltSoft,
                  fontWeight: isTurn ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
