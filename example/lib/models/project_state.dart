import 'package:flutter_sequencer_example/constants.dart';

import 'step_sequencer_state.dart';

class ProjectState {
  ProjectState({
    required this.stepCount,
    required this.tempo,
    required this.isLooping,
    required this.drumState,
    required this.pianoState,
    required this.bassState,
    required this.synthState,
  });

  final int stepCount;
  final double tempo;
  final bool isLooping;
  final StepSequencerState drumState;
  final StepSequencerState pianoState;
  final StepSequencerState bassState;
  final StepSequencerState synthState;

  static ProjectState empty() {
    return ProjectState(
      stepCount: INITIAL_STEP_COUNT,
      tempo: INITIAL_TEMPO,
      isLooping: INITIAL_IS_LOOPING,
      drumState: StepSequencerState(),
      pianoState: StepSequencerState(),
      bassState: StepSequencerState(),
      synthState: StepSequencerState(),
    );
  }

  static ProjectState demo() {
    final drumState = StepSequencerState();

    drumState.setVelocity(0, 44, 0.75);

    drumState.setVelocity(2, 44, 0.5);
    drumState.setVelocity(3, 44, 0.5);
    drumState.setVelocity(4, 44, 0.75);

    drumState.setVelocity(6, 44, 1.0);

    drumState.setVelocity(8, 56, 0.75);

    drumState.setVelocity(10, 56, 0.75);

    drumState.setVelocity(12, 44, 0.75);

    drumState.setVelocity(14, 44, 0.5);
    drumState.setVelocity(15, 44, 0.5);
    drumState.setVelocity(16, 44, 0.5);

    drumState.setVelocity(18, 44, 0.75);

    drumState.setVelocity(20, 56, 0.75);

    drumState.setVelocity(22, 56, 0.75);

    drumState.setVelocity(24, 36, 0.75);
    drumState.setVelocity(24, 44, 0.75);

    drumState.setVelocity(26, 38, 0.3);
    drumState.setVelocity(27, 38, 0.4);
    drumState.setVelocity(28, 38, 0.5);
    drumState.setVelocity(29, 38, 0.6);
    drumState.setVelocity(30, 36, 0.75);
    drumState.setVelocity(30, 44, 0.75);

    drumState.setVelocity(32, 38, 0.4);
    drumState.setVelocity(33, 38, 0.5);
    drumState.setVelocity(34, 38, 0.6);
    drumState.setVelocity(35, 38, 0.7);
    drumState.setVelocity(36, 36, 0.8);
    drumState.setVelocity(36, 44, 0.8);

    drumState.setVelocity(38, 38, 0.5);
    drumState.setVelocity(39, 38, 0.6);
    drumState.setVelocity(40, 38, 0.7);
    drumState.setVelocity(41, 38, 0.8);

    drumState.setVelocity(42, 36, 1.0);
    drumState.setVelocity(42, 56, 1.0);
    drumState.setVelocity(43, 44, 0.4);
    drumState.setVelocity(44, 44, 0.5);
    drumState.setVelocity(45, 44, 0.6);
    drumState.setVelocity(46, 44, 0.7);
    drumState.setVelocity(47, 44, 0.8);

    final pianoState = StepSequencerState();

    pianoState.setVelocity(0, 67, 1.0);

    pianoState.setVelocity(2, 60, 0.75);
    pianoState.setVelocity(3, 62, 0.75);
    pianoState.setVelocity(4, 64, 0.75);
    pianoState.setVelocity(5, 65, 0.75);
    pianoState.setVelocity(6, 64, 0.75);
    pianoState.setVelocity(6, 67, 1.0);

    pianoState.setVelocity(8, 60, 1.0);

    pianoState.setVelocity(10, 60, 1.0);

    pianoState.setVelocity(12, 65, 0.75);
    pianoState.setVelocity(12, 69, 1.0);

    pianoState.setVelocity(14, 65, 0.75);
    pianoState.setVelocity(15, 67, 0.75);
    pianoState.setVelocity(16, 69, 0.75);
    pianoState.setVelocity(17, 71, 0.75);
    pianoState.setVelocity(18, 67, 0.75);
    pianoState.setVelocity(18, 72, 1.0);

    pianoState.setVelocity(20, 60, 1.0);

    pianoState.setVelocity(22, 60, 1.0);

    pianoState.setVelocity(24, 60, 0.75);
    pianoState.setVelocity(24, 65, 0.9);

    pianoState.setVelocity(26, 67, 0.4);
    pianoState.setVelocity(27, 65, 0.5);
    pianoState.setVelocity(28, 64, 0.6);
    pianoState.setVelocity(29, 62, 0.7);
    pianoState.setVelocity(30, 60, 0.75);
    pianoState.setVelocity(30, 64, 0.9);

    pianoState.setVelocity(32, 65, 0.3);
    pianoState.setVelocity(33, 64, 0.4);
    pianoState.setVelocity(34, 62, 0.5);
    pianoState.setVelocity(35, 60, 0.6);
    pianoState.setVelocity(36, 59, 0.75);
    pianoState.setVelocity(36, 62, 0.9);

    pianoState.setVelocity(38, 64, 0.4);
    pianoState.setVelocity(39, 62, 0.5);
    pianoState.setVelocity(40, 60, 0.6);
    pianoState.setVelocity(41, 59, 0.7);
    pianoState.setVelocity(42, 60, 0.9);
    pianoState.setVelocity(42, 64, 0.9);
    pianoState.setVelocity(42, 67, 0.9);
    pianoState.setVelocity(42, 72, 0.9);
    pianoState.setVelocity(43, 72, 0.9);
    pianoState.setVelocity(44, 72, 0.9);
    pianoState.setVelocity(45, 60, 0.9);
    pianoState.setVelocity(46, 72, 0.9);
    pianoState.setVelocity(47, 60, 0.9);

    final bassState = StepSequencerState();
    final synthState = StepSequencerState();

    return ProjectState(
      stepCount: 48,
      tempo: 480,
      isLooping: true,
      pianoState: pianoState,
      drumState: drumState,
      bassState: bassState,
      synthState: synthState,
    );
  }
}
