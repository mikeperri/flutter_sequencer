import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/sequence_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:ui' as ui;

class MockSequence extends Mock implements Sequence {}

void tick(Duration duration) {
  // We don't bother running microtasks between these two calls
  // because we don't use Futures in these tests and so don't care.
  SchedulerBinding.instance!.handleBeginFrame(duration);
  SchedulerBinding.instance!.handleDrawFrame();
}

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance!.resetEpoch();
    ui.window.onBeginFrame = null;
    ui.window.onDrawFrame = null;
  });
  group('SequenceController', () {
    test('emits a SequenceState on a tick', () async {
      final sequence = MockSequence();
      final expectedSequenceState = SequenceState(
        isPlaying: true,
        tempo: 120,
        beat: 4,
        loopState: LoopState.Off,
      );

      when(() => sequence.getState()).thenReturn(expectedSequenceState);

      final sequenceController = SequenceController(
        vsync: const TestVSync(),
        sequence: sequence,
      );

      final sequenceStateStream = sequenceController.listenForChanges();

      final expectedResult =
          expectLater(sequenceStateStream, emits(expectedSequenceState));

      tick(Duration(seconds: 1));

      await expectedResult;
    });
  });
}
