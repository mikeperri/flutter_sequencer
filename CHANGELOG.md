## 0.1.0

* Initial release.

## 0.1.1

* Fix third-party repos in Android build. Now they are downloaded by the Gradle build if they don't exist.

## 0.1.2

* SampleDescriptor uses default values for most properties.
* README is updated to explain how to build a sampler without an SFZ.
* "pitch" has been replaced with "noteNumber" in all the public APIs.
* Minor refactoring in sfz_parser.dart

## 0.1.3

* Merged PR to expose presetIndex: https://github.com/mikeperri/flutter_sequencer/pull/2

## 0.1.4

* Merge PR to fix presetIndex assignment: https://github.com/mikeperri/flutter_sequencer/pull/7
* Fix iOS release mode issue: https://github.com/mikeperri/flutter_sequencer/issues/8

## 0.2.0

* Migrate to null safety
* Upgrade lint rules

## 0.2.1

* Change AudioKit branch name

## 0.3.0

* Send MIDI note off for all notes when a track is stopped
* Prevent rounding errors in getIsOver() by using frames instead of beats
* Add Track.addNoteOn and .addNoteOff methods

## 0.3.1
* Clone third party repos with JGit library instead of deprecated Gradle plugin in Android build
* Update Kotlin version to get rid of warnings in Android build

## 0.3.2
* Set Xcode STRIP_STYLE to "non-global" in podspec

## 0.4.0
* Replaced AudioKit Sampler with [sfizz](https://sfz.tools/sfizz/) because it supports many more SFZ opcodes, including filters and effects, and can stream samples from disk instead of loading them all into RAM.
* Exposed APIs for scheduling MIDI CC and pitch bend events
* BREAKING CHANGE - Replaced SamplerInstrument with RuntimeSfzInstrument. Instead of creating SampleDescriptors, now you have to build an Sfz object.
* BREAKING CHANGE - Assets are copied to context.filesDir on Android for SFZ instruments. See the README for more info.
* BREAKING CHANGE - SFZ player no longer handles URL-decoding asset paths

## 0.4.1
* Update README

## 0.4.2
* Remove hard-coded FLUTTER_ROOT in example iOS app
* Run `flutter format`

## 0.4.3
* Fix for sfizz.hpp file not found on ios release build
