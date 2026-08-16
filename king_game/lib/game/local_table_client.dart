import 'package:king_game_engine/king_game_engine.dart';

import '../models/avatar.dart';
import 'game_controller.dart';
import 'table_client.dart';

/// Adapts [GameController]'s pass-and-play state to the same
/// [TableClient] shape [OnlineGameClient] already implements, so the
/// local hotseat screens can be built from the exact same table
/// widgets as the online ones — "my seat" here is just whichever
/// player is currently holding the phone.
///
/// "Seat" here means [Player.id] (stable, assigned once at setup in
/// entry order) — the same thing [Trick]'s playerId values are, and
/// the same thing the online server means by "seat". [GameController]
/// otherwise indexes players by their *table position*
/// (`activePlayerIndex`, `game.players[i]`, seating decided by the ace
/// draw), which is a different number — every lookup here goes through
/// `game.players` to translate between the two, exactly like the
/// server's `_seatAt` does.
///
/// Local players never picked an avatar (there's no per-device
/// registration to hang one off), so each seat gets a fixed default by
/// id — purely cosmetic, just enough for the shared widgets to have
/// something to draw.
class LocalTableClient implements TableClient {
  final GameController controller;
  const LocalTableClient(this.controller);

  @override
  int? get mySeat => controller.activePlayer.id;

  @override
  int? get declarerSeat => controller.game.players[controller.game.currentDeclarerIndex].id;

  @override
  ContractType? get contract => controller.round?.declaration.type;

  @override
  Suit? get trumpSuit => controller.round?.declaration.trumpSuit;

  @override
  bool get isMyTurnToDeclare => controller.phase == GamePhase.declaring;

  @override
  Map<int, int> get standings => {for (final p in controller.players) p.id: p.totalScore};

  @override
  String nameOf(int seat) => controller.players.firstWhere((p) => p.id == seat).name;

  @override
  String avatarIdOf(int seat) => kAvatarOptions[seat % kAvatarOptions.length].id;

  @override
  bool isConnected(int seat) => true;
}
