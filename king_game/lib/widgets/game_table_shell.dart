import 'package:flutter/material.dart';

import '../game/table_client.dart';
import 'avatar_circle.dart';

/// The shared table furniture every in-game screen — local or online —
/// sits inside: the two opponent seats left/right of whatever this
/// phase wants shown in the middle, and your own avatar next to your
/// hand along the bottom — the same "seat at a real table" frame in
/// every phase instead of each screen laying itself out from scratch.
/// The standings panel and contract badge live above this, floating in
/// the screen's corners (see OnlineGameFlowScreen / GameFlowScreen) —
/// top padding here just leaves them room.
class GameTableShell extends StatelessWidget {
  final TableClient client;
  final Widget leftSeat;
  final Widget rightSeat;
  final Widget center;
  final Widget hand;

  const GameTableShell({
    super.key,
    required this.client,
    required this.leftSeat,
    required this.rightSeat,
    required this.center,
    required this.hand,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Top padding must clear the standings panel floating over the
      // corner (see OnlineGameFlowScreen) — it's ~78px tall starting 8px
      // from the screen edge, so anything shorter here lets its hitbox
      // overlap the seat/grid content underneath and steal taps meant
      // for them (confirmed by online_widget_test.dart before this fix).
      padding: const EdgeInsets.fromLTRB(12, 100, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: leftSeat),
                Expanded(flex: 5, child: center),
                Expanded(flex: 2, child: rightSeat),
              ],
            ),
          ),
          // Wider than a purely cosmetic gap needs to be on its own —
          // this is what actually keeps a trick's played-card slots
          // (bottom-anchored right at the top row's own bottom edge, see
          // SeatBadge/TrickCenter) from reading as touching the hand row
          // just below them.
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  AvatarCircle(avatarId: client.avatarIdOf(client.mySeat!), radius: 16),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 60,
                    child: Text(
                      client.nameOf(client.mySeat!),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(child: hand),
            ],
          ),
        ],
      ),
    );
  }
}
