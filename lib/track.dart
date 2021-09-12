import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'constants.dart';
import 'models/instrument.dart';
import 'models/events.dart';
import 'native_bridge.dart';
import 'sequence.dart';

/// Represents a track. A track belongs to a sequence and has a collection of
/// events.
class Track {
  final Sequence sequence;
  final int id;
  final Instrument instrument;
  final events = <SchedulerEvent>[];
  int lastFrameSynced = 0;

  Track._withId(
      {required this.sequence, required this.id, required this.instrument});

  /// Creates a track in the underlying sequencer engine.
  static Future<Track?> build(
      {required Sequence sequence, required Instrument instrument}) async {
    int? id;

    if (instrument is Sf2Instrument) {
      id = await NativeBridge.addTrackSf2(
          instrument.idOrPath, instrument.isAsset, instrument.presetIndex);
    } else if (instrument is SfzInstrument) {
      final sfzFile = File(instrument.idOrPath);
      String? normalizedSfzPath;

      if (instrument.isAsset) {
        final normalizedSfzDir =
            await NativeBridge.normalizeAssetDir(sfzFile.parent.path);

        if (normalizedSfzDir == null)
          throw Exception(
              'Could not normalize asset dir for ${sfzFile.parent.path}');
        normalizedSfzPath = '$normalizedSfzDir/${p.basename(sfzFile.path)}';
      } else {
        normalizedSfzPath = sfzFile.path;
      }

      id = await NativeBridge.addTrackSfz(
          normalizedSfzPath, instrument.tuningPath);
    } else if (instrument is RuntimeSfzInstrument) {
      final sfzContent = instrument.sfz.buildString();
      String? normalizedSampleRoot;

      if (instrument.isAsset) {
        normalizedSampleRoot =
            await NativeBridge.normalizeAssetDir(instrument.sampleRoot);

        if (normalizedSampleRoot == null)
          throw Exception(
              'Could not normalize asset dir for ${instrument.sampleRoot}');
      } else {
        normalizedSampleRoot = instrument.sampleRoot;
      }

      // Sfizz uses the parent path of this (line 73 of Parser.cpp)
      final fakeSfzDir = '$normalizedSampleRoot/does_not_exist.sfz';

      id = await NativeBridge.addTrackSfzString(
          fakeSfzDir, sfzContent, instrument.tuningString);
    } else if (instrument is AudioUnitInstrument) {
      id = await NativeBridge.addTrackAudioUnit(instrument.idOrPath);
    } else {
      throw Exception('Instrument not recognized');
    }

    if (id == -1) return null;

    return Track._withId(
      sequence: sequence,
      id: id!,
      instrument: instrument,
    );
  }

  /// Handles a Note On event on this track immediately.
  /// The event will not be added to this track's events.
  void startNoteNow({required int noteNumber, required double velocity}) {
    final nextBeat = sequence.getBeat();
    final event = MidiEvent.ofNoteOn(
        beat: nextBeat,
        noteNumber: noteNumber,
        velocity: _velocityToMidi(velocity));

    NativeBridge.handleEventsNow(
        id, [event], Sequence.globalState.sampleRate!, sequence.tempo);
  }

  /// Handles a Note Off event on this track immediately.
  /// The event will not be added to this track's events.
  void stopNoteNow({required int noteNumber}) {
    final nextBeat = sequence.getBeat();
    final event = MidiEvent.ofNoteOff(beat: nextBeat, noteNumber: noteNumber);

    NativeBridge.handleEventsNow(
        id, [event], Sequence.globalState.sampleRate!, sequence.tempo);
  }

  /// Handles a MIDI CC event on this track immediately.
  /// The event will not be added to this track's events.
  void midiCCNow({required int ccNumber, required int ccValue}) {
    final nextBeat = sequence.getBeat();
    final event =
        MidiEvent.cc(beat: nextBeat, ccNumber: ccNumber, ccValue: ccValue);

    NativeBridge.handleEventsNow(
        id, [event], Sequence.globalState.sampleRate!, sequence.tempo);
  }

  /// Handles a MIDI pitch bend event on this track immediately.
  /// The event will not be added to this track's events.
  void midiPitchBendNow({required double value}) {
    final nextBeat = sequence.getBeat();
    final event = MidiEvent.pitchBend(beat: nextBeat, value: value);

    NativeBridge.handleEventsNow(
        id, [event], Sequence.globalState.sampleRate!, sequence.tempo);
  }

