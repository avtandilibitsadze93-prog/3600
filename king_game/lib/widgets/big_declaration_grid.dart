import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../models/score_row.dart';
import '../theme/king_theme.dart';

/// The declaring phase's whole interface: the exact same bordered score
/// sheet [MiniStandingsPanel]/[ScoreTableScreen] always show, just made
/// big enough to *be* the interaction surface — the declaring player
/// picks their contract by tapping the open cell in their own row,
/// instead of a separate grid unrelated to the score sheet they already
/// read every round. [MiniStandingsPanel] hides itself for the duration
/// (see the game-flow screens) so there's only ever one score sheet on
/// screen at a time; once a contract is chosen the phase moves on and
/// this widget is torn down, leaving the small corner panel in its place.
class BigDeclarationGrid extends StatefulWidget {
  final List<ScoreRow> rows;
  final int myRowIndex;
  final List<ContractType> legalTypes;
  final void Function(ContractType type, {Suit? trumpSuit}) onDeclare;

  const BigDeclarationGrid({
    super.key,
    required this.rows,
    required this.myRowIndex,
    required this.legalTypes,
    required this.onDeclare,
  });

  @override
  State<BigDeclarationGrid> createState() => _BigDeclarationGridState();
}

class _BigDeclarationGridState extends State<BigDeclarationGrid> {
  bool _pickingPlus = false;
  Suit? _chosenTrumpSuit;
  bool _bezChosen = false;

  bool get _hasChosenPlus => _chosenTrumpSuit != null || _bezChosen;

  @override
  Widget build(BuildContext context) {
    return _pickingPlus ? _buildSuitPicker() : _buildTable();
  }

