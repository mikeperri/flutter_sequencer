#include <thread>
#include "AndroidEngine/AndroidEngine.h"
#include "Engine/SamplerInstrument.h"
#include "Engine/SoundFontInstrument.h"
#include "Utils/OptionArray.h"

std::unique_ptr<AndroidEngine> engine;

void check_engine() {
    if (engine.get() == NULL) {
        throw std::runtime_error("Engine is not set up. Ensure that setup_engine() is called before calling this method.");
    }
}

extern "C" {
    __attribute__((visibility("default"))) __attribute__((used))
    void setup_engine(Dart_Port sampleRateCallbackPort) {
        engine = std::make_unique<AndroidEngine>(sampleRateCallbackPort);
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void destroy_engine() {
        engine.reset();
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void add_track_sampler(Dart_Port trackIndexCallbackPort) {
        check_engine();

        std::thread([=]() {
            auto sampleRate = engine->getSampleRate();
            auto channelCount = engine->getChannelCount();
            auto isStereo = channelCount > 1;
            auto samplerInstrument = new SamplerInstrument(sampleRate, isStereo);

            auto trackIndex = engine->mSchedulerMixer.addTrack(samplerInstrument);

            callbackToDartInt32(trackIndexCallbackPort, trackIndex);
        }).detach();
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void add_sample_to_sampler(
        track_index_t trackIndex,
        char* samplePath,
        bool isAsset,
        int noteNumber,
        float noteFrequency,
        int minimumNoteNumber,
        int maximumNoteNumber,
        int minimumVelocity,
        int maximumVelocity,
        bool isLooping,
        float loopStartPoint,
        float loopEndPoint,
        float startPoint,
        float endPoint,
        Dart_Port resultCallbackPort
    ) {
        check_engine();
        std::string samplePathStr { samplePath };

        std::thread([=]() {
            AKSampleDescriptor sampleDescriptor = {
                    .noteNumber = noteNumber,
                    .noteFrequency = noteFrequency,
                    .minimumNoteNumber = minimumNoteNumber,
                    .maximumNoteNumber = maximumNoteNumber,
                    .minimumVelocity = minimumVelocity,
                    .maximumVelocity = maximumVelocity,
                    .isLooping = isLooping,
                    .loopStartPoint = loopStartPoint,
                    .loopEndPoint = loopEndPoint,
                    .startPoint = startPoint,
                    .endPoint = endPoint,
            };

            auto instrument = engine->mSchedulerMixer.getTrack(trackIndex);

            if (!instrument.has_value()) {
                callbackToDartBool(resultCallbackPort, false);
                return;
            }

            auto samplerInstrument = dynamic_cast<SamplerInstrument *>(instrument.value());

            if (samplerInstrument == nullptr) {
                callbackToDartBool(resultCallbackPort, false);
                return;
            }

            auto loadSampleResult = samplerInstrument->loadSample(samplePathStr, sampleDescriptor,
                                                                  isAsset);

            callbackToDartBool(resultCallbackPort, loadSampleResult);
        }).detach();
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void build_key_map(track_index_t trackIndex, Dart_Port resultCallbackPort) {
        auto instrument = engine->mSchedulerMixer.getTrack(trackIndex);

        if (!instrument.has_value()) {
            callbackToDartBool(resultCallbackPort, false);
            return;
        }

        auto samplerInstrument = dynamic_cast<SamplerInstrument *>(instrument.value());

        samplerInstrument->buildKeyMap();

        callbackToDartBool(resultCallbackPort, true);
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void add_track_sf2(const char* filename, bool isAsset, int32_t presetIndex, Dart_Port callbackPort) {
        check_engine();

        std::thread([=]() {
            auto sampleRate = engine->getSampleRate();
            auto channelCount = engine->getChannelCount();
            auto isStereo = channelCount > 1;

            auto sf2Instrument = new SoundFontInstrument(sampleRate, isStereo, filename, isAsset, presetIndex);
            auto trackIndex = engine->mSchedulerMixer.addTrack(sf2Instrument);

            callbackToDartInt32(callbackPort, trackIndex);
        }).detach();
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void remove_track(track_index_t trackIndex) {
        check_engine();

        engine->mSchedulerMixer.removeTrack(trackIndex);
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void reset_track(track_index_t trackIndex) {
        check_engine();

        engine->mSchedulerMixer.resetTrack(trackIndex);
    }

    __attribute__((visibility("default"))) __attribute__((used))
    float get_track_volume(track_index_t trackIndex) {
        check_engine();

        return engine->mSchedulerMixer.getLevel(trackIndex);
    }

    __attribute__((visibility("default"))) __attribute__((used))
    int32_t get_position() {
        check_engine();

        return engine->mSchedulerMixer.getPosition();
    }

    __attribute__((visibility("default"))) __attribute__((used))
    uint64_t get_last_render_time_us() {
        check_engine();

        return engine->mSchedulerMixer.getLastRenderTimeUs();
    }

    __attribute__((visibility("default"))) __attribute__((used))
    uint32_t get_buffer_available_count(track_index_t trackIndex) {
        return engine->mSchedulerMixer.getBufferAvailableCount(trackIndex);
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void handle_events_now(track_index_t trackIndex, const uint8_t* eventData, int32_t eventsCount) {
        check_engine();

        SchedulerEvent events[eventsCount];

        rawEventDataToEvents(eventData, eventsCount, events);

        engine->mSchedulerMixer.handleEventsNow(trackIndex, events, eventsCount);
    }

    __attribute__((visibility("default"))) __attribute__((used))
    int32_t schedule_events(track_index_t trackIndex, const uint8_t* eventData, int32_t eventsCount) {
        check_engine();

        SchedulerEvent events[eventsCount];

        rawEventDataToEvents(eventData, eventsCount, events);

        return engine->mSchedulerMixer.scheduleEvents(trackIndex, events, eventsCount);
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void clear_events(track_index_t trackIndex, position_frame_t fromFrame) {
        check_engine();

        return engine->mSchedulerMixer.clearEvents(trackIndex, fromFrame);
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void engine_play() {
        check_engine();

        engine->play();
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void engine_pause() {
        check_engine();

        engine->pause();
    }
}
