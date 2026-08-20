import 'package:king_game_engine/king_game_engine.dart';

/// The minimal "who's at the table right now" shape the shared table
/// widgets (GameTableShell, SeatBadge, MiniStandingsPanel,
/// ContractBadge) need — implemented by both [OnlineGameClient] (a real
/// seat, one per device) and by a local pass-and-play adapter (where
/// "my seat" is whichever player is currently holding the phone), so
/// both modes render off the exact same widgets instead of two
/// look-alike layouts drifting apart over time.
abstract class TableClient {
  int? get mySeat;
  int? get declarerSeat;
  ContractType? get contract;
  Suit? get trumpSuit;
  bool get isMyTurnToDeclare;
  Map<int, int> get standings;
  String nameOf(int seat);
  String avatarIdOf(int seat);
  bool isConnected(int seat);

  /// Move clock (online only — always null for local pass-and-play,
  /// which has no other real players waiting on a slow turn): which
  /// seat currently has a live countdown, its base turnTimeLimit
  /// deadline, and — once that runs out — the shared time-bank deadline
  /// that takes over. See SeatBadge/TurnCountdownRing for the rendering.
  int? get timedSeat;
  DateTime? get turnDeadline;
  DateTime? get bankDeadline;
}
