import 'package:flutter/material.dart';

import '../game/online_game_client.dart';
import 'avatar_circle.dart';
import 'contract_badge.dart';
import 'mini_standings_panel.dart';

/// The shared table furniture every online in-game screen (declaring,
/// prikoup, trick) sits inside: standings top-left, current contract
/// top-right, the two opponent seats left/right of whatever this phase
/// wants shown in the middle, and your own avatar next to your hand
/// along the bottom — the same "seat at a real table" frame in every
/// phase instead of each screen laying itself out from scratch.
class GameTableShell extends StatelessWidget {
  final OnlineGameClient client;
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: MiniStandingsPanel(client: client)),
              const SizedBox(width: 8),
              Flexible(child: Align(alignment: Alignment.centerRight, child: ContractBadge(client: client))),
            ],
          ),
          const SizedBox(height: 4),
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
          const SizedBox(height: 8),
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
