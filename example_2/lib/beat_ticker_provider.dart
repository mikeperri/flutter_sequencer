import 'dart:async';

import 'package:example_2/sequence_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sequencer/global_state.dart';
import 'package:flutter_sequencer/models/instrument.dart';
import 'package:flutter_sequencer/models/sfz.dart';
import 'package:flutter_sequencer/sequence.dart';

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
  int beatNumber = 1;

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

    _sequence = Sequence(tempo: 80, endBeat: 7);
    _sequence.createTracks(instruments).then((tracks) => null);
    _sequence.loopState = LoopState.AfterLoopEnd;
    _sequence.setLoop(0, 7);
    _sequenceController = SequenceController(
        vsync: this,
        sequence: _sequence,
        onBeatChanged: (beatNumber) {
          setState(() {
            this.beatNumber = beatNumber + 1;
          });
        });

    /**
     * OR could do it this way via dart streams, could be more extendable:
     * _sequenceController.listenForChanges() // listen for changes in the sequence state (returns Stream<SequenceState>)
     *     .onBeatChanged(() {...}) // a function that takes a stream of SeqeunceState and returns the same. If the beat position changes, it called the function passed into it
     *     .onMyCustomStateChangeHandler() // it's possible for the user to manipulate the stream any way they want this way
     */

    // start playing after a second
    Timer(Duration(seconds: 1), () {
      _sequence.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Text(
          '$beatNumber',
          style: Theme.of(context).textTheme.headline4,
        ),
      ),
    );
  }
}
