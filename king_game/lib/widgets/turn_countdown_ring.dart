import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Same base move-clock length the server hands out per turn — kept in
/// sync manually since the client never needs to know the server's
/// exact configured value to render a plausible countdown, only this
/// shared constant used to turn a turnDeadline timestamp into a
/// fraction-elapsed for the ring's sweep.
const kTurnTimeLimit = Duration(seconds: 20);

const _trackGreen = Color(0xFF3FA34D);
const _fillYellow = Color(0xFFE0B93A);
const _trackRedDim = Color(0xFF5A2426);
const _fillRed = Color(0xFFCF4B4B);

/// Wraps [child] (a seat's avatar) with an animated countdown ring while
/// [turnDeadline] is set: a green track fills with yellow as the base
/// move clock (turnTimeLimit) runs out, then switches fully red — still
/// counting down, now against the shared whole-game time bank — once
/// [bankDeadline] also appears. Purely decorative: the server alone
/// decides whose turn it is and when it actually times out (see
/// Room._startNewTurn/_onTurnTimeExpired/_onBankTimeExpired) — this just
/// renders whatever deadline it was last told about.
class TurnCountdownRing extends StatefulWidget {
  final DateTime? turnDeadline;
  final DateTime? bankDeadline;
  final Widget child;
  final double radius;

  const TurnCountdownRing({
    super.key,
    required this.turnDeadline,
    required this.bankDeadline,
    required this.child,
    required this.radius,
  });

  @override
  State<TurnCountdownRing> createState() => _TurnCountdownRingState();
}

class _TurnCountdownRingState extends State<TurnCountdownRing> {
  Timer? _ticker;
  DateTime? _trackedBankDeadline;
  DateTime? _bankPhaseStart;

  @override
  void initState() {
    super.initState();
    _syncBankPhaseStart();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant TurnCountdownRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBankPhaseStart();
  }

  // The server never tells us how big THIS bank countdown's total span
  // is (only its deadline) — remembering the moment it first appeared
  // locally is precise enough for a decorative ring's fill fraction, and
  // avoids a wire field that exists purely for cosmetics.
  void _syncBankPhaseStart() {
    final bd = widget.bankDeadline;
    if (bd == null) {
      _trackedBankDeadline = null;
      _bankPhaseStart = null;
    } else if (_trackedBankDeadline != bd) {
      _trackedBankDeadline = bd;
      _bankPhaseStart = DateTime.now();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turnDeadline = widget.turnDeadline;
    if (turnDeadline == null) return widget.child;

    final now = DateTime.now();
    final bankDeadline = widget.bankDeadline;

    late final double fraction;
    late final Color track;
    late final Color fill;
    late final int secondsLeft;

    if (bankDeadline != null) {
      final total = bankDeadline.difference(_bankPhaseStart ?? now);
      final remaining = bankDeadline.difference(now);
      fraction = total.inMilliseconds <= 0
          ? 1.0
          : (1 - remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
      track = _trackRedDim;
      fill = _fillRed;
      secondsLeft = remaining.isNegative ? 0 : (remaining.inMilliseconds / 1000).ceil();
    } else {
      final remaining = turnDeadline.difference(now);
      fraction =
          (1 - remaining.inMilliseconds / kTurnTimeLimit.inMilliseconds).clamp(0.0, 1.0);
      track = _trackGreen;
      fill = _fillYellow;
      secondsLeft = remaining.isNegative ? 0 : (remaining.inMilliseconds / 1000).ceil();
    }

    final size = widget.radius * 2 + 10;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(fraction: fraction, track: track, fill: fill),
          ),
          widget.child,
          Positioned(
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8)),
              child: Text(
                '$secondsLeft',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color track;
  final Color fill;

  _RingPainter({required this.fraction, required this.track, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 3.0;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction <= 0) return;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.track != track || oldDelegate.fill != fill;
}
