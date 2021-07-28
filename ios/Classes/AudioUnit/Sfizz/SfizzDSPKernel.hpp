/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A DSPKernel subclass implementing the realtime signal processing portion of the AUv3FilterDemo audio unit.
*/
#ifndef SfizzDSPKernel_hpp
#define SfizzDSPKernel_hpp

#ifdef __cplusplus
#import "DSPKernel.hpp"
#import "SfizzSamplerInstrument.h"
#import <vector>
#import <iostream>

/*
 SfizzDSPKernel
 Calls Sfizz render code and handles MIDI events.
 As a non-ObjC class, this is safe to use from render thread.
 */
class SfizzDSPKernel : public DSPKernel {
public:

    // MARK: Member Functions

    SfizzDSPKernel() {
        mInstrument = std::make_unique<SfizzSamplerInstrument>();
    }

    void init(int inChannelCount, double inSampleRate) {
        channelCount = inChannelCount;
        sampleRate = float(inSampleRate);
        mInstrument->setOutputFormat(sampleRate, channelCount > 1);
        mInstrument->setSamplesPerBlock(maximumFramesToRender());
    }

    void reset() {
    }

    void startRamp(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) override {
    }

    void setBuffers(AudioBufferList* inBufferList, AudioBufferList* outBufferList) {
        inBufferListPtr = inBufferList;
        outBufferListPtr = outBufferList;
    }
    
    bool loadFile(const char* sfzPath, const char* tuningPath) {
        return mInstrument->loadSfzFile(sfzPath, tuningPath);
    }

    bool loadString(const char* sfzPath, const char* sfzString, const char* tuningString) {
        return mInstrument->loadSfzString(sfzPath, sfzString, tuningString);
    }

    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {
        if (channelCount == 1) {
            // Mono
            float* outBuffer = (float*)outBufferListPtr->mBuffers[0].mData + bufferOffset;
            
            mInstrument->renderAudio(outBuffer, frameCount);
        } else {
            // Stereo
            float interlacedBuffer[frameCount * 2];
            mInstrument->renderAudio(interlacedBuffer, frameCount);
            
            float* leftOutBuffer = (float*)outBufferListPtr->mBuffers[0].mData + bufferOffset;
            float* rightOutBuffer = (float*)outBufferListPtr->mBuffers[1].mData + bufferOffset;
            
            // De-interlace
            for (int i = 0; i < frameCount; i++) {
                leftOutBuffer[i] = interlacedBuffer[i * 2];
                rightOutBuffer[i] = interlacedBuffer[(i * 2) + 1];
            }
        }
    }
    
    void handleMIDIEvent(AUMIDIEvent const& midiEvent) override {
        if (midiEvent.eventType == 8) {
            auto midiStatus = midiEvent.data[0];
            auto midiData1 = midiEvent.data[1];
            auto midiData2 = midiEvent.data[2];
            
            mInstrument->handleMidiEvent(midiStatus, midiData1, midiData2);
        }
    }

    // MARK: Member Variables

private:
    int channelCount;
    float sampleRate;

    AudioBufferList* inBufferListPtr = nullptr;
    AudioBufferList* outBufferListPtr = nullptr;

public:
    std::unique_ptr<SfizzSamplerInstrument> mInstrument;
};

#endif
#endif /* SfizzDSPKernel_hpp */