  /// Handles a Volume Change event on this track immediately.
  /// The event will not be added to this track's events.
  void changeVolumeNow({required double volume}) {
    final nextBeat = sequence.getBeat();
    final event = VolumeEvent(beat: nextBeat, volume: volume);

    NativeBridge.handleEventsNow(
        id, [event], Sequence.globalState.sampleRate!, sequence.tempo);
  }

  /// Adds a Note On and Note Off event to this track.
  /// This does not sync the events to the backend.
  void addNote(
      {required int noteNumber,
      required double velocity,
      required double startBeat,
      required double durationBeats}) {
    addNoteOn(
      noteNumber: noteNumber,
      velocity: velocity,
      beat: startBeat,
    );

    addNoteOff(
      noteNumber: noteNumber,
      beat: startBeat + durationBeats,
    );
  }

  /// Adds a Note On event to this track.
  /// This does not sync the events to the backend.
  void addNoteOn(
      {required int noteNumber,
      required double velocity,
      required double beat}) {
    assert(velocity > 0 && velocity <= 1);

    final noteOnEvent = MidiEvent.ofNoteOn(
      beat: beat,
      noteNumber: noteNumber,
      velocity: _velocityToMidi(velocity),
    );

    _addEvent(noteOnEvent);
  }

  /// Adds a Note Off event to this track.
  /// This does not sync the events to the backend.
  void addNoteOff({required int noteNumber, required double beat}) {
    final noteOffEvent = MidiEvent.ofNoteOff(
      beat: beat,
      noteNumber: noteNumber,
    );

    _addEvent(noteOffEvent);
  }

  /// Adds a MIDI CC event to this track.
  /// This does not sync the events to the backend.
  void addMidiCC(
      {required int ccNumber, required int ccValue, required double beat}) {
    final ccEvent =
        MidiEvent.cc(beat: beat, ccNumber: ccNumber, ccValue: ccValue);

    _addEvent(ccEvent);
  }

  /// Adds a MIDI pitch bend event to this track.
  /// The value must be between -1 and 1.
  /// This does not sync the events to the backend.
  void addMidiPitchBend({required double value, required double beat}) {
    final pitchBendEvent = MidiEvent.pitchBend(beat: beat, value: value);

    _addEvent(pitchBendEvent);
  }

  /// Adds a Volume event to this track.
  /// This does not sync the events to the backend.
  void addVolumeChange({required double volume, required double beat}) {
    final volumeChangeEvent = VolumeEvent(beat: beat, volume: volume);

    _addEvent(volumeChangeEvent);
  }

  /// Gets the current volume of the track.
  double getVolume() {
    return NativeBridge.getTrackVolume(id);
  }

  /// Clears all events on this track.
  /// This does not sync the events to the backend.
  void clearEvents() {
    events.clear();
  }

  /// Syncs events to the backend. This should be called after making changes to
  /// track events to ensure that the changes are synced immediately.
  void syncBuffer(
      [int? absoluteStartFrame, int maxEventsToSync = BUFFER_SIZE]) {
    final position = NativeBridge.getPosition();

    if (absoluteStartFrame == null) {
      absoluteStartFrame = position;
    } else {
      absoluteStartFrame = max(absoluteStartFrame, position);
    }

    NativeBridge.clearEvents(id, absoluteStartFrame);

    if (sequence.isPlaying) {
      final relativeStartFrame = absoluteStartFrame - sequence.engineStartFrame;
      _scheduleEvents(relativeStartFrame, maxEventsToSync);
    } else {
      lastFrameSynced = 0;
    }
  }

  /// {@macro flutter_sequencer_library_private}
  /// Triggers a sync that will fill any available space in the buffer with
  /// any un-synced events.
  void topOffBuffer() {
    final bufferAvailableCount = NativeBridge.getBufferAvailableCount(id);

    if (bufferAvailableCount > 0) {
      syncBuffer(lastFrameSynced + 1, bufferAvailableCount);
    }
  }

  /// {@macro flutter_sequencer_library_private}
  /// Clears any scheduled events in the backend.
  void clearBuffer() {
    NativeBridge.clearEvents(id, 0);
  }

