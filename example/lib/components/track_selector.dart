import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sequencer/track.dart';

class TrackSelector extends StatelessWidget {
  TrackSelector({
    this.selectedTrack,
    this.tracks,
    this.handleChange,
  });

  final Track selectedTrack;
  final List<Track> tracks;
  final Function(Track nextTrack) handleChange;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Track>(
      value: selectedTrack,
      onChanged: handleChange,
      items: tracks.map((track) {
        return DropdownMenuItem<Track>(
          value: track,
          child: Text(track.instrument.displayName)
        );
      }).toList()
    );
  }
}
