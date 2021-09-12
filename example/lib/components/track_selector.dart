import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sequencer/track.dart';

class TrackSelector extends StatelessWidget {
  TrackSelector({
    required this.selectedTrack,
    required this.tracks,
    required this.handleChange,
  });

  final Track? selectedTrack;
  final List<Track> tracks;
  final void Function(Track? nextTrack) handleChange;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Track>(
        value: selectedTrack,
        onChanged: handleChange,
        items: tracks.map((track) {
          return DropdownMenuItem<Track>(
              value: track, child: Text(track.instrument.displayName));
        }).toList());
  }
}
