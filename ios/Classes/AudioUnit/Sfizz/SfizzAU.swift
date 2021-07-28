/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An AUAudioUnit subclass implementing a low-pass filter with resonance.
*/

import Foundation
import AudioToolbox
import AVFoundation
import CoreAudioKit

public class SfizzAU: AUAudioUnit {

    private let kernelAdapter: SfizzDSPKernelAdapter

    lazy private var inputBusArray: AUAudioUnitBusArray = {
        AUAudioUnitBusArray(audioUnit: self,
                            busType: .input,
                            busses: [kernelAdapter.inputBus])
    }()

    lazy private var outputBusArray: AUAudioUnitBusArray = {
        AUAudioUnitBusArray(audioUnit: self,
                            busType: .output,
                            busses: [kernelAdapter.outputBus])
    }()

    /// The filter's input busses
    public override var inputBusses: AUAudioUnitBusArray {
        return inputBusArray
    }

    /// The filter's output busses
    public override var outputBusses: AUAudioUnitBusArray {
        return outputBusArray
    }

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {

        // Create adapter to communicate to underlying C++ DSP code
        kernelAdapter = SfizzDSPKernelAdapter()

        // Init super class
        try super.init(componentDescription: componentDescription, options: options)
    }

    public override var maximumFramesToRender: AUAudioFrameCount {
        get {
            return kernelAdapter.maximumFramesToRender
        }
        set {
            if !renderResourcesAllocated {
                kernelAdapter.maximumFramesToRender = newValue
            }
        }
    }

    public override func allocateRenderResources() throws {
        if kernelAdapter.outputBus.format.channelCount != kernelAdapter.inputBus.format.channelCount {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_FailedInitialization), userInfo: nil)
        }
        try super.allocateRenderResources()
        kernelAdapter.allocateRenderResources()
    }

    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
        kernelAdapter.deallocateRenderResources()
    }

    public override var internalRenderBlock: AUInternalRenderBlock {
        return kernelAdapter.internalRenderBlock()
    }

    // Boolean indicating that this AU can process the input audio in-place
    // in the input buffer, without requiring a separate output buffer.
    public override var canProcessInPlace: Bool {
        return true
    }
    
    public func loadSfzFile(path: UnsafePointer<CChar>, tuningPath: UnsafePointer<CChar>) -> Bool {
        return kernelAdapter.loadSfzFile(path, tuningPath: tuningPath)
    }
    
    public func loadSfzString(sampleRoot: UnsafePointer<CChar>, sfzString: UnsafePointer<CChar>, tuningString: UnsafePointer<CChar>) -> Bool {
        return kernelAdapter.loadSfzString(sampleRoot, sfzString: sfzString, tuningString: tuningString)
    }
    
    public static var componentDescription: AudioComponentDescription = {
        
        // Ensure that AudioUnit type, subtype, and manufacturer match the extension's Info.plist values
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = kAudioUnitType_MusicDevice
        componentDescription.componentSubType = 0x7366697a /*'sfizz'*/
        componentDescription.componentManufacturer = 0x6d706673 /*'mpfs'*/
        componentDescription.componentFlags = 0
        componentDescription.componentFlagsMask = 0

        return componentDescription
    }()
    
    public static var componentName = "FlutterSequencerSfizz"
    
    public static func registerAU() -> Void {
        AUAudioUnit.registerSubclass(SfizzAU.self,
                                     as: componentDescription,
                                     name: componentName,
                                     version: UInt32.max)
    }
}