  // FlexColumnWidth needs a bounded width to distribute — Column's
  // default stretch behavior (from DeclarationLayout's ancestor Column)
  // supplies that, so the table always fills the full available width
  // rather than the fixed-64px columns ScoreTableScreen uses (which rely
  // on horizontal scrolling instead).
  Widget _buildTable() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Table(
              border: TableBorder.all(color: KingColors.gold, width: 0.8),
              columnWidths: const {0: FlexColumnWidth(1.3)},
              defaultColumnWidth: const FlexColumnWidth(1),
              children: [
                _headerRow(),
                for (var i = 0; i < widget.rows.length; i++) _dataRow(i),
              ],
            ),
          ],
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

  TableRow _dataRow(int index) {
    final row = widget.rows[index];
    final isMine = index == widget.myRowIndex;
    return TableRow(
      children: [
        _nameCell(row.name, isMine),
        for (final type in fixedColumnOrder) _fixedCell(row, type, isMine),
        for (var slot = 0; slot < 3; slot++) _plusCell(row, slot, isMine),
        _totalCell(row.totalScore),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KingColors.inkNavy),
      ),
    );
  }

  Widget _nameCell(String name, bool isMine) {
    return Container(
      color: isMine ? KingColors.gold.withValues(alpha: 0.25) : null,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      alignment: Alignment.center,
      child: Text(
        name,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KingColors.cream),
      ),
    );
  }

  // A fixed contract's cell in someone's row: a filled-in value once
  // that round has been played, an open selectable cell if it's still
  // legal AND it's the declaring player's own row, otherwise a blank
  // placeholder (another player's still-unplayed contract).
  Widget _fixedCell(ScoreRow row, ContractType type, bool isMine) {
    final value = row.fixedResults[type];
    if (value != null) return _valueCell(value);
    if (isMine && widget.legalTypes.contains(type)) {
      return _selectableCell(
        cellKey: ValueKey('contract_${type.name}'),
        onTap: () => widget.onDeclare(type),
      );
    }
    return const SizedBox(height: 44);
  }

  // Same idea for the 3 "+" slots, except only the next not-yet-filled
  // slot can ever be selectable — plus rounds are taken in order, unlike
  // fixed contracts which can be declared in any order.
  Widget _plusCell(ScoreRow row, int slot, bool isMine) {
    if (slot < row.plusResults.length) return _valueCell(row.plusResults[slot]);
    final isNextOpenSlot = slot == row.plusResults.length;
    if (isMine && isNextOpenSlot && widget.legalTypes.contains(ContractType.trump)) {
      return _selectableCell(
        cellKey: const ValueKey('contract_plus'),
        gold: true,
        onTap: () => setState(() => _pickingPlus = true),
      );
    }
    return const SizedBox(height: 44);
  }

  Widget _selectableCell({required Key cellKey, required VoidCallback onTap, bool gold = false}) {
    return Material(
      key: cellKey,
      color: gold ? KingColors.goldLight : KingColors.cream.withValues(alpha: 0.85),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Icon(Icons.add, size: 20, color: KingColors.inkNavy.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }

  Widget _valueCell(int value) {
    final negative = value < 0;
    return Container(
      height: 44,
      alignment: Alignment.center,
      color: negative ? Colors.red.shade400 : Colors.green.shade700,
      child: Text(
        value > 0 ? '+$value' : '$value',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _totalCell(int total) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      child: Text(
        '$total',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: KingColors.goldLight),
      ),
    );
  }

  // Tapping "+" swaps the score sheet for a circular suit picker
  // (diamonds/clubs/hearts/spades around a No Trump center) instead of
  // declaring immediately — identical behavior/keys to the grid this
  // replaces, so nothing about the trump-declaration flow itself changed.
  Widget _buildSuitPicker() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _pickingPlus = false),
              ),
              const Expanded(
                child: Text('Choose a suit', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(alignment: Alignment.topCenter, child: _suitButton(Suit.hearts)),
                  Align(alignment: Alignment.centerRight, child: _suitButton(Suit.diamonds)),
                  Align(alignment: Alignment.bottomCenter, child: _suitButton(Suit.clubs)),
                  Align(alignment: Alignment.centerLeft, child: _suitButton(Suit.spades)),
                  _noTrumpButton(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: KingColors.inkNavy,
                foregroundColor: KingColors.cream,
                disabledBackgroundColor: KingColors.inkNavy.withValues(alpha: 0.35),
                disabledForegroundColor: KingColors.cream.withValues(alpha: 0.6),
              ),
              key: const ValueKey('declare_button'),
              onPressed: !_hasChosenPlus
                  ? null
                  : () => widget.onDeclare(
                        ContractType.trump,
                        trumpSuit: _bezChosen ? null : _chosenTrumpSuit,
                      ),
              child: const Text('Declare'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suitButton(Suit suit) {
    final selected = _chosenTrumpSuit == suit && !_bezChosen;
    final isRed = suit == Suit.hearts || suit == Suit.diamonds;
    return GestureDetector(
      key: ValueKey('suit_${suit.name}'),
      onTap: () => setState(() {
        _chosenTrumpSuit = suit;
        _bezChosen = false;
      }),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: KingColors.cream,
          border: Border.all(color: selected ? KingColors.gold : KingColors.inkNavy, width: selected ? 3 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          suit.symbol,
          style: TextStyle(
            fontSize: 34,
            color: isRed ? KingColors.brickRed : KingColors.inkNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// The center of the diamond — deliberately not Joker's star/joker-card
  /// icon: a plain "NT" badge reads clearly as "No Trump" without
  /// borrowing another app's iconography.
  Widget _noTrumpButton() {
    return GestureDetector(
      key: const ValueKey('contract_no_trump'),
      onTap: () => setState(() {
        _bezChosen = true;
        _chosenTrumpSuit = null;
      }),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bezChosen ? KingColors.inkNavy : KingColors.cream,
          border: Border.all(color: _bezChosen ? KingColors.gold : KingColors.inkNavy, width: _bezChosen ? 3 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          'NT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _bezChosen ? KingColors.cream : KingColors.inkNavy,
          ),
        ),
      ),
    );
  }
}
