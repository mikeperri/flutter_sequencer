import 'dart:async';
import 'dart:math';

import 'package:flutter_sequencer/sfz_parser.dart';

import 'constants.dart';
import 'global_state.dart';
import 'instrument.dart';
import 'native_bridge.dart';
import 'track.dart';

/// {@macro flutter_sequencer_library_private}
enum LoopState {
  Off,
  BeforeLoopEnd,
  AfterLoopEnd,
}

/// Represents a collection of tracks, play/pause state, position, loop state,
/// and tempo. Play the sequence to schedule the events on its tracks.
class Sequence {
  static final GlobalState globalState = GlobalState();

  Sequence({
    required this.tempo,
    required this.endBeat,
  }) {
    id = globalState.registerSequence(this);
  }

  /// Call this to remove this sequence and its tracks from the global sequencer
  /// engine.
  void destroy() {
    _tracks.values.forEach((track) => deleteTrack(track));
    globalState.unregisterSequence(this);
  }
  
  final _tracks = <int, Track>{};
  late int id;

  // Sequencer state
  bool isPlaying = false;
  double tempo;
  double endBeat;
  double pauseBeat = 0;
  int engineStartFrame = 0;
  LoopState loopState = LoopState.Off;
  double loopStartBeat = 0;
  double loopEndBeat = 0;

  /// Gets all tracks.
  List<Track> getTracks() {
    return _tracks.values.toList();
  }

  /// Creates tracks in the underlying sequencer engine.
  Future<List<Track>> createTracks(List<Instrument> instruments) async {
    if (globalState.isEngineReady) {
      return _createTracks(instruments);
    } else {
      final completer = Completer<List<Track>>.sync();

      globalState.onEngineReady(() async {
        final tracks = await _createTracks(instruments);

        completer.complete(tracks);
      });

      return completer.future;
    }
  }

  /// Removes a track from the underlying sequencer engine.
  List<Track> deleteTrack(Track track) {
    final keysToRemove = [];

    _tracks.forEach((key, value) {
      if (value == track) {
        keysToRemove.add(key);
      }
    });

    keysToRemove.forEach((key) {
      NativeBridge.removeTrack(key);
      _tracks.remove(key);
    });

    return _tracks.values.toList();
  }

  /// Starts playback of this sequence. If it is already playing, this will have
  /// no effect.
  void play() {
    if (!globalState.isEngineReady) return;

    if (getIsOver()) {
      setBeat(0.0);
    }

    globalState.playSequence(id);
  }

  /// Pauses playback of this sequence. If it is already paused, this will have
  /// no effect.
  void pause() {
    if (!globalState.isEngineReady) return;

    _tracks.values.forEach((track) {
      NativeBridge.resetTrack(track.id);
    });
    globalState.pauseSequence(id);
  }

  /// Stops playback of this sequence and resets its position to the beginning.
  void stop() {
    pause();
    setBeat(0.0);
    _tracks.values.forEach((track) {
      List.generate(128, (noteNumber) {
        track.stopNoteNow(noteNumber: noteNumber);
      });
    });
  }

  /// Sets the tempo.
  void setTempo(double nextTempo) {
    // Update engine start frame to remove excess loops
    final loopsElapsed =
      loopState == LoopState.BeforeLoopEnd
        ? getLoopsElapsed(_getFramesRendered())
        : 0;
    engineStartFrame += loopsElapsed * getLoopLengthFrames();

    // Update engine start frame to adjust to new tempo
    final framesRendered = _getFramesRendered();
    final nextFramesRendered =
      (framesRendered * (tempo / nextTempo)).round();
    final framesToAdvance = framesRendered - nextFramesRendered;
    engineStartFrame += framesToAdvance;

    tempo = nextTempo;

    getTracks().forEach((track) {
      track.syncBuffer();
    });
  }

