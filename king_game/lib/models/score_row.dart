import 'package:king_game_engine/king_game_engine.dart';

/// One player's row of data for the score sheet — deliberately plain
/// data (not [Player] or [OnlineGameClient] directly) so both the local
/// pass-and-play and online modes can build it from whatever they
/// already have, and so both [ScoreTableScreen] (full detail) and
/// [MiniStandingsPanel] (the always-visible corner version) can render
/// the exact same numbers.
class ScoreRow {
  final String name;
  final Map<ContractType, int> fixedResults;
  final List<int> plusResults;
  final int totalScore;

  const ScoreRow({
    required this.name,
    required this.fixedResults,
    required this.plusResults,
    required this.totalScore,
  });
}

/// Order the 6 fixed-contract columns are always shown in, left to
/// right — matches the order every player declares them in their own
/// [Player.remainingFixedContracts].
const List<ContractType> fixedColumnOrder = [
  ContractType.king,
  ContractType.queen,
  ContractType.jack,
  ContractType.noTricks,
  ContractType.noHearts,
  ContractType.lastTwo,
];
