import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:isolate/ports.dart';

import 'models/events.dart';
import 'models/sample_descriptor.dart';

final DynamicLibrary nativeLib = Platform.isAndroid
  ? DynamicLibrary.open('libflutter_sequencer.so')
  : DynamicLibrary.executable();

final nRegisterPostCObject = nativeLib.lookupFunction<
  Void Function(
    Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
    functionPointer),
  void Function(
    Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
    functionPointer)>('RegisterDart_PostCObject');

final nSetupEngine = nativeLib.lookupFunction<
  Void Function(Int64),
  void Function(int)>('setup_engine');

final nDestroyEngine = nativeLib.lookupFunction<
  Void Function(),
  void Function()>('destroy_engine');

final nAddTrackSampler = nativeLib.lookupFunction<
  Void Function(Int64),
  void Function(int)>('add_track_sampler');

final nAddSampleToSampler = nativeLib.lookupFunction<
  Void Function(Int32, Pointer<Utf8>, Int8, Int32, Float, Int32, Int32, Int32, Int32, Int8, Float, Float, Float, Float, Int64),
  void Function(int, Pointer<Utf8>, int, int, double, int, int, int, int, int, double, double, double, double, int)>('add_sample_to_sampler');

final nBuildKeyMap = nativeLib.lookupFunction<
  Void Function(Int32, Int64),
  void Function(int, int)>('build_key_map');

final nAddTrackSf2 = nativeLib.lookupFunction<
  Void Function(Pointer<Utf8>, Int8, Int32, Int64),
  void Function(Pointer<Utf8>, int, int, int)>('add_track_sf2');

final nRemoveTrack = nativeLib.lookupFunction<
  Void Function(Int32),
  void Function(int)>('remove_track');

final nResetTrack = nativeLib.lookupFunction<
  Void Function(Int32),
  void Function(int)>('reset_track');

final nGetPosition = nativeLib.lookupFunction<
  Uint32 Function(),
  int Function()>('get_position');

final nGetTrackVolume = nativeLib.lookupFunction<
  Float Function(Int32),
  double Function(int)>('get_track_volume');

final nGetLastRenderTimeUs = nativeLib.lookupFunction<
  Uint64 Function(),
  int Function()>('get_last_render_time_us');

final nGetBufferAvailableCount = nativeLib.lookupFunction<
  Uint32 Function(Int32),
  int Function(int)>('get_buffer_available_count');

final nHandleEventsNow = nativeLib.lookupFunction<
  Uint32 Function(Int32, Pointer<Uint8>, Uint32),
  int Function(int, Pointer<Uint8>, int)>('handle_events_now');

final nScheduleEvents = nativeLib.lookupFunction<
  Uint32 Function(Int32, Pointer<Uint8>, Uint32),
  int Function(int, Pointer<Uint8>, int)>('schedule_events');

final nClearEvents = nativeLib.lookupFunction<
  Void Function(Int32, Uint32),
  void Function(int, int)>('clear_events');

final nPlay = nativeLib.lookupFunction<
  Void Function(),
  void Function()>('engine_play');

final nPause = nativeLib.lookupFunction<
  Void Function(),
  void Function()>('engine_pause');

/// {@macro flutter_sequencer_library_private}
/// This class encapsulates the boilerplate code needed to call into native code
/// and get responses back. It should hide any implementation details from the
/// rest of the library.
class NativeBridge {
  static const MethodChannel _channel = MethodChannel('flutter_sequencer');

  // Must be called once, before any other method
  static Future<int> doSetup() async {
    await _channel.invokeMethod('setupAssetManager');
    nRegisterPostCObject(NativeApi.postCObject);

    return singleResponseFuture<int>((port) => nSetupEngine(port.nativePort));
  }

  static Future<List<String>> listAssetDir(String assetDir, String extension) async {
    final args = <String, dynamic>{
      'assetDir': assetDir,
      'extension': extension
    };
    final result = await _channel.invokeMethod('listAssetDir', args);
    final List<String> paths = result.cast<String>();

    return paths;
  }

  static Future<List<String>> listAudioUnits() async {
    final result = await _channel.invokeMethod('listAudioUnits');
    final List<String> audioUnitIds = result.cast<String>();

    return audioUnitIds;
  }

