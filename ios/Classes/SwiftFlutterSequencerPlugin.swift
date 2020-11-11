import Foundation
import AudioToolbox
import CoreAudio
import AVFoundation
import AudioKit

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
        } else if (call.method == "listAssetDir") {
            let assetDir = (call.arguments as AnyObject)["assetDir"] as! String
            let fileExtension = (call.arguments as AnyObject)["extension"] as! String
            
            let paths = listAssetDir(assetDir, fileExtension: fileExtension, registrar: registrar)
            result(paths)
        } else if (call.method == "listAudioUnits") {
            listAudioUnits { result($0) }
        } else if (call.method == "addTrackAudioUnit") {
            let audioUnitId = (call.arguments as AnyObject)["id"] as! String
            addTrackAudioUnit(audioUnitId) { result($0) }
        }
    }
}

// Called from method channel
func listAssetDir(_ assetDir: String, fileExtension: String, registrar: FlutterPluginRegistrar) -> [String] {
    let dirKey: String = registrar.lookupKey(forAsset: assetDir)
    return Bundle.main.paths(forResourcesOfType: fileExtension, inDirectory: dirKey)
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

@_cdecl("add_track_sampler")
func addTrackSampler(trackIndexCallbackPort: Dart_Port) {
    plugin.engine!.addTrackSampler { trackIndex in
        if let trackIndex = trackIndex {
            callbackToDartInt32(trackIndexCallbackPort, Int32(trackIndex))
        } else {
            callbackToDartInt32(trackIndexCallbackPort, -1)
        }
    }
}

@_cdecl("add_sample_to_sampler")
func addSampleToSampler(
    trackIndex: Int32,
    samplePath: UnsafePointer<CChar>,
    isAsset: Bool,
    noteNumber: Int32,
    noteFrequency: Float32,
    minimumNoteNumber: Int32,
    maximumNoteNumber: Int32,
    minimumVelocity: Int32,
    maximumVelocity: Int32,
    isLooping: Bool,
    loopStartPoint: Float32,
    loopEndPoint: Float32,
    startPoint: Float32,
    endPoint: Float32,
    resultCallbackPort: Dart_Port
) {
    DispatchQueue.global(qos: .default).async {
        let sd = AKSampleDescriptor(
            noteNumber: noteNumber,
            noteFrequency: noteFrequency,
            minimumNoteNumber: minimumNoteNumber,
            maximumNoteNumber: maximumNoteNumber,
            minimumVelocity: minimumVelocity,
            maximumVelocity: maximumVelocity,
            isLooping: isLooping,
            loopStartPoint: loopStartPoint,
            loopEndPoint: loopEndPoint,
            startPoint: startPoint,
            endPoint: endPoint
        )
        plugin.engine!.addSampleToSampler(
            trackIndex: trackIndex,
            samplePath: String(cString: samplePath),
            isAsset: isAsset,
            sd: sd
        ) { result in
            callbackToDartBool(resultCallbackPort, result)
        }
    }
}

@_cdecl("build_key_map")
func buildKeyMap(trackIndex: track_index_t, resultCallbackPort: Dart_Port) {
    DispatchQueue.global(qos: .default).async {
        plugin.engine!.buildKeyMap(trackIndex: trackIndex) { result in
            callbackToDartBool(resultCallbackPort, result)
        }
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
    plugin.engine!.addTrackAudioUnit(audioUnitId: audioUnitId, completion: completion)}

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
