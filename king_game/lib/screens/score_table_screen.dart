import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../theme/king_theme.dart';

/// One player's row of data for [ScoreTableScreen] — deliberately plain
/// data (not [Player] or [OnlineGameClient] directly) so both the local
/// pass-and-play and online modes can build it from whatever they
/// already have.
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
const List<ContractType> _fixedColumnOrder = [
  ContractType.king,
  ContractType.queen,
  ContractType.jack,
  ContractType.noTricks,
  ContractType.noHearts,
  ContractType.lastTwo,
];

/// The score sheet: one row per player, one column per contract "slot"
/// (their own 6 fixed contracts, in a fixed order, plus their 3 "plus"
/// turns), each cell filled in — red for a loss, green for a gain or a
/// clean zero — as soon as that round is played. Purely a read-only
/// summary; nothing here is tappable.
class ScoreTableScreen extends StatelessWidget {
  final List<ScoreRow> rows;
  const ScoreTableScreen({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ცხრილი')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Table(
                border: TableBorder.all(color: KingColors.gold, width: 0.6),
                columnWidths: const {
                  0: FixedColumnWidth(88),
                  // noTricks/noHearts have much longer Georgian names
                  // ("არაფრის არ წაღება" / "გულის არ წაღება") than the
                  // other columns — give them extra room so the header
                  // doesn't wrap to 4+ lines.
                  4: FixedColumnWidth(88),
                  5: FixedColumnWidth(88),
                },
                defaultColumnWidth: const FixedColumnWidth(60),
                children: [
                  _headerRow(),
                  for (final row in rows) _dataRow(row),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: const BoxDecoration(color: KingColors.cream),
      children: [
        _headerCell(''),
        for (final type in _fixedColumnOrder) _headerCell(type.georgianName),
        _headerCell('+'),
        _headerCell('+'),
        _headerCell('+'),
        _headerCell('ჯამი'),
      ],
    );
  }

  TableRow _dataRow(ScoreRow row) {
    return TableRow(
      children: [
        _nameCell(row.name),
        for (final type in _fixedColumnOrder) _resultCell(row.fixedResults[type]),
        for (var i = 0; i < 3; i++)
          _resultCell(i < row.plusResults.length ? row.plusResults[i] : null),
        _totalCell(row.totalScore),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: KingColors.inkNavy),
      ),
    );
  }

  Widget _nameCell(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KingColors.cream),
      ),
    );
  }

  Widget _resultCell(int? value) {
    if (value == null) {
      return const SizedBox(height: 40);
    }
    final negative = value < 0;
    return Container(
      height: 40,
      alignment: Alignment.center,
      color: negative ? Colors.red.shade400 : Colors.green.shade700,
      child: Text(
        value > 0 ? '+$value' : '$value',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _totalCell(int total) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      child: Text(
        '$total',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KingColors.goldLight),
      ),
    );
  }
}
