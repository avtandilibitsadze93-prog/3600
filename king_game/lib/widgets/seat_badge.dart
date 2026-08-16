import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/online_game_client.dart';
import '../theme/king_theme.dart';
import 'avatar_circle.dart';
import 'playing_card_widget.dart';

/// One seat's avatar + name — ringed gold when it's their turn, dimmed
/// if a bot has taken over for a disconnected player, and showing
/// their card for the current trick if [playedCard] is given. Shared
/// by every online in-game screen (declaring, prikoup, trick) so a
/// player's spot at the table — left opponent, right opponent — stays
/// in the same place across phases, the way a real seat would.
class SeatBadge extends StatelessWidget {
  final OnlineGameClient client;
  final int seat;
  final bool isTurn;
  final PlayingCard? playedCard;

  const SeatBadge({
    super.key,
    required this.client,
    required this.seat,
    this.isTurn = false,
    this.playedCard,
  });

  @override
  Widget build(BuildContext context) {
    final connected = client.players.firstWhere((p) => p.seat == seat).connected;
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
            if (playedCard != null) ...[
              const SizedBox(height: 6),
              PlayingCardWidget(card: playedCard!, enabled: false),
            ],
          ],
        ),
      ),
    );
  }
}
