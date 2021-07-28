#ifndef ANDROID_ENGINE_H
#define ANDROID_ENGINE_H

#include <oboe/Oboe.h>
#include "CallbackManager.h"
#include "IInstrument.h"
#include "../AndroidInstruments/Mixer.h"

class AndroidEngine : public oboe::AudioStreamCallback {
public:
    explicit AndroidEngine(Dart_Port sampleRateCallbackPort);
    ~AndroidEngine();

    oboe::DataCallbackResult onAudioReady(oboe::AudioStream *oboeStream, void *audioData, int32_t numFrames) override;

    int32_t getSampleRate();
    int32_t getChannelCount();
    int32_t getBufferSize();
    void play();
    void pause();

    Mixer mSchedulerMixer;
private:
    oboe::ManagedStream mOutStream;

    static int constexpr kSampleRate = 44100;
};

#endif //ANDROID_ENGINE_H
