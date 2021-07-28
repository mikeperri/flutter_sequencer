import AVFoundation

func isAppleSampler(component: AVAudioUnitComponent) -> Bool {
    let isApple = component.audioComponentDescription.componentManufacturer == kAudioUnitManufacturer_Apple
    let isMIDISynth = component.audioComponentDescription.componentSubType == kAudioUnitSubType_MIDISynth

    return isApple && isMIDISynth
}

func loadSoundFont(avAudioUnit: AVAudioUnit, soundFontURL: URL, presetIndex: Int32) {
    assert(avAudioUnit.audioComponentDescription.componentSubType == kAudioUnitSubType_MIDISynth)
    
    let audioUnit = avAudioUnit.audioUnit
    var mutableSoundFontURL = soundFontURL
    
    // Load SoundFont
    var result = AudioUnitSetProperty(audioUnit,
                                 AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
                                 AudioUnitScope(kAudioUnitScope_Global),
                                 0,
                                 &mutableSoundFontURL,
                                 UInt32(MemoryLayout.size(ofValue: mutableSoundFontURL)))
    assert(result == noErr, "SoundFont could not be loaded")

    var enabled = UInt32(1)
    
    // Enable preload
    result = AudioUnitSetProperty(audioUnit,
                                  AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
                                  AudioUnitScope(kAudioUnitScope_Global),
                                  0,
                                  &enabled,
                                  UInt32(MemoryLayout.size(ofValue: enabled)))
    assert(result == noErr, "Preload could not be enabled")
    
    // Send program change command for patch 0 to preload
    let channel = UInt32(0)
    let pcCommand = UInt32(0xC0 | channel)
    let patch1 = UInt32(presetIndex)
    result = MusicDeviceMIDIEvent(audioUnit, pcCommand, patch1, 0, 0)
    assert(result == noErr, "Patch could not be preloaded")
    
    // Disable preload
    enabled = UInt32(0)
    result = AudioUnitSetProperty(audioUnit,
                                  AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
                                  AudioUnitScope(kAudioUnitScope_Global),
                                  0,
                                  &enabled,
                                  UInt32(MemoryLayout.size(ofValue: enabled)))

    assert(result == noErr, "Preload could not be disabled")

    result = MusicDeviceMIDIEvent(audioUnit, pcCommand, patch1, 0, 0)
    assert(result == noErr, "Patch could not be changed")
}
