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
/// instead of needing a tap to see.
class MiniStandingsPanel extends StatelessWidget {
  final List<ScoreRow> rows;
  const MiniStandingsPanel({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KingColors.feltDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KingColors.onFeltHairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerRow(),
          for (final row in rows) _dataRow(row),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 44),
        for (final type in fixedColumnOrder) _headerCell(_abbreviation[type]!),
        _headerCell('+'),
        _headerCell('+'),
        _headerCell('+'),
        _headerCell('Σ'),
      ],
    );
  }

  Widget _dataRow(ScoreRow row) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
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
    return SizedBox(
      width: 18,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: KingColors.goldLight),
      ),
    );
  }

  Widget _cell(int? value) {
    return Container(
      width: 18,
      height: 14,
      margin: const EdgeInsets.symmetric(vertical: 1),
      alignment: Alignment.center,
      decoration: value == null
          ? null
          : BoxDecoration(
              color: value < 0 ? Colors.red.shade400 : Colors.green.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
      child: value == null
          ? null
          : Text(
              '$value',
              style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _totalCell(int total) {
    return SizedBox(
      width: 20,
      child: Text(
        '$total',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: KingColors.goldLight),
      ),
    );
  }
}