  /// Enables looping.
  void setLoop(double loopStartBeat, double loopEndBeat) {
    // If the sequence is over, ensure globalState is updated so the sequence
    // doesn't start playing
    checkIsOver();

    // Update engine start frame to remove excess loops
    final loopsElapsed =
      loopState == LoopState.BeforeLoopEnd
        ? getLoopsElapsed(_getFramesRendered())
        : 0;
    engineStartFrame += loopsElapsed * getLoopLengthFrames();

    // Update loop state and bounds
    final loopEndFrame = beatToFrames(loopEndBeat);
    final currentFrame = _getFrame(false);

    if (currentFrame <= loopEndFrame) {
      loopState = LoopState.BeforeLoopEnd;
    } else {
      loopState = LoopState.AfterLoopEnd;
    }

    this.loopStartBeat = loopStartBeat;
    this.loopEndBeat = loopEndBeat;

    getTracks().forEach((track) => track.syncBuffer());
  }

  /// Disables looping for the sequence.
  void unsetLoop() {
    if (loopState == LoopState.BeforeLoopEnd) {
      final loopsElapsed = getLoopsElapsed(_getFramesRendered());

      engineStartFrame += loopsElapsed * getLoopLengthFrames();
    }

    loopStartBeat = 0;
    loopEndBeat = 0;
    loopState = LoopState.Off;

    getTracks().forEach((track) => track.syncBuffer());
  }

  /// Sets the beat at which the sequence will end. Events after the end beat
  /// won't be scheduled.
  void setEndBeat(double beat) {
    endBeat = beat;
  }

  /// Immediately changes the position of the sequence to the given beat.
  void setBeat(double beat) {
    if (!globalState.isEngineReady) return;

    _tracks.values.forEach((track) {
      NativeBridge.resetTrack(track.id);
    });

    final leadFrames =
    getIsPlaying()
      ? min(_getFramesRendered(), LEAD_FRAMES)
      : 0;

    final frame = beatToFrames(beat) - leadFrames;

    engineStartFrame = NativeBridge.getPosition() - frame;
    pauseBeat = beat;

    getTracks().forEach((track) {
      track.syncBuffer(engineStartFrame);
    });

    if (loopState != LoopState.Off) {
      final loopEndFrame = beatToFrames(loopEndBeat);
      loopState = frame < loopEndFrame
        ? LoopState.BeforeLoopEnd
        : LoopState.AfterLoopEnd;
    }
  }

  /// Returns true if the sequence is playing.
  bool getIsPlaying() {
    return isPlaying && !getIsOver();
  }

  /// Returns true if the sequence is at its end beat.
  bool getIsOver() {
    return _getFrame(true) == beatToFrames(endBeat);
  }

  /// Gets the current beat. Returns a value based on the number of frames
  /// rendered and the time elapsed since the last render callback. To omit
  /// the time elapsed since the last render callback, pass `false`.
  double getBeat([bool estimateFramesSinceLastRender = true]) {
    return framesToBeat(_getFrame(estimateFramesSinceLastRender));
  }

  /// Gets the current tempo.
  double getTempo() {
    return tempo;
  }

  /// {@macro flutter_sequencer_library_private}
  /// Returns the length of the loop in frames.
  int getLoopLengthFrames() {
    final loopStartFrame = beatToFrames(loopStartBeat);
    final loopEndFrame = beatToFrames(loopEndBeat);

    return loopEndFrame - loopStartFrame;
  }

  /// {@macro flutter_sequencer_library_private}
  /// Returns the number of loops that have been played
  /// since the sequence started playing.
  int getLoopsElapsed(int frame) {
    final loopStartFrame = beatToFrames(loopStartBeat);

    if (frame <= loopStartFrame) return 0;
    if (getLoopLengthFrames() == 0) return 0;

    return ((frame - loopStartFrame) / getLoopLengthFrames()).floor();
  }

  /// {@macro flutter_sequencer_library_private}
  /// Maps a frame beyond the end of the loop range to
  /// where it would be inside the loop range.
  int getLoopedFrame(int frame) {
    final loopStartFrame = beatToFrames(loopStartBeat);
    final loopLengthFrames = getLoopLengthFrames();

    if (frame <= loopStartFrame || loopLengthFrames == 0) return frame;

    return ((frame - loopStartFrame) % loopLengthFrames) + loopStartFrame;
  }

