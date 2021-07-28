import Flutter
import Foundation
import AudioToolbox
import CoreAudio
import AVFoundation

var plugin: SwiftFlutterSequencerPlugin!

enum PluginError: Error {
    case engineNotReady
}

public class SwiftFlutterSequencerPlugin: NSObject, FlutterPlugin {
    public var registrar: FlutterPluginRegistrar!
    public var engine: CocoaEngine?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_sequencer", binaryMessenger: registrar.messenger())
        plugin = SwiftFlutterSequencerPlugin()
        plugin.registrar = registrar
        registrar.addMethodCallDelegate(plugin, channel: channel)
    }
    
    public override init() {
        super.init()

        plugin = self
    }
    
    deinit {
        plugin = nil
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "setupAssetManager") {
            result(nil)
        } else if (call.method == "normalizeAssetDir") {
            let assetDir = (call.arguments as AnyObject)["assetDir"] as! String

            result(normalizeAssetDir(registrar: registrar, assetDir: assetDir))
        } else if (call.method == "listAudioUnits") {
            listAudioUnits { result($0) }
        } else if (call.method == "addTrackAudioUnit") {
            let audioUnitId = (call.arguments as AnyObject)["id"] as! String
            addTrackAudioUnit(audioUnitId) { result($0) }
        }
    }
}

// Called from method channel
func normalizeAssetDir(registrar: FlutterPluginRegistrar, assetDir: String) -> String? {
    let key = registrar.lookupKey(forAsset: assetDir)
    let path = Bundle.main.path(forResource: key, ofType: nil)
    
    return path
}

// Called from method channel
func listAudioUnits(completion: @escaping ([String]) -> Void) {
    AudioUnitUtils.loadAudioUnits { loadedComponents in
        let ids = loadedComponents.map(AudioUnitUtils.getAudioUnitId)
        
        completion(ids)
    }
}


@_cdecl("setup_engine")
func setupEngine(sampleRateCallbackPort: Dart_Port) {
    plugin.engine = CocoaEngine(sampleRateCallbackPort: sampleRateCallbackPort, registrar: plugin.registrar)
}

@_cdecl("destroy_engine")
func destroyEngine() {
    plugin.engine = nil
}

@_cdecl("add_track_sfz")
func addTrackSfz(sfzPath: UnsafePointer<CChar>, tuningPath: UnsafePointer<CChar>, callbackPort: Dart_Port) {
    plugin.engine!.addTrackSfz(sfzPath: sfzPath, tuningPath: tuningPath) { trackIndex in
        callbackToDartInt32(callbackPort, trackIndex)
    }
}

@_cdecl("add_track_sfz_string")
func addTrackSfzString(sampleRoot: UnsafePointer<CChar>, sfzString: UnsafePointer<CChar>, tuningString: UnsafePointer<CChar>, callbackPort: Dart_Port) {
    plugin.engine!.addTrackSfzString(sampleRoot: sampleRoot, sfzString: sfzString, tuningString: tuningString) { trackIndex in
        callbackToDartInt32(callbackPort, trackIndex)
    }
}

@_cdecl("add_track_sf2")
func addTrackSf2(path: UnsafePointer<CChar>, isAsset: Bool, presetIndex: Int32, callbackPort: Dart_Port) {
    plugin.engine!.addTrackSf2(sf2Path: String(cString: path), isAsset: isAsset, presetIndex: presetIndex) { trackIndex in
        callbackToDartInt32(callbackPort, trackIndex)
    }
}

// Called from method channel
func addTrackAudioUnit(_ audioUnitId: String, completion: @escaping (track_index_t) -> Void) {
    plugin.engine!.addTrackAudioUnit(audioUnitId: audioUnitId, completion: completion)
}

@_cdecl("remove_track")
func removeTrack(trackIndex: track_index_t) {
    let _ = plugin.engine!.removeTrack(trackIndex: trackIndex)
}

@_cdecl("reset_track")
func resetTrack(trackIndex: track_index_t) {
    SchedulerResetTrack(plugin.engine!.scheduler, trackIndex)
}

@_cdecl("get_position")
func getPosition() -> position_frame_t {
    return SchedulerGetPosition(plugin.engine!.scheduler)
}

@_cdecl("get_track_volume")
func getTrackVolume(trackIndex: track_index_t) -> Float32 {
    return SchedulerGetTrackVolume(plugin.engine!.scheduler, trackIndex)
}

@_cdecl("get_last_render_time_us")
func getLastRenderTimeUs() -> UInt64 {
    return SchedulerGetLastRenderTimeUs(plugin.engine!.scheduler)
}

@_cdecl("get_buffer_available_count")
func getBufferAvailableCount(trackIndex: track_index_t) -> UInt32 {
    return SchedulerGetBufferAvailableCount(plugin.engine!.scheduler, trackIndex)
}

@_cdecl("handle_events_now")
func handleEventsNow(trackIndex: track_index_t, eventData: UnsafePointer<UInt8>, eventsCount: UInt32) {
    let events = UnsafeMutablePointer<SchedulerEvent>.allocate(capacity: Int(eventsCount))
    
    rawEventDataToEvents(eventData, eventsCount, events)
    
    SchedulerHandleEventsNow(plugin.engine!.scheduler, trackIndex, UnsafePointer(events), eventsCount)
}

@_cdecl("schedule_events")
func scheduleEvents(trackIndex: track_index_t, eventData: UnsafePointer<UInt8>, eventsCount: UInt32) -> UInt32 {
    let events = UnsafeMutablePointer<SchedulerEvent>.allocate(capacity: Int(eventsCount))
    
    rawEventDataToEvents(eventData, eventsCount, events)
    
    return SchedulerAddEvents(plugin.engine!.scheduler, trackIndex, UnsafePointer(events), eventsCount)
}

@_cdecl("clear_events")
func clearEvents(trackIndex: track_index_t, fromFrame: position_frame_t) {
    SchedulerClearEvents(plugin.engine!.scheduler, trackIndex, fromFrame)
}

@_cdecl("engine_play")
func enginePlay() {
    plugin.engine!.play()
}

@_cdecl("engine_pause")
func enginePause() {
    plugin.engine!.pause()
}
