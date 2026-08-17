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

const double _rowHeight = 18;

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
      // Clips the Table's sharp rectangular corners to the rounded
      // border instead of just drawing the border on top of them,
      // which otherwise left a sliver of unclipped background peeking
      // out past the border at each corner.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: KingColors.feltDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KingColors.onFeltHairline),
      ),
      // FixedColumnWidth columns don't need a bounded incoming width to
      // lay out, unlike FlexColumnWidth — important here since this
      // panel sits inside a Positioned overlay with unbounded width.
      //
      // Every cell across every row is exactly _rowHeight tall (Center
      // instead of Padding) so Table's default top-aligned cells can't
      // leave a shorter cell's own leftover space unfilled within a row
      // that's tall enough to fit that row's other, taller cells.
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
        const SizedBox(height: _rowHeight),
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
        Container(
          height: _rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.centerLeft,
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
    return Container(
      height: _rowHeight,
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: KingColors.goldLight),
      ),
    );
  }

  // Just the win/loss color, no number — this panel is a permanent
  // at-a-glance corner fixture, not the place to read exact scores; the
  // full ScoreTableScreen (a tap away) has the real numbers.
  Widget _cell(int? value) {
    return Container(
      height: _rowHeight,
      color: value == null ? null : (value < 0 ? Colors.red.shade400 : Colors.green.shade700),
    );
  }

  Widget _totalCell(int total) {
    return Container(
      height: _rowHeight,
      alignment: Alignment.center,
      child: Text(
        '$total',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: KingColors.goldLight),
      ),
    );
  }
}