  static Future<int> addTrackSampler() {
    return singleResponseFuture<int>((port) => nAddTrackSampler(port.nativePort));
  }

  static Future<bool> addSampleToSampler(
    int trackIndex,
    SampleDescriptor sampleDescriptor
  ) {
    final filenameUtf8Ptr = Utf8.toUtf8(sampleDescriptor.filename);

    return singleResponseFuture<bool>((port) =>
      nAddSampleToSampler(
        trackIndex,
        filenameUtf8Ptr,
        sampleDescriptor.isAsset ? 1 : 0,
        sampleDescriptor.noteNumber,
        sampleDescriptor.noteFrequency,
        sampleDescriptor.minimumNoteNumber,
        sampleDescriptor.maximumNoteNumber,
        sampleDescriptor.minimumVelocity,
        sampleDescriptor.maximumVelocity,
        sampleDescriptor.isLooping ? 1 : 0,
        sampleDescriptor.loopStartPoint,
        sampleDescriptor.loopEndPoint,
        sampleDescriptor.startPoint,
        sampleDescriptor.endPoint,
        port.nativePort
      ));
  }

  static Future<bool> samplerBuildKeyMap(int trackIndex) {
    return singleResponseFuture<bool>((port) =>
      nBuildKeyMap(trackIndex, port.nativePort));
  }

  static Future<int> addTrackSf2(String filename, bool isAsset, int patchNumber) {
    final filenameUtf8Ptr = Utf8.toUtf8(filename);
    return singleResponseFuture<int>((port) => nAddTrackSf2(filenameUtf8Ptr, isAsset ? 1 : 0, patchNumber, port.nativePort));
  }

  static Future<int> addTrackAudioUnit(String id) async {
    if (Platform.isAndroid) return -1;

    final args = <String, dynamic>{
      'id': id,
    };

    return await _channel.invokeMethod('addTrackAudioUnit', args);
  }

  static void removeTrack(int trackIndex) {
    nRemoveTrack(trackIndex);
  }

  static void resetTrack(int trackIndex) {
    nResetTrack(trackIndex);
  }

  static int getPosition() {
    return nGetPosition();
  }

  static double getTrackVolume(int trackIndex) {
    return nGetTrackVolume(trackIndex);
  }

  static int getLastRenderTimeUs() {
    return nGetLastRenderTimeUs();
  }

  static int getBufferAvailableCount(int trackIndex) {
    return nGetBufferAvailableCount(trackIndex);
  }

  static int handleEventsNow(int trackIndex, List<SchedulerEvent> events, int sampleRate, double tempo) {
    if (events.isEmpty) return 0;

    final nativeArray = allocate<Uint8>(count: events.length * SCHEDULER_EVENT_SIZE);
    events.asMap().forEach((eventIndex, e) {
      final byteData = e.serializeBytes(sampleRate, tempo, 0);
      for (var byteIndex = 0; byteIndex < byteData.lengthInBytes; byteIndex++) {
        nativeArray[eventIndex * SCHEDULER_EVENT_SIZE + byteIndex] = byteData.getUint8(byteIndex);
      }
    });

    return nHandleEventsNow(trackIndex, nativeArray, events.length);
  }

  static int scheduleEvents(int trackIndex, List<SchedulerEvent> events, int sampleRate, double tempo, int frameOffset) {
    if (events.isEmpty) return 0;

    final nativeArray = allocate<Uint8>(count: events.length * SCHEDULER_EVENT_SIZE);
    events.asMap().forEach((eventIndex, e) {
      final byteData = e.serializeBytes(sampleRate, tempo, frameOffset);
      for (var byteIndex = 0; byteIndex < byteData.lengthInBytes; byteIndex++) {
        nativeArray[eventIndex * SCHEDULER_EVENT_SIZE + byteIndex] = byteData.getUint8(byteIndex);
      }
    });

    return nScheduleEvents(trackIndex, nativeArray, events.length);
  }

  static void clearEvents(int trackIndex, int fromTick) {
    nClearEvents(trackIndex, fromTick);
  }

  static void play() {
    nPlay();
  }

  static void pause() {
    nPause();
  }
}
