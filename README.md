# flutter_sequencer

This Flutter plugin lets you set up sampler instruments and create multi-track sequences of notes
that play on those instruments. You can specify a loop range for a sequence and schedule volume
automations.

It uses the [core sampler engine from AudioKit](https://github.com/AudioKit/AudioKit/tree/v4-master/AudioKit/Core/AudioKitCore/Sampler)
on both Android and iOS, which lets you create an instrument by loading some samples and specifying
what notes they are. If you play a note you don't have a sample for, it will pitch shift your other
samples to fill in the gaps. It also supports playing SF2 (SoundFont) files on both platforms, and
on iOS, you can load any AudioUnit instrument.

The example app is a drum machine. In theory, though, you could make a whole sample-based DAW with
this plugin. You could also use it for game sound effects, or even to generate a dynamic game
soundtrack.

![Drum machine example on Android](https://michaeljperri.com/images/DrumMachineExampleAndroid.png)

## How to use
### Create the sequence
```dart
final sequence = Sequence(tempo: 120.0, endBeat: 8.0);
```
You need to set the tempo and the end beat when you create the sequence.

### Create instruments
```dart
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
  ),
];
```
An instrument can be used to create one or more tracks.
There are four instruments:

1. SamplerInstrument, to load a list of SampleDescriptors in the AudioKitSampler manually without an SFZ file
    - On iOS and Android, it will be played by the [AudioKit Sampler](https://github.com/AudioKit/AudioKit/tree/v4-master/AudioKit/Core/AudioKitCore/Sampler)
    - A SampleDescriptor can point to a .wav or a .wv (WavPack) file. I recommend using .wv when
    possible, since it supports lossless compression. It's easy to convert audio files to WavPack
    format with ffmpeg.
    - The only things you need to specify about a sample are its path, whether or not it's an asset,
    and what note number it should correspond to.
    - Optionally, you can set a note range or a velocity range for each sample. You can create
    "velocity layers" like this, where lower velocities trigger different samples than higher ones.
2. SfzInstrument, to load a `.sfz` SFZ file.
    - This will also be played by the AudioKit sampler.
    - Only a few SFZ opcodes are supported. Look at sfz_parser.dart to see which ones are
    acknowledged.
    - This is not a full-fledged SFZ player. SFZ just provides a convenient format to load samples
    into the sampler.
3. Sf2Instrument, to load a `.sf2` SoundFont file.
    - On iOS, it will be played by the built-in Apple MIDI synth AudioUnit
    - On Android, it will be played by [tinysoundfont](https://github.com/schellingb/TinySoundFont)
4. AudioUnitInstrument, to load an AudioUnit
    - This will only work on iOS
        
For an SF2 or SFZ instrument, pass `isAsset: true` to load a path in the Flutter assets directory.
You should use assets for "factory preset" sounds. To load user-provided or downloaded sounds
from the filesystem, pass `isAsset: false`.

### Optional: keep engine running
```dart
GlobalState().setKeepEngineRunning(true);
```
This will keep the audio engine running even when all sequences are paused. Set this to true if you
need to trigger sounds when the sequence is paused. Don't do it otherwise, since it will increase
energy usage.

### Create tracks
```dart
sequence.createTracks(instruments).then((tracks) {
  setState(() {
    this.tracks = tracks;
    ...
  });
});
```
createTracks returns Future<List<Track>>. You probably want to store the value it completes with in
your widget's state.

### Schedule events on the tracks
```dart
track.addNote(noteNumber: 60, velocity: 0.7, startBeat: 0.0, durationBeats: 2.0);
```
This will add middle C (MIDI note number 60) to the sequence, starting from beat 0, and stopping
after 2 beats.

```dart
track.addVolumeChange(volume: 0.75, beat: 2.0);
```
This will schedule a volume change. It can be used to do volume automation. Note that track volume
is on a linear scale, not a logarithmic scale. You may want to use a logarithmic scale and convert
to linear.

### Control playback
```dart
sequence.play();
```
```dart
sequence.pause();
```
```dart
sequence.stop();
```
Start, pause, or stop the sequence.

```dart
sequence.setBeat(double beat);
```
Set the playback position in the sequence, in beats.

```dart
sequence.setEndBeat(double beat);
```
Set the length of the sequence in beats.

```dart
sequence.setTempo(120.0);
```
Set the tempo in beats per minute.

```dart
sequence.setLoop(double loopStartBeat, double loopEndBeat);
```
Enable looping.

```dart
sequence.unsetLoop();
```
Disable looping.

### Get real-time information about the sequence
You can use SingleTickerProviderStateMixin to make these calls on every frame.

```
sequence.getPosition(); // double
```
Gets the playback position of the sequence, in beats.

```
sequence.getIsPlaying(); // bool
```
Gets whether or not the sequence is playing. It may have stopped if it reached the end.

```
track.getVolume();
```
Gets the volume of a track. A VolumeEvent may have changed it during playback.

### Real-time playback
```
track.startNoteNow(noteNumber: 60, velocity: 0.75);
```
Send a MIDI Note On message to the track immediately.

```
track.stopNoteNow(noteNumber: 60);
```
Send a MIDI Note Off message to the track immediately.

```
track.changeVolumeNow(volume: 0.5);
```
Change the track's volume immediately. Note that this is linear gain, not logarithmic.

## How it works
The Android and iOS backends start their respective audio engines. The iOS one adds an AudioUnit
for each track to an AVAudioEngine and connects it to a Mixer AudioUnit. The Android one has to
do all of the rendering manually. Both of them share a "BaseScheduler", which can be found under the
`ios` directory.

The backend has no concept of the sequence, the position in a sequence, the loop state, or even time
as measured in seconds or beats. It just maintains a map of tracks, and it triggers events on those
tracks when the appropriate number of frames have been rendered by the audio engine. The
BaseScheduler has a Buffer for each track that holds its scheduled events. The Buffer is supposed to
be thread-safe for one reader and one writer and real-time safe (i.e. it will not allocate memory,
so it can be used on the audio render thread.)

The Sequence lives on the Dart front end. A Sequence has Tracks. Each Track is backed by a Buffer on
the backend. When you add a note or a volume change to the track, it schedules an event on the
Buffer at the appropriate frame, based on the tempo and sample rate.

The buffer might not be big enough to hold all the events. Also, when looping is enabled, events
will occur indefinitely, so the buffer will never be big enough. To deal with this, the frontend
will periodically "top off" each track's buffer.

## Development instructions
Note that the Android build uses several third party libraries. The Gradle build will download them
from GitHub into the android/third_party directory.

The iOS build depends on the AudioKit library. It will be downloaded by CocoaPods.

To build the C++ tests on Mac OS, go into the `cpp_test` directory, and run
```
cmake .
make
```
Then, to run the tests,
```
./build/sequencer_test
```

I haven't tried it on Windows or Linux, but it should work without too many changes.

## To Do
PRs are welcome! If you use this plugin in your project, please consider contributing by fixing a
bug or by tackling one of these to-do items.

### Difficulty: Easy
- (important) Enable setting the AudioKit Sampler envelope parameters
- Change position_frame_t to 64-bit integer to avoid overflow errors
- Make constants configurable (TOP_OFF_PERIOD_MS and LEAD_FRAMES)
- Support federated plugins

### Difficulty: Medium
- Start using Dart null safety
- Support tempo automation
- Support pitch bends and custom tunings
- MIDI Out instrument
    - Create an instrument that doesn't make any sounds on its own and just sends MIDI
    events to a designated MIDI output port.
- Refactoring
    - GlobalState, Sequence, and Track should have a clear separation of responsibilities
    - Engine, Sequencer, Mixer, Scheduler do too
    - "Track index" and "Track ID" are used interchangeably, "Track ID" should be used everywhere
    - Make the names and organization of the different files (Plugin/Engine/Scheduler) consistent
- Optimize UI performance of example app
- Support MacOS
    - Most of the iOS code should be able to be reused
- Add more C++ tests
    - For BaseScheduler, specifically.
- Add Dart tests
    - Test loop edge cases
- Ensure there are no memory leaks or concurrency issues

### Difficulty: Hard
- Generic C++ instrument
    - Create an instrument that can be used on iOS and Android. The AudioKit Sampler works this way,
    but this library uses AudioKit's AudioUnit wrapper for it. The hard part is creating an
    generic AudioUnit wrapper for a C++ `IInstrument`.
- Full SFZ support
    - This would probably involve the [sfizz](https://github.com/sfztools/sfizz/) library
        - It may be difficult to build sfizz and its dependencies for Android and iOS. Ideally it
        would have a more modular build - this project doesn't need its support for AU/LV/VST,
        audio output, and audio file decoding.
- Support Windows
    - Some of the code in the Android directory might be able to be reused
- Record audio output
- Support React Native?
    - Could use dart2js

#### Difficulty: Very Hard
- (important) Audio graph
    - Create a graph of tracks and effects where any output can be connected to any input.
    - At that point, the most of the audio engine can be cross-platform. On iOS, it could be
    wrapped in one AudioUnit, and external AudioUnit instruments and effects could be connected to it
    via input and output buses.
    - [LabSound](https://github.com/LabSound/LabSound/tree/dev) seems like the library to use
        - It's based on WebAudio, so there could also be a web backend
	- Can be used to add some key effects like reverb, delay, and compression
	- Supports audio input, writing output to file, and other DAW stuff
- Support Web
