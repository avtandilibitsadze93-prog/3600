import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../widgets/card_sort.dart';
import '../widgets/declaration_layout.dart';

/// Built off the exact same [DeclarationLayout]/[ContractGridPicker]
/// widgets as [OnlineDeclarationScreen] so testing locally shows the
/// same big-grid declaration screen a real online player would see.
class DeclarationScreen extends StatelessWidget {
  final GameController controller;
  const DeclarationScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DeclarationLayout(
      legalTypes: controller.legalDeclarations,
      onDeclare: controller.declare,
      hand: sortedForDisplay(controller.activePlayer.hand),
    );
  }
}
