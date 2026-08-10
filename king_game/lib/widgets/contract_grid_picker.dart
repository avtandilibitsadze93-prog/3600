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

  Widget _buildGrid(BuildContext context) {
    final plusLegal = widget.legalTypes.contains(ContractType.trump);
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: [
        for (final type in _fixedContractOrder)
          _ContractCell(
            key: ValueKey('contract_${type.name}'),
            label: type.englishName,
            enabled: widget.legalTypes.contains(type),
            onTap: () => widget.onDeclare(type),
          ),
        _ContractCell(
          key: const ValueKey('contract_plus'),
          label: '+',
          enabled: plusLegal,
          gold: true,
          onTap: () => setState(() => _pickingPlus = true),
        ),
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
              width: 190,
              height: 190,
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
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: KingColors.cream,
          border: Border.all(color: selected ? KingColors.gold : KingColors.inkNavy, width: selected ? 3 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          suit.symbol,
          style: TextStyle(
            fontSize: 26,
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bezChosen ? KingColors.inkNavy : KingColors.cream,
          border: Border.all(color: _bezChosen ? KingColors.gold : KingColors.inkNavy, width: _bezChosen ? 3 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          'NT',
          style: TextStyle(
            fontSize: 15,
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
                  fontSize: gold ? 22 : 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
