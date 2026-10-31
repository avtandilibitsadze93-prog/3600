import 'package:flutter/material.dart';
import 'package:king_game_engine/king_game_engine.dart';

import 'playing_card_widget.dart';

/// The ace-draw reveal's card pile: fans out in the center of the table
/// as each dealt card is revealed, then settles into the final
/// declare-order list once the deciding Ace has shown. Shared by the
/// online and local pass-and-play ace-draw screens — both just hand it
/// the same [AceDraw]/[AceDrawCard] data the engine already produced.
class AceDrawPile extends StatelessWidget {
  final List<AceDrawCard> revealed;
  final bool done;
  final List<int> seating;
  final String Function(int seat) nameOf;

  const AceDrawPile({
    super.key,
    required this.revealed,
    required this.done,
    required this.seating,
    required this.nameOf,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < revealed.length; i++)
                      Transform.translate(
                        offset: Offset((i - (revealed.length - 1) / 2) * 11, 0),
                        child: Transform.rotate(
                          angle: (i - (revealed.length - 1) / 2) * 0.1,
                          child: SizedBox(
                            width: 56,
                            height: 80,
                            child: PlayingCardWidget(card: revealed[i].card, enabled: false),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (done) ...[
                const SizedBox(height: 16),
                for (var i = 0; i < seating.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('${i + 1}. ${nameOf(seating[i])}', style: const TextStyle(fontSize: 16)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
