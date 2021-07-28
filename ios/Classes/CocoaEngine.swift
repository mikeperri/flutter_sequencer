import Foundation
import AVFoundation

public class CocoaEngine {
    var scheduler: UnsafeMutableRawPointer!
    
    private let engine = AVAudioEngine()
    private var mixer: AVAudioUnit?
    private let outputFormat: AVAudioFormat!
    private let registrar: FlutterPluginRegistrar!

    // Swift Dictionary is not thread-safe, so this must be copied before access
    private var unsafeAvAudioUnits: [track_index_t: AVAudioUnit] = [:]
    
    public init(sampleRateCallbackPort: Dart_Port, registrar: FlutterPluginRegistrar) {
        outputFormat = engine.outputNode.outputFormat(forBus: 0)
        
        self.registrar = registrar

        initMixer {
            self.scheduler = InitScheduler(self.mixer!.audioUnit, self.outputFormat.sampleRate)

            callbackToDartInt32(sampleRateCallbackPort, Int32(self.outputFormat.sampleRate))
        }
        
        SfizzAU.registerAU()
    }
    
    deinit {
        SchedulerPause(self.scheduler)
        engine.stop()
        scheduler.deallocate()
    }
    
    func addTrackSfz(sfzPath: UnsafePointer<CChar>, tuningPath: UnsafePointer<CChar>, completion: @escaping (track_index_t) -> Void) {
        AudioUnitUtils.instantiate(
            description: SfizzAU.componentDescription,
            sampleRate: self.outputFormat.sampleRate,
            options: AudioComponentInstantiationOptions.loadOutOfProcess
        ) { avAudioUnit in
            AudioUnitUtils.setSampleRate(avAudioUnit: avAudioUnit, sampleRate: self.outputFormat.sampleRate)
            let sfizzAU = avAudioUnit.auAudioUnit as! SfizzAU
            
            if (sfizzAU.loadSfzFile(path: sfzPath, tuningPath: tuningPath)) {
                let trackIndex = SchedulerAddTrack(self.scheduler)
                self.setTrackAudioUnit(trackIndex: trackIndex, avAudioUnit: avAudioUnit)
                completion(trackIndex)
            } else {
                completion(-1)
            }
        }
    }
    
    func addTrackSfzString(sampleRoot: UnsafePointer<CChar>, sfzString: UnsafePointer<CChar>, tuningString: UnsafePointer<CChar>, completion: @escaping (track_index_t) -> Void) {
        AudioUnitUtils.instantiate(
            description: SfizzAU.componentDescription,
            sampleRate: self.outputFormat.sampleRate,
            options: AudioComponentInstantiationOptions.loadOutOfProcess
        ) { avAudioUnit in
            AudioUnitUtils.setSampleRate(avAudioUnit: avAudioUnit, sampleRate: self.outputFormat.sampleRate)
            let sfizzAU = avAudioUnit.auAudioUnit as! SfizzAU

            if (sfizzAU.loadSfzString(sampleRoot: sampleRoot, sfzString: sfzString, tuningString: tuningString)) {
                let trackIndex = SchedulerAddTrack(self.scheduler)
                self.setTrackAudioUnit(trackIndex: trackIndex, avAudioUnit: avAudioUnit)
                completion(trackIndex)
            } else {
                completion(-1)
            }
        }
    }
    
    func addTrackSf2(sf2Path: String, isAsset: Bool, presetIndex: Int32, completion: @escaping (track_index_t) -> Void) {
        let trackIndex = SchedulerAddTrack(self.scheduler)

        AudioUnitUtils.loadAudioUnits { avAudioUnitComponents in
            let appleSamplerComponent = avAudioUnitComponents.first(where: isAppleSampler)
            
            if let appleSamplerComponent = appleSamplerComponent {
                AudioUnitUtils.instantiate(
                    description: appleSamplerComponent.audioComponentDescription,
                    sampleRate: self.outputFormat.sampleRate,
                    options: AudioComponentInstantiationOptions.loadOutOfProcess
                ) { avAudioUnit in
                    AudioUnitUtils.setSampleRate(avAudioUnit: avAudioUnit, sampleRate: self.outputFormat.sampleRate)
                    
                    // Apple Sampler needs to be initialized again or pre-loading patch won't work
                    let error = AudioUnitInitialize(avAudioUnit.audioUnit)
                    assert(error == noErr)
                    
                    if let normalizedPath = self.normalizePath(sf2Path, isAsset: isAsset) {
                        let url = URL(fileURLWithPath: normalizedPath)
                        
                        loadSoundFont(avAudioUnit: avAudioUnit, soundFontURL: url, presetIndex: presetIndex)
                        
                        self.setTrackAudioUnit(trackIndex: trackIndex, avAudioUnit: avAudioUnit)
                        
                        completion(trackIndex)
                    } else {
                        completion(-1)
                    }
                }
            } else {
                print("Apple Sampler was not found")
                completion(-1)
            }
        }
    }
    
