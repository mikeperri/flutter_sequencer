import Foundation
import AVFoundation
import AudioKit

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
        
        AKSampler.register()
        AKSettings.enableLogging = true

        initMixer {
            self.scheduler = InitScheduler(self.mixer!.audioUnit, self.outputFormat.sampleRate)

            callbackToDartInt32(sampleRateCallbackPort, Int32(self.outputFormat.sampleRate))
        }
    }
    
    deinit {
        SchedulerPause(self.scheduler)
        engine.stop()
        scheduler.deallocate()
    }
    
    func addTrackSampler(completion: @escaping (track_index_t?) -> Void) {
        let trackIndex = SchedulerAddTrack(self.scheduler)

        AVAudioUnit.instantiate(with: AKSampler.ComponentDescription, options: []) { avAudioUnit, err in
            if let avAudioUnit = avAudioUnit {
                AudioUnitUtils.setSampleRate(avAudioUnit: avAudioUnit, sampleRate: self.outputFormat.sampleRate)
                self.setTrackAudioUnit(trackIndex: trackIndex, avAudioUnit: avAudioUnit)
                
                completion(trackIndex)
            } else {
                completion(nil)
            }
        }
    }
    
    func addSampleToSampler(trackIndex: track_index_t, samplePath: String, isAsset: Bool, sd: AKSampleDescriptor, completion: @escaping (Bool) -> Void) {
        if let url = getUrlForPath(samplePath, isAsset: isAsset) {
            if let avAudioUnit = self.getAvAudioUnits()[trackIndex] {
                if let akSamplerAU = avAudioUnit.auAudioUnit as? AKSamplerAudioUnit {
                    if url.path.hasSuffix(".wv") {
                        url.path.cString(using: .ascii)?.withUnsafeBufferPointer { buffer in
                            akSamplerAU.loadCompressedSampleFile(
                                from: AKSampleFileDescriptor(sampleDescriptor: sd, path: buffer.baseAddress))
                            completion(true)
                        }
                    } else {
                        do {
                            let file = try AKAudioFile(forReading: url)
                            let sampleRate = Float(file.sampleRate)
                            let sampleCount = Int32(file.samplesCount)
                            let channelCount = Int32(file.channelCount)
                            var flattened = Array(file.floatChannelData!.joined())
                            flattened.withUnsafeMutableBufferPointer { data in
                                akSamplerAU.loadSampleData(from: AKSampleDataDescriptor(sampleDescriptor: sd,
                                                                                        sampleRate: sampleRate,
                                                                                        isInterleaved: false,
                                                                                        channelCount: channelCount,
                                                                                        sampleCount: sampleCount,
                                                                                        data: data.baseAddress) )
                            }
                            completion(true)
                        } catch {
                            completion(false)
                        }
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    
    func buildKeyMap(trackIndex: track_index_t, completion: @escaping (Bool) -> Void) {
        if let avAudioUnit = getAvAudioUnits()[trackIndex] {
            if let akSamplerAU = avAudioUnit.auAudioUnit as? AKSamplerAudioUnit {
                akSamplerAU.buildSimpleKeyMap()
                completion(true)
            } else {
                completion(false)
            }
        } else {
            completion(false)
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
                    
                    if let url = self.getUrlForPath(sf2Path, isAsset: isAsset) {
                        
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
                self.engine.attach(avAudioUnit)
                let auOutputFormat = avAudioUnit.outputFormat(forBus: 0)
            
                self.engine.connect(avAudioUnit, to: self.engine.outputNode, format: auOutputFormat)
                
                completion()
            }
        }
    }
    
    func connect(avAudioUnit: AVAudioUnit, trackIndex: Int32) {
        self.engine.attach(avAudioUnit)
        let auOutputFormat = avAudioUnit.outputFormat(forBus: 0)

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
    
    private func getUrlForPath(_ path: String, isAsset: Bool) -> URL? {
        if (!isAsset) {
            return URL(fileURLWithPath: path)
        } else {
            let key = registrar.lookupKey(forAsset: path)
            let bundlePath = Bundle.main.path(forResource: key, ofType: nil)
            
            if let bundlePath = bundlePath {
                return URL(fileURLWithPath: bundlePath)
            } else {
                return nil
            }
        }
    }
}