  /// Adds an event to the event list at the appropriate index given the sort
  /// order determined by _compareEvents.
  void _addEvent(SchedulerEvent eventToAdd) {
    int index;

    if (events.isEmpty) {
      index = 0;
    } else {
      final indexWhereResult =
          events.indexWhere((e) => _compareEvents(e, eventToAdd) == 1);

      if (indexWhereResult == -1) {
        index = events.length;
      } else {
        index = indexWhereResult;
      }
    }

    events.insert(index, eventToAdd);
  }

  /// Builds events that can be scheduled in the sequencer engine's event buffer
  /// and adds them to eventsList.
  void _scheduleEvents(int startFrame, [int maxEventsToSync = BUFFER_SIZE]) {
    final isBeforeLoopEnd = sequence.loopState == LoopState.BeforeLoopEnd;
    final loopLength = sequence.getLoopLengthFrames();
    final loopsElapsed = sequence.loopState == LoopState.Off
        ? 0
        : sequence.getLoopsElapsed(startFrame);

    var eventsSyncedCount = _scheduleEventsInRange(
        maxEventsToSync,
        isBeforeLoopEnd ? sequence.getLoopedFrame(startFrame) : startFrame,
        sequence.beatToFrames(
            isBeforeLoopEnd ? sequence.loopEndBeat : sequence.endBeat),
        loopLength * loopsElapsed);

    if (isBeforeLoopEnd) {
      var loopIndex = loopsElapsed + 1;
      var lastBatchCount = 0;
      final loopStartFrame = sequence.beatToFrames(sequence.loopStartBeat);
      final loopEndFrame = sequence.beatToFrames(sequence.loopEndBeat);

      while (eventsSyncedCount < maxEventsToSync) {
        // Schedule all events in one loop range
        lastBatchCount = _scheduleEventsInRange(
            maxEventsToSync - eventsSyncedCount,
            loopStartFrame,
            loopEndFrame,
            loopLength * loopIndex);

        eventsSyncedCount += lastBatchCount;
        if (lastBatchCount == 0) break;
        loopIndex++;
      }
    }
  }

  /// Schedules this track's events that start on or after startBeat and end
  /// on or before endBeat. Adds frameOffset to every scheduled event.
  int _scheduleEventsInRange(
      int maxEventsToSync, int startFrame, int? endFrame, int frameOffset) {
    final eventsToSync = <SchedulerEvent>[];

    for (var eventIndex = 0; eventIndex < events.length; eventIndex++) {
      if (eventsToSync.length == maxEventsToSync) break;

      final event = events[eventIndex];
      final eventFrame = sequence.beatToFrames(event.beat);

      if (eventFrame < startFrame) continue;
      if (endFrame != null && eventFrame > endFrame) break;

      eventsToSync.add(event);
    }

    final eventsSyncedCount = NativeBridge.scheduleEvents(
        id,
        eventsToSync,
        Sequence.globalState.sampleRate!,
        sequence.tempo,
        sequence.engineStartFrame + frameOffset);

    if (eventsSyncedCount > 0) {
      lastFrameSynced = sequence.engineStartFrame +
          sequence.beatToFrames(eventsToSync[eventsSyncedCount - 1].beat) +
          frameOffset;
    }

    return eventsSyncedCount;
  }

  /// Used for ordering events.
  int _compareEvents(SchedulerEvent eventA, SchedulerEvent eventB) {
    final beatComparison = eventA.beat.compareTo(eventB.beat);

    if (beatComparison != 0) {
      return beatComparison;
    } else {
      // Beats are the same

      if (eventA is VolumeEvent && !(eventB is VolumeEvent)) {
        // Volume should come before anything else
        return -1;
      } else if (eventB is VolumeEvent && !(eventA is VolumeEvent)) {
        return 1;
      } else if (eventA is MidiEvent && eventB is MidiEvent) {
        // Note off should come before note on if the note is the same
        if (eventA.midiData1 == eventB.midiData1 &&
            eventA.midiStatus == MIDI_STATUS_NOTE_OFF &&
            eventB.midiStatus == MIDI_STATUS_NOTE_ON) {
          return -1;
        } else if (eventA.midiData1 == eventB.midiData1 &&
            eventA.midiStatus == MIDI_STATUS_NOTE_ON &&
            eventB.midiStatus == MIDI_STATUS_NOTE_OFF) {
          return 1;
        } else {
          return 0;
        }
      } else {
        return 0;
      }
    }
  }

  int _velocityToMidi(double velocity) {
    return (velocity * 127).round();
  }
}
