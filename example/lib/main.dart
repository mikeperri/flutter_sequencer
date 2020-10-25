import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_sequencer/global_state.dart';
import 'package:flutter_sequencer/models/sample_descriptor.dart';

import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/instrument.dart';
import 'package:flutter_sequencer/track.dart';

import 'components/drum_machine/drum_machine.dart';
import 'components/position_view.dart';
import 'components/step_count_selector.dart';
import 'components/tempo_selector.dart';
import 'components/track_selector.dart';
import 'components/transport.dart';
import 'models/project_state.dart';
import 'models/step_sequencer_state.dart';
import 'constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  final sequence = Sequence(tempo: INITIAL_TEMPO, endBeat: INITIAL_STEP_COUNT.toDouble());
  Map<int, StepSequencerState> trackStepSequencerStates = {};
  List<Track> tracks = [];
  Map<int, double> trackVolumes = {};
  Track selectedTrack;
  Ticker ticker;
  double tempo = INITIAL_TEMPO;
  int stepCount = INITIAL_STEP_COUNT;
  double position = 0.0;
  bool isPlaying = false;
  bool isLooping = INITIAL_IS_LOOPING;

  @override
  void initState() {
    super.initState();

    GlobalState().setKeepEngineRunning(true);

    final instruments = [
      Sf2Instrument(path: "assets/sf2/TR-808.sf2", isAsset: true),
      SfzInstrument(path: "assets/sfz/SplendidGrandPiano.sfz", isAsset: true),
      SamplerInstrument(
        id: "80's FM Bass",
        sampleDescriptors: [
          SampleDescriptor(filename: "assets/wav/D3.wav", isAsset: true, noteNumber: 62),
          SampleDescriptor(filename: "assets/wav/F3.wav", isAsset: true, noteNumber: 65),
          SampleDescriptor(filename: "assets/wav/G#3.wav", isAsset: true, noteNumber: 68),
        ]
      )
    ];

    sequence.createTracks(instruments).then((tracks) {
      this.tracks = tracks;
      tracks.forEach((track) {
        trackVolumes[track.id] = 0.0;
        trackStepSequencerStates[track.id] = StepSequencerState();
      });

      setState(() {

        this.selectedTrack = tracks[0];
      });
    });

    ticker = this.createTicker((Duration elapsed) {
      setState(() {

        tempo = sequence.getTempo();
        position = sequence.getBeat();
        isPlaying = sequence.getIsPlaying();

        tracks.forEach((track) {
          trackVolumes[track.id] = track.getVolume();
        });
      });
    });
    ticker.start();
  }

  handleTogglePlayPause() {
    if (isPlaying) {
      sequence.pause();
    } else {
      sequence.play();
    }
  }

  handleStop() {
    sequence.stop();
  }

  handleSetLoop(bool nextIsLooping) {
    if (nextIsLooping) {
      sequence.setLoop(0, stepCount.toDouble());
    } else {
      sequence.unsetLoop();
    }

    setState(() {
      isLooping = nextIsLooping;
    });
  }

  handleToggleLoop() {
    final nextIsLooping = !isLooping;

    handleSetLoop(nextIsLooping);
  }

  handleStepCountChange(int nextStepCount) {
    if (nextStepCount < 1) return;

    sequence.setEndBeat(nextStepCount.toDouble());

    if (isLooping) {
      final nextLoopEndBeat = nextStepCount.toDouble();

      sequence.setLoop(0, nextLoopEndBeat);
    }

    setState(() {
      stepCount = nextStepCount;
      tracks.forEach((track) => syncTrack(track));
    });
  }

  handleTempoChange(double nextTempo) {
    if (nextTempo <= 0) return;
    sequence.setTempo(nextTempo);
  }

  handleTrackChange(Track nextTrack) {
    setState(() {
      selectedTrack = nextTrack;
    });
  }

  handleVolumeChange(double nextVolume) {
    selectedTrack.changeVolumeNow(volume: nextVolume);
  }

  handleVelocitiesChange(int trackId, int step, int noteNumber, double velocity) {
    final track = tracks.firstWhere((track) => track.id == trackId);

    trackStepSequencerStates[trackId].setVelocity(step, noteNumber, velocity);

    syncTrack(track);
  }

  syncTrack(track) {
    track.clearEvents();
    trackStepSequencerStates[track.id].iterateEvents((step, noteNumber, velocity) {
      if (step < stepCount) {
        track.addNote(
          noteNumber: noteNumber,
          velocity: velocity,
          startBeat: step.toDouble(),
          durationBeats: 1.0);
      }
    });
    track.syncBuffer();
  }

  loadProjectState(ProjectState projectState) {
    handleStop();

    trackStepSequencerStates[tracks[0].id] = projectState.drumState;
    trackStepSequencerStates[tracks[1].id] = projectState.pianoState;
    trackStepSequencerStates[tracks[2].id] = projectState.bassState;

    handleStepCountChange(projectState.stepCount);
    handleTempoChange(projectState.tempo);
    handleSetLoop(projectState.isLooping);

    syncTrack(tracks[0]);
    syncTrack(tracks[1]);
    syncTrack(tracks[2]);
  }

  handleReset() {
    loadProjectState(ProjectState.empty());
  }

  handleLoadDemo() {
    loadProjectState(ProjectState.demo());
  }

  Widget _getMainView() {
    if (selectedTrack == null) return Text('Loading...');

    final isDrumTrackSelected = selectedTrack == tracks[0];

    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Transport(
                isPlaying: isPlaying,
                isLooping: isLooping,
                onTogglePlayPause: handleTogglePlayPause,
                onStop: handleStop,
                onToggleLoop: handleToggleLoop,
              ),
              PositionView(position: position),
            ]
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StepCountSelector(stepCount: stepCount, onChange: handleStepCountChange),
              TempoSelector(
                selectedTempo: tempo,
                handleChange: handleTempoChange,
              ),
            ],
          ),
          TrackSelector(
            tracks: tracks,
            selectedTrack: selectedTrack,
            handleChange: handleTrackChange,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MaterialButton(
                child: Text('Reset'),
                onPressed: handleReset,
              ),
              MaterialButton(
                child: Text('Load Demo'),
                onPressed: handleLoadDemo,
              ),
            ]
          ),
          DrumMachineWidget(
            track: selectedTrack,
            stepCount: stepCount,
            currentStep: position.floor(),
            rowLabels: isDrumTrackSelected ? ROW_LABELS_DRUMS : ROW_LABELS_PIANO,
            columnPitches: isDrumTrackSelected ? ROW_PITCHES_DRUMS : ROW_PITCHES_PIANO,
            volume: trackVolumes[selectedTrack.id] ?? 0.0,
            stepSequencerState: trackStepSequencerStates[selectedTrack.id],
            handleVolumeChange: handleVolumeChange,
            handleVelocitiesChange: handleVelocitiesChange,
          ),
        ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme:
        ThemeData(
          colorScheme: ColorScheme.dark(),
          textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.white)
        ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Drum machine example')),
        body: _getMainView(),
      ),
    );
  }
}
