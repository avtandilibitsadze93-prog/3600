import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../models/score_row.dart';
import '../theme/king_theme.dart';

export '../models/score_row.dart' show ScoreRow;

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
      appBar: AppBar(title: const Text('Score Table')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(12),
              // Every column the same width — the English contract names
              // ("No Tricks", "Last Two", ...) are all similar lengths,
              // so there's no need for the wider special-cased columns
              // the old Georgian labels needed.
              child: Table(
                border: TableBorder.all(color: KingColors.gold, width: 0.6),
                defaultColumnWidth: const FixedColumnWidth(64),
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
        for (final type in fixedColumnOrder) _headerCell(type.englishName),
        _headerCell('+'),
        _headerCell('+'),
        _headerCell('+'),
        _headerCell('Total'),
      ],
    );
  }

  TableRow _dataRow(ScoreRow row) {
    return TableRow(
      children: [
        _nameCell(row.name),
        for (final type in fixedColumnOrder) _resultCell(row.fixedResults[type]),
        for (var i = 0; i < 3; i++)
          _resultCell(i < row.plusResults.length ? row.plusResults[i] : null),
        _totalCell(row.totalScore),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: KingColors.inkNavy),
      ),
    );
  }

  Widget _nameCell(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        name,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: KingColors.cream),
      ),
    );
  }

  Widget _resultCell(int? value) {
    if (value == null) {
      return const SizedBox(height: 30);
    }
    final negative = value < 0;
    return Container(
      height: 30,
      alignment: Alignment.center,
      color: negative ? Colors.red.shade400 : Colors.green.shade700,
      child: Text(
        value > 0 ? '+$value' : '$value',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _totalCell(int total) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      child: Text(
        '$total',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: KingColors.goldLight),
      ),
    );
  }
}
