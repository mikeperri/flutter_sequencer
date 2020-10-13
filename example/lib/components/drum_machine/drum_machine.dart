import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_sequencer/track.dart';

import 'package:flutter_sequencer_example/models/step_sequencer_state.dart';

import 'volume_slider.dart';
import 'grid/grid.dart';

class DrumMachineWidget extends StatefulWidget {
  const DrumMachineWidget({
    Key key,
    @required this.track,
    @required this.stepCount,
    @required this.currentStep,
    @required this.rowLabels,
    @required this.columnPitches,
    @required this.volume,
    @required this.stepSequencerState,
    @required this.handleVolumeChange,
    @required this.handleVelocitiesChange,
  }) : super(key: key);

  final Track track;
  final int stepCount;
  final int currentStep;
  final List<String> rowLabels;
  final List<int> columnPitches;
  final double volume;
  final StepSequencerState stepSequencerState;
  final Function(double) handleVolumeChange;
  final Function(int, int, int, double) handleVelocitiesChange;

  @override
  _DrumMachineWidgetState createState() => _DrumMachineWidgetState();
}

class _DrumMachineWidgetState extends State<DrumMachineWidget> with SingleTickerProviderStateMixin {
  Ticker ticker;

  @override
  void dispose() {
    super.dispose();
  }

  double getVelocity(int step, int col) {
    return widget.stepSequencerState.getVelocity(step, widget.columnPitches[col]);
  }

  void handleVelocityChange(int col, int step, double velocity) {
    widget.handleVelocitiesChange(widget.track.id, step, widget.columnPitches[col], velocity);
  }

  void handleVolumeChange(double nextVolume) {
    widget.handleVolumeChange(nextVolume);
  }

  void handleNoteOn(int col) {
    widget.track.startNoteNow(pitch: widget.columnPitches[col], velocity: .75);
  }

  void handleNoteOff(int col) {
    widget.track.stopNoteNow(pitch: widget.columnPitches[col]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
      decoration: BoxDecoration(
        color: Colors.black54,
      ),
      child: Column(
        children: [
          VolumeSlider(
            value: widget.volume,
            onChange: handleVolumeChange
          ),
          Grid(
            columnLabels: widget.rowLabels,
            getVelocity: getVelocity,
            stepCount: widget.stepCount,
            currentStep: widget.currentStep,
            onChange: handleVelocityChange,
            onNoteOn: handleNoteOn,
            onNoteOff: handleNoteOff
          ),
        ],
      )
    );
  }
}

