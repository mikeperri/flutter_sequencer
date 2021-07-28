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
  SfzInstrument(
    path: "assets/sfz/GMPiano.sfz",
    isAsset: true,
    tuningPath: "assets/sfz/meanquar.scl",
  ),
  RuntimeSfzInstrument(
    id: "Sampled Synth",
    sampleRoot: "assets/wav",
    isAsset: true,
    sfz: Sfz(
      groups: [
        SfzGroup(
          regions: [
            SfzRegion(sample: "D3.wav", noteNumber: 62),
            SfzRegion(sample: "F3.wav", noteNumber: 65),
            SfzRegion(sample: "Gsharp3.wav", noteNumber: 68),
          ],
        ),
      ],
    ),
  ),
  RuntimeSfzInstrument(
    id: "Generated Synth",
    // This SFZ doesn't use any sample files, so just put "/" as a placeholder.
    sampleRoot: "/",
    isAsset: false,
    // Based on the Unison Oscillator example here:
    // https://sfz.tools/sfizz/quick_reference#unison-oscillator
    sfz: Sfz(
      groups: [
        SfzGroup(
          regions: [
            SfzRegion(
              sample: "*saw",
              otherOpcodes: {
                "oscillator_multi": "5",
                "oscillator_detune": "50",
              }
            )
          ]
        )
      ]
    )
  ),
];
```
An instrument can be used to create one or more tracks.
There are four instruments:

1. SfzInstrument, to load a `.sfz` file and the samples it refers to.
    - On iOS and Android, it will be played by [sfizz](https://sfz.tools/sfizz/)
    - As far as I know, sfizz is the most complete and most frequently updated SFZ player library
    with a license that permits commercial use.
    - Sfizz supports .wav and .flac sample files, among others. I recommend using .flac when
    possible, since it supports lossless compression. It's easy to convert audio files to FLAC
    format with ffmpeg.
    - You can also create an SFZ that doesn't use any sample files by setting `sample` to a
    predefined waveform, such as `*sine`, `*saw`, `*square`, `*triangle`, or `*noise`.
    - Check which SFZ opcodes are supported by sfizz here:
    <https://sfz.tools/sfizz/development/status/opcodes/>
    - Learn more about the SFZ format here: <https://sfzformat.com>
2. RuntimeSfzInstrument, to build an SFZ at runtime.
    - This will also be played by [sfizz](https://sfz.tools/sfizz/).
    - Instead of a file, you pass an `Sfz` object to the constructor. See the example.
    - You might use this so that your app can build a synth using selected oscillators, or a sampler
    using user-provided samples.
3. Sf2Instrument, to load a `.sf2` SoundFont file.
    - On iOS, it will be played by the built-in Apple MIDI synth AudioUnit
    - On Android, it will be played by [tinysoundfont](https://github.com/schellingb/TinySoundFont)
    - I recommend using SFZ format, since sfizz can stream samples from disk. This way you can load
    bigger sound fonts without running out of RAM.
    - You can easily convert SF2 to SFZ with [Polyphone](https://www.polyphone-soundfonts.com). Just
    open the SF2, click the menu icon at the top right, and click "Export Soundfonts." Change the
    format to SFZ. The other options shouldn't matter.
4. AudioUnitInstrument, to load an AudioUnit
    - This will only work on iOS
    - You might use this if you are making a DAW type of app.

For an SF2 or SFZ instrument, pass `isAsset: true` to load a path in the Flutter assets directory.
You should use assets for "factory preset" sounds. To load user-provided or downloaded sounds
from the filesystem, pass `isAsset: false`.

### Important notes about `isAsset: true`
Note that on Android, SFZ files and samples that are loaded with `isAsset: true` will be extracted
from the bundle into the application files directory (`context.filesDir`), since sfizz cannot read
directly from Android assets. This means they will exist in two places on the device - in the
APK in compressed (zipped) form and in the files directory in uncompressed form. So I only recommend
using `isAsset: true` if your samples are small. If you want to include high-quality soundfonts in
your app, your app should download them at runtime.

Note that on either platform, **Flutter asset paths get URL-encoded**. For example, if you put a
file called "Piano G#5.wav" in your assets folder, it will end up being called "Piano%20G%235.wav"
on the device. So if you are bundling an SFZ file as an asset, make sure that you either remove any
special characters and spaces from the sample file names, or update the SFZ file to refer to the
URL-encoded sample paths. I recommend just getting rid of any spaces and special characters.

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

```dart
track.addMidiCC(ccNumber: 127, ccValue: 127, beat: 2.0);
```
This will schedule a MIDI CC event. These can be used to change parameters in a sound font. For
example, in an SFZ, you can use the "cutoff_cc1" and "cutoff" opcodes to define a filter where the
cutoff can be changed with MIDI CC events. There are many other parameters that can be controlled
by CC as well, such as amp envelope, filter envelope, sample offset, and EQ parameters. For more
information, see [how to do modulations in SFZ](https://sfzformat.com/tutorials/sfz1_modulations)
and [how to use filter cutoff in SFZ](https://sfzformat.com/opcodes/cutoff).

```dart
track.addMidiPitchBend(value: 1.0, beat: 2.0);
```
This will schedule a MIDI pitch bend event. The value can be from -1.0 to 1.0. Note that the value
is NOT the number of semitones. The sound font defines how many semitones the bend range is. For
example, in an SFZ, you can use the "bend_down" and "bend_up" opcodes to define how many cents the
pitch will be changed when the bend value is set to -1.0 and 1.0, respectively.

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
