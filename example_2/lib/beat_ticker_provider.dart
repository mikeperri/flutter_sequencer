import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sequencer/global_state.dart';
import 'package:flutter_sequencer/models/instrument.dart';
import 'package:flutter_sequencer/models/sfz.dart';
import 'package:flutter_sequencer/sequence.dart';
import 'package:flutter_sequencer/sequence_controller.dart';

class BeatCounter extends StatefulWidget {
  const BeatCounter({Key? key}) : super(key: key);

  @override
  _BeatCounterState createState() => _BeatCounterState();
}

class DummyInstrument extends Instrument {
  DummyInstrument(String idOrPath) : super(idOrPath, false);
}

class _BeatCounterState extends State<BeatCounter>
    with SingleTickerProviderStateMixin {
  late SequenceController _sequenceController;
  late Sequence _sequence;

  final instruments = [
    RuntimeSfzInstrument(
        id: "Generated Synth",
        // This SFZ doesn't use any sample files, so just put "/" as a placeholder.
        sampleRoot: "/",
        isAsset: false,
        // Based on the Unison Oscillator example here:
        // https://sfz.tools/sfizz/quick_reference#unison-oscillator
        sfz: Sfz(groups: [
          SfzGroup(regions: [
            SfzRegion(sample: "*saw", otherOpcodes: {
              "oscillator_multi": "5",
              "oscillator_detune": "50",
            })
          ])
        ])),
  ];

  @override
  void initState() {
    super.initState();

    GlobalState().setKeepEngineRunning(true);

    _setupSequence();
    _sequenceController = SequenceController(vsync: this, sequence: _sequence);

    // start playing after a second
    Timer(Duration(seconds: 1), () {
      _sequence.play();
    });
  }

  void _setupSequence() {
    _sequence = Sequence(tempo: 80, endBeat: 7);
    _sequence.createTracks(instruments).then((tracks) => tracks.first
        .addNote(noteNumber: 64, velocity: 1, startBeat: 0, durationBeats: 1));
    _sequence.loopState = LoopState.AfterLoopEnd;
    _sequence.setLoop(0, 7);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: StreamBuilder<SequenceState>(
          stream: _sequenceController.listenForChanges().distinctBeatPosition(),
          builder: (context, sequencerState) {
            final beat = (sequencerState.data?.beat.toInt() ?? 0) + 1;
            return Text(
              '$beat',
              style: Theme.of(context).textTheme.headline4,
            );
          },
        ),
      ),
    );
  }
}
