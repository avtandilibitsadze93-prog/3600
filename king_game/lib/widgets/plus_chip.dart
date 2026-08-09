import 'package:flutter/material.dart';

import '../theme/king_theme.dart';

/// A suit/ბეზი choice for the "+" (plus/trump) declaration card, styled
/// explicitly rather than via the app-wide ChipTheme — this one sits on
/// a solid gold card (see DeclarationScreen/OnlineDeclarationScreen),
/// not the felt background every other chip theme assumption is built for.
class PlusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const PlusChip({super.key, required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: KingColors.cream,
      selectedColor: KingColors.inkNavy,
      labelStyle: TextStyle(
        color: selected ? KingColors.cream : KingColors.inkNavy,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: const BorderSide(color: KingColors.inkNavy, width: 1),
    );
  }
}
