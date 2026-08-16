import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../models/score_row.dart';
import '../theme/king_theme.dart';

const Map<ContractType, String> _abbreviation = {
  ContractType.king: 'K',
  ContractType.queen: 'Q',
  ContractType.jack: 'J',
  ContractType.noTricks: 'NT',
  ContractType.noHearts: 'H',
  ContractType.lastTwo: 'L2',
};

/// A small always-visible score grid in the corner of every in-game
/// screen, local or online — the same columns as the full [rows]
/// passed to [ScoreTableScreen] (which opens on tap), just shrunk down
/// with abbreviated headers so it fits permanently on the table
/// instead of needing a tap to see. Uses a real [Table] with grid lines
/// (like [ScoreTableScreen]'s own border) rather than individually
/// spaced boxes, so it reads as one sheet instead of loose tiles.
class MiniStandingsPanel extends StatelessWidget {
  final List<ScoreRow> rows;
  const MiniStandingsPanel({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KingColors.feltDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KingColors.onFeltHairline),
      ),
      // FixedColumnWidth columns don't need a bounded incoming width to
      // lay out, unlike FlexColumnWidth — important here since this
      // panel sits inside a Positioned overlay with unbounded width.
      child: Table(
        border: const TableBorder(
          horizontalInside: BorderSide(color: KingColors.onFeltHairline, width: 0.5),
          verticalInside: BorderSide(color: KingColors.onFeltHairline, width: 0.5),
        ),
        columnWidths: const {0: FixedColumnWidth(44), 10: FixedColumnWidth(20)},
        defaultColumnWidth: const FixedColumnWidth(18),
        children: [
          _headerRow(),
          for (final row in rows) _dataRow(row),
        ],
      ),
    );
  }

  TableRow _headerRow() {
    return TableRow(
      children: [
        const SizedBox(),
        for (final type in fixedColumnOrder) _headerCell(_abbreviation[type]!),
        _headerCell('+'),
        _headerCell('+'),
        _headerCell('+'),
        _headerCell('Σ'),
      ],
    );
  }

  TableRow _dataRow(ScoreRow row) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
          child: Text(
            row.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: KingColors.cream),
          ),
        ),
        for (final type in fixedColumnOrder) _cell(row.fixedResults[type]),
        for (var i = 0; i < 3; i++) _cell(i < row.plusResults.length ? row.plusResults[i] : null),
        _totalCell(row.totalScore),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: KingColors.goldLight),
      ),
    );
  }

  Widget _cell(int? value) {
    if (value == null) return const SizedBox(height: 16);
    return Container(
      color: value < 0 ? Colors.red.shade400 : Colors.green.shade700,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$value',
        style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _totalCell(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        '$total',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: KingColors.goldLight),
      ),
    );
  }
}
