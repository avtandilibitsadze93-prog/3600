import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import '../theme/king_theme.dart';

/// Same order the score table's columns use — cosmetic only, but keeps
/// the two grids feeling like the same "sheet" the player already knows
/// from [ScoreTableScreen].
const List<ContractType> _fixedContractOrder = [
  ContractType.king,
  ContractType.queen,
  ContractType.jack,
  ContractType.noTricks,
  ContractType.noHearts,
  ContractType.lastTwo,
];

/// The declaring player's choice of contract, shown as a table/grid
/// instead of a scrolling list: every fixed contract they haven't used
/// yet this game is a live cell, everything they've already declared is
/// dimmed to show it can't be picked again. Tapping "+" swaps the grid
/// for a circular suit picker (diamonds/clubs/hearts/spades around a
/// No Trump center) instead of declaring immediately.
class ContractGridPicker extends StatefulWidget {
  final List<ContractType> legalTypes;
  final void Function(ContractType type, {Suit? trumpSuit}) onDeclare;

  const ContractGridPicker({super.key, required this.legalTypes, required this.onDeclare});

  @override
  State<ContractGridPicker> createState() => _ContractGridPickerState();
}

class _ContractGridPickerState extends State<ContractGridPicker> {
  bool _pickingPlus = false;
  Suit? _chosenTrumpSuit;
  bool _bezChosen = false;

  bool get _hasChosenPlus => _chosenTrumpSuit != null || _bezChosen;

  @override
  Widget build(BuildContext context) {
    return _pickingPlus ? _buildPlusPicker(context) : _buildGrid(context);
  }

  // A Column/Row of Expanded cells rather than a GridView: with 7 known,
  // fixed cells this divides the available space evenly and guarantees
  // every cell — including "+" — is always simultaneously visible and
  // tappable. A GridView here would lazily build only what's near the
  // viewport, and at the larger size this grid gets post-redesign, the
  // "+" cell (last in the list) could end up needing a scroll gesture
  // just to exist in the tree, breaking a plain tap.
  //
  // All 3 rows (2 of fixed contracts + the "+" row) use the same
  // Expanded flex, splitting whatever height is available evenly —
  // an earlier version gave "+" a fixed height instead, which on a
  // real phone's aspect ratio starved the two fixed-contract rows
  // down to single-digit pixels tall (confirmed via a widget test
  // reading actual RenderBox sizes, not just "no overflow exception").
  Widget _buildGrid(BuildContext context) {
    final plusLegal = widget.legalTypes.contains(ContractType.trump);
    Widget cellFor(ContractType type) => _ContractCell(
          key: ValueKey('contract_${type.name}'),
          label: type.englishName,
          enabled: widget.legalTypes.contains(type),
          onTap: () => widget.onDeclare(type),
        );
    Widget rowOf(List<Widget> cells) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                for (final cell in cells)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: cell,
                    ),
                  ),
              ],
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rowOf([for (final type in _fixedContractOrder.sublist(0, 3)) cellFor(type)]),
        rowOf([for (final type in _fixedContractOrder.sublist(3, 6)) cellFor(type)]),
        rowOf([
          _ContractCell(
            key: const ValueKey('contract_plus'),
            label: '+',
            enabled: plusLegal,
            gold: true,
            onTap: () => setState(() => _pickingPlus = true),
          ),
        ]),
      ],
    );
  }

  Widget _buildPlusPicker(BuildContext context) {
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

class _ContractCell extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool gold;
  final VoidCallback onTap;

  const _ContractCell({super.key, required this.label, required this.enabled, required this.onTap, this.gold = false});

  @override
  Widget build(BuildContext context) {
    final baseColor = gold ? KingColors.goldLight : KingColors.cream;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: baseColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? onTap : null,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KingColors.inkNavy,
                  fontWeight: gold ? FontWeight.bold : FontWeight.w600,
                  fontSize: gold ? 26 : 17,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