  /// {@macro flutter_sequencer_library_private}
  /// Converts a beat to sample frames.
  int beatToFrames(double beat) {
    // (min / b) * (ms) * (ms / min)
    final us = ((1 / tempo) * beat * (60000000)).round();

    return Sequence.globalState.usToFrames(us);
  }

  /// {@macro flutter_sequencer_library_private}
  /// Converts sample frames to a beat.
  double framesToBeat(int frames) {
    final us = Sequence.globalState.framesToUs(frames);

    // (b / min) * us * (min / us)
    return tempo * us * (1 / 60000000);
  }

  /// {@macro flutter_sequencer_library_private}
  /// Pauses this sequence if it is at its end.
  void checkIsOver() {
    if (isPlaying && getIsOver()) {
      // Sequence is at end, pause

      pauseBeat = endBeat;
      pause();
    }
  }

  /// Number of frames elapsed since the sequence was started. Does not account
  /// for the number of loops that may have occurred.
  int _getFramesRendered() {
    if (!globalState.isEngineReady) return 0;

    return NativeBridge.getPosition() - engineStartFrame - LEAD_FRAMES;
  }

  /// Gets the current frame position of the sequencer.
  int _getFrame([bool estimateFramesSinceLastRender = true]) {
    if (!globalState.isEngineReady) return 0;

    if (isPlaying) {
      final frame = _getFramesRendered() + (estimateFramesSinceLastRender ? _getFramesSinceLastRender() : 0);
      final loopedFrame = loopState == LoopState.Off ? frame : getLoopedFrame(frame);

      return max(min(loopedFrame, beatToFrames(endBeat)), 0);
    } else {
      return max(min(beatToFrames(pauseBeat), beatToFrames(endBeat)), 0);
    }
  }

  /// Returns the number of frames elapsed since the last audio render callback
  /// was called.
  int _getFramesSinceLastRender() {
    final microsecondsSinceLastRender =
      max(0, DateTime.now().microsecondsSinceEpoch - NativeBridge.getLastRenderTimeUs());

    return globalState.usToFrames(microsecondsSinceLastRender);
  }

  /// Creates a track in the underlying sequencer engine.
  Future<Track?> _createTrack(Instrument instrument) async {
    int? id;

    if (instrument is Sf2Instrument) {
      id = await NativeBridge.addTrackSf2(instrument.idOrPath, instrument.isAsset, instrument.presetIndex);
    } else if (instrument is SfzInstrument) {
      final parseResult = await parseSfz(instrument.idOrPath, instrument.isAsset);
      final samplerInstrument =
      SamplerInstrument(
        id: instrument.idOrPath,
        sampleDescriptors: parseResult.sampleDescriptors);

      id = await _createSamplerTrack(samplerInstrument);
    } else if (instrument is SamplerInstrument) {
      id = await _createSamplerTrack(instrument);
    } else if (instrument is AudioUnitInstrument) {
      id = await NativeBridge.addTrackAudioUnit(instrument.idOrPath);
    } else {
      return null;
    }

    final track =
      Track(
        sequence: this,
        id: id!,
        instrument: instrument,
      );

    _tracks.putIfAbsent(id, () => track);

    return track;
  }

  Future<List<Track>> _createTracks(List<Instrument> instruments) async {
    final tracks = await Future.wait(instruments.map((instrument) => _createTrack(instrument)));
    final nonNullTracks = tracks.whereType<Track>().toList();

    return nonNullTracks;
  }

  /// Creates a sampler track and adds the sample descriptors.
  Future<int> _createSamplerTrack(SamplerInstrument samplerInstrument) async {
    final trackIndex = await NativeBridge.addTrackSampler();

    final addSampleFutures =
    samplerInstrument.sampleDescriptors.map((sd) =>
      NativeBridge.addSampleToSampler(trackIndex, sd));

    await Future.wait(addSampleFutures);

    final buildKeyMapResult = await NativeBridge.samplerBuildKeyMap(trackIndex);

    if (buildKeyMapResult) {
      return trackIndex;
    } else {
      return -1;
    }
  }
}
