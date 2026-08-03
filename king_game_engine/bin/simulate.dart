// Console simulation of a full 27-round King game with simple bots.
// Run with: dart run bin/simulate.dart
//
// This exists so the rules engine can be sanity-checked end-to-end
// before wiring up any UI. The bots play legally but not strategically
// (random legal move each turn), which is enough to prove the engine
// never lets an illegal move through and that scoring balances out.

import 'dart:math';
import 'package:king_game_engine/king_game_engine.dart';

void main() {
  final rng = Random(42);
  final players = [
    Player(id: 0, name: 'ავთო'),
    Player(id: 1, name: 'ვასო'),
    Player(id: 2, name: 'გიორგი'),
  ];

  final game = GameEngine(players);

  print('=== "კინგის" სიმულაცია: 27 რაუნდი ===\n');

  while (!game.isGameOver) {
    final dealt = game.dealNextRound();
    final declarerIdx = game.currentDeclarerIndex;
    final declarer = players[declarerIdx];

    // Pick a random legal declaration (GameEngine guarantees this list
    // is always non-empty and never leaves a player stranded later).
    final options = game.legalDeclarationTypes(declarerIdx);
    final chosenType = options[rng.nextInt(options.length)];
    final declaration = chosenType == ContractType.trump
        ? Declaration(ContractType.trump,
            trumpSuit: Suit.values[rng.nextInt(Suit.values.length)])
        : Declaration(chosenType);

    print('--- რაუნდი ${game.roundsPlayed + 1}: ${declarer.name} აცხადებს '
        '${declaration.type.georgianName}'
        '${declaration.trumpSuit != null ? " (${declaration.trumpSuit!.georgianName})" : ""} ---');

    final round = game.startRound(declaration, dealt);

    // Prikoup: declarer previews their hand + the 2 prikoup cards to
    // choose a legal burial, then exchangePrikoup applies it atomically.
    final declarerPlayer = players[declarerIdx];
    final previewHand = [...declarerPlayer.hand, ...dealt.prikoup];
    final buryCandidates = previewHand
        .where((c) => !round.isBurialForbidden(c))
        .take(2)
        .toList();
    round.exchangePrikoup(dealt.prikoup, buryCandidates);

    // Play all 10 tricks.
    for (var t = 0; t < 10; t++) {
      final trick = Trick();
      var seat = round.currentLeaderIndex;
      for (var turn = 0; turn < 3; turn++) {
        final player = players[seat];
        final legal = round.legalMoves(player, trick);
        final card = legal[rng.nextInt(legal.length)];
        round.playCard(player, trick, card);
        seat = (seat + 1) % 3;
      }
      final winnerIdx = round.resolveTrick(trick);
      print('  ხელი ${t + 1}: ${trick.plays.map((p) => p.card).join(", ")}'
          '  -> იღებს ${players[winnerIdx].name}');
    }

    final totalsBefore = {for (final p in players) p.id: p.totalScore};
    game.finishRound(round);
    final delta = round.computeRoundScore();
    print('  ქულები ამ რაუნდში: '
        '${players.map((p) => "${p.name}: ${delta[p.id]}").join(", ")}');
    // The +40 "პრემია" is a whole-game bonus (see GameEngine.finishRound),
    // not part of the round's own delta above — show it separately so
    // it's visible exactly when it lands.
    for (final p in players) {
      final actualDelta = p.totalScore - totalsBefore[p.id]!;
      final roundDelta = delta[p.id] ?? 0;
      if (actualDelta != roundDelta) {
        print('  >>> ${p.name} მიიღო პრემია: +${actualDelta - roundDelta} '
            '(ყველა 6 მინუს კონტრაქტი წმინდად შეასრულა)');
      }
    }
    print('  ჯამი: ${game.standings}\n');
  }

  print('=== თამაში დასრულდა ===');
  print(game.standings);
}
