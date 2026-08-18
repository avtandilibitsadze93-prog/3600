import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../game/table_client.dart';
import '../theme/king_theme.dart';
import 'avatar_circle.dart';
import 'playing_card_widget.dart';

/// One seat's avatar + name — ringed gold when it's their turn, dimmed
/// if a bot has taken over for a disconnected player. Shared by every
/// in-game screen, local or online (declaring, prikoup, trick), so a
/// player's spot at the table — left opponent, right opponent — stays
/// in the same place across phases, the way a real seat would.
///
/// During a trick, [showCardSlot] reserves a card-sized spot right
/// under this seat's own avatar for whatever they've played this
/// trick — so each card reads as "this seat's card", not a pile of
/// cards floating in the middle unconnected to whose they are. That
/// slot is bottom-anchored (see build()) rather than centered in the
/// seat's column, so the played card lines up with [TrickCenter]'s own
/// bottom-anchored card — both sit on the same row right above the
/// hand, "symmetric" left/mine/right, instead of at whatever height
/// each column's differently-sized content happens to center around.
class SeatBadge extends StatelessWidget {
  final TableClient client;
  final int seat;
  final bool isTurn;
  final bool showCardSlot;
  final PlayingCard? playedCard;

  const SeatBadge({
    super.key,
    required this.client,
    required this.seat,
    this.isTurn = false,
    this.showCardSlot = false,
    this.playedCard,
  });

  @override
  Widget build(BuildContext context) {
    final connected = client.isConnected(seat);
    final content = Column(
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
        if (showCardSlot) ...[
          const SizedBox(height: 8),
          KeyedSubtree(
            key: ValueKey('card_slot_$seat'),
            child: playedCard != null
                ? PlayingCardWidget(card: playedCard!, enabled: false)
                : Container(
                    width: 56,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: KingColors.onFeltHairline, width: 1),
                    ),
                  ),
          ),
        ],
      ],
    );
    if (!showCardSlot) {
      return Center(child: SingleChildScrollView(child: content));
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(padding: const EdgeInsets.only(bottom: 20), child: content),
    );
  }
}
