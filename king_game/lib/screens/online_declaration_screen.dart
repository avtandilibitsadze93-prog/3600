import 'package:flutter/material.dart';

import '../game/online_game_client.dart';
import '../widgets/card_sort.dart';
import '../widgets/declaration_layout.dart';

class OnlineDeclarationScreen extends StatelessWidget {
  final OnlineGameClient client;
  const OnlineDeclarationScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return DeclarationLayout(
      legalTypes: client.legalDeclarations,
      onDeclare: client.declare,
      hand: sortedForDisplay(client.yourHand),
    );
  }
}
