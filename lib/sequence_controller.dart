import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_sequencer/sequence.dart';

class SequenceController {
  SequenceController({
    required TickerProvider vsync,
    required this.sequence,
  }) {
    _ticker = vsync.createTicker(_tick);
    _ticker?.start();
  }

  Ticker? _ticker;
  Sequence sequence;
  final StreamController<SequenceState> _streamController =
      StreamController.broadcast();

  void _updateSequenceState() {
    _streamController.add(sequence.getState());
  }

  /// Listen for changes to the sequence.
  ///
  /// Emits a new [SequenceState] every tick.
  Stream<SequenceState> listenForChanges() {
    return _streamController.stream;
  }

  void _tick(Duration elapsed) {
    _updateSequenceState();
  }

  void dispose() {
    _ticker?.dispose();
  }
}

extension SequenceStateObservers on Stream<SequenceState> {
  /// Only emits a SequenceState event when the current beat position has
  /// changed.
  ///
  /// The beat increments checked here are integers (e.g. from 4 to 5).
  Stream<SequenceState> distinctBeatPosition() {
    return distinct(
      (previous, current) => previous.beat.toInt() == current.beat.toInt(),
    );
  }
}
