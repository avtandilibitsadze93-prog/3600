/// The authoritative King (კინგი) rules engine — shared, unmodified, by
/// both the Flutter client (for local/offline use and UI-side legality
/// previews) and the game server (as the actual source of truth for a
/// live online match). Pure Dart, no Flutter dependency, so the server
/// can depend on it without pulling in the Flutter SDK.
library king_game_engine;

export 'models/card.dart';
export 'models/contract.dart';
export 'models/player.dart';
export 'models/trick.dart';
export 'logic/deck.dart';
export 'logic/game_engine.dart';
export 'logic/legality.dart';
export 'logic/round_engine.dart';
export 'wire.dart';