    func addTrackAudioUnit(audioUnitId: String, completion: @escaping (Int32) -> Void) {
        let trackIndex = SchedulerAddTrack(self.scheduler)

        AudioUnitUtils.loadAudioUnits { components in
            let match = components.first { AudioUnitUtils.getAudioUnitId($0) == audioUnitId }
            
            if (match != nil) {
                AudioUnitUtils.instantiate(
                    description: match!.audioComponentDescription,
                    sampleRate: self.outputFormat.sampleRate,
                    options: []
                ) { avAudioUnit in
                    self.setTrackAudioUnit(trackIndex: trackIndex, avAudioUnit: avAudioUnit)
                    
                    completion(trackIndex)
                }
            } else {
                completion(-1)
            }
        }
    }
    
    func setTrackAudioUnit(trackIndex: track_index_t, avAudioUnit: AVAudioUnit) {
        SchedulerSetTrackAudioUnit(self.scheduler, trackIndex, avAudioUnit.audioUnit)
        updateAvAudioUnits(trackIndex: trackIndex, avAudioUnit: avAudioUnit)
        connect(avAudioUnit: avAudioUnit, trackIndex: trackIndex)
    }
    
    func removeTrack(trackIndex: track_index_t) -> Bool {
        let avAudioUnitToRemove = getAvAudioUnits()[trackIndex]

        updateAvAudioUnits(trackIndex: trackIndex, avAudioUnit: nil)
        SchedulerRemoveTrack(self.scheduler, trackIndex)
        
        if let avAudioUnit = avAudioUnitToRemove {
            disconnect(avAudioUnit: avAudioUnit)
            return true
        }
        
        return false
    }

    func play() {
        do {
            SchedulerPlay(self.scheduler)
            try self.engine.start()
        } catch {
            // ignore
        }
    }
    
    func pause() {
        SchedulerPause(self.scheduler)
        self.engine.pause()
        self.engine.reset()
    }
    
    func initMixer(completion: @escaping () -> Void) {
        let options = AudioComponentInstantiationOptions.loadOutOfProcess
        let componentDescription =
            AudioComponentDescription(componentType: kAudioUnitType_Mixer,
                                      componentSubType: kAudioUnitSubType_MultiChannelMixer,
                                      componentManufacturer: kAudioUnitManufacturer_Apple,
                                      componentFlags: 0,
                                      componentFlagsMask: 0)
        
        AVAudioUnit.instantiate(with: componentDescription, options: options) { avAudioUnit, err in
            self.mixer = avAudioUnit
            
            if let avAudioUnit = avAudioUnit {
                let hardwareFormat = self.engine.outputNode.outputFormat(forBus: 0)
                
                self.engine.attach(avAudioUnit)
                self.engine.connect(avAudioUnit, to: self.engine.outputNode, format: hardwareFormat)
                
                completion()
            }
        }
    }
    
    func connect(avAudioUnit: AVAudioUnit, trackIndex: Int32) {
        // let hardwareFormat = self.engine.outputNode.outputFormat(forBus: 0)
        // let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareFormat.sampleRate, channels: 2)
        let auOutputFormat = avAudioUnit.outputFormat(forBus: 0)
        
        self.engine.attach(avAudioUnit)
        self.engine.connect(avAudioUnit, to: self.mixer!, fromBus: 0, toBus: AVAudioNodeBus(trackIndex), format: auOutputFormat)
    }
    
    func disconnect(avAudioUnit: AVAudioUnit) {
        self.engine.disconnectNodeOutput(avAudioUnit)
        self.engine.detach(avAudioUnit)
    }
    
    private func getAvAudioUnits() -> [track_index_t: AVAudioUnit] {
        return self.unsafeAvAudioUnits
    }
    
    private func updateAvAudioUnits(trackIndex: track_index_t, avAudioUnit: AVAudioUnit?) {
        var nextAvAudioUnits = self.unsafeAvAudioUnits;
        nextAvAudioUnits[trackIndex] = avAudioUnit;
        self.unsafeAvAudioUnits = nextAvAudioUnits;
    }
    
    private func normalizePath(_ path: String, isAsset: Bool) -> String? {
        if (!isAsset) {
            return path
        } else {
            let key = registrar.lookupKey(forAsset: path)
            let bundlePath = Bundle.main.path(forResource: key, ofType: nil)
            
            if let bundlePath = bundlePath {
                return bundlePath
            } else {
                return nil
            }
        }
    }
}
