import 'package:flutter/scheduler.dart';
import 'package:flutter_sequencer/sequence.dart';

class SequenceController {
  SequenceController({
    required TickerProvider vsync,
    required this.sequence,
    required this.onBeatChanged,
  }) : beatPositionOnLastTick = sequence.getBeat().toInt() {
    this._ticker = vsync.createTicker(_tick);
    this._ticker?.start();
  }

  Ticker? _ticker;
  Sequence sequence;
  int beatPositionOnLastTick;
  Function(int) onBeatChanged;

  void _tick(Duration elapsed) {
    int currentBeatPosition = sequence.getBeat().toInt();
    if (beatPositionOnLastTick != currentBeatPosition) {
      onBeatChanged(currentBeatPosition);
      beatPositionOnLastTick = currentBeatPosition;
    }
  }
}
