/*
 * Adapted from https://github.com/google/oboe/blob/master/samples/shared/Mixer.h
 * This is used on Android only, on iOS we use the built in mixer
 */

#ifndef MIXER_H
#define MIXER_H

#include <array>
#include <optional>
#include "BaseScheduler.h"
#include "IRenderableAudio.h"
#include "../Utils/OptionArray.h"
#include "../Utils/Logging.h"

constexpr int32_t kBufferSize = 192*10;  // Temporary buffer is used for mixing
constexpr uint8_t kMaxTracks = 100;

/**
 * A Mixer object which sums the output from multiple tracks into a single output. The number of
 * input channels on each track must match the number of output channels (default 1=mono). This can
 * be changed by calling `setChannelCount`.
 * The inputs to the mixer are not owned by the mixer, they should not be deleted while rendering.
 */

struct TrackInfo {
    IInstrument* track;
    float level;
};

class Mixer : public IRenderableAudio, public BaseScheduler {

public:
    Mixer() {
        static_assert(std::is_base_of<IRenderableAudio, IInstrument>::value, "TTrack must be derived from IRenderableAudio");
    }

    void renderAudio(float *audioData, int32_t numFrames) {
        if (numFrames == 0) {
            return;
        }

        // Zero out the incoming container array
        memset(audioData, 0, sizeof(float) * numFrames * mChannelCount);

        for (std::pair<track_index_t, TrackInfo> pair : mTrackMap) {
            auto trackIndex = pair.first;
            auto trackInfo = pair.second;

            handleFrames(trackIndex, numFrames);

            for (int j = 0; j < numFrames * mChannelCount; ++j) {
                audioData[j] += mixingBuffer[j] * trackInfo.level;
            }
        }
    }

    void handleRenderAudioRange(track_index_t trackIndex, uint32_t offsetFrame, uint32_t numFramesToRender) {
        if (numFramesToRender == 0) return;

        auto offsetMixingBuffer = mixingBuffer + offsetFrame * mChannelCount;

        auto maybeTrackInfo = getTrackInfo(trackIndex);
        if (maybeTrackInfo.has_value()) {
            auto trackInfo = maybeTrackInfo.value();
            IInstrument *track = trackInfo.track;
            track->renderAudio(offsetMixingBuffer, numFramesToRender);
        }
    }

    void handleEvent(track_index_t trackIndex, SchedulerEvent event, position_frame_t offsetFrame) {
        if (event.type == VOLUME_EVENT) {
            auto volumeEvent = VolumeEventData(event.data);

            setLevel(trackIndex, volumeEvent.volume);
        } else if (event.type == MIDI_EVENT) {
            auto midiEvent = MidiEventData(event.data);
            auto track = getTrack(trackIndex);

            if (track.has_value()) {
                // if (midiEvent.midiStatus == 144) {
                //     LOGI("Track %i: note on %i", trackIndex, midiEvent.midiData1);
                // } else if (midiEvent.midiStatus == 128) {
                //     LOGI("Track %i: note off %i", trackIndex, midiEvent.midiData1);
                // }
                track.value()->handleMidiEvent(midiEvent.midiStatus, midiEvent.midiData1, midiEvent.midiData2);
            }
        }
    }

    track_index_t addTrack(IInstrument *track) {
        auto trackIndex = BaseScheduler::addTrack();

        TrackInfo trackInfo;
        trackInfo.track = track;
        trackInfo.level = 1.0;

        mTrackMap.insert({ trackIndex, trackInfo });

        return trackIndex;
    }

    void onRemoveTrack(track_index_t trackIndex) {
        mTrackMap.erase(trackIndex);
    }

    std::optional<IInstrument*> getTrack(track_index_t trackIndex) {
        auto maybeTrackInfo = getTrackInfo(trackIndex);

        if (maybeTrackInfo.has_value()) {
            return maybeTrackInfo.value().track;
        } else {
            return std::nullopt;
        }
    }

    void onResetTrack(track_index_t trackIndex) {
        auto search = mTrackMap.find(trackIndex);

        if (search != mTrackMap.end()) {
            auto trackInfo = search->second;
            IInstrument *track = trackInfo.track;

            track->reset();
        }
    }

    void setLevel(track_index_t trackIndex, float level) {
        auto maybeTrackInfo = getTrackInfo(trackIndex);

        if (maybeTrackInfo.has_value()) {
            TrackInfo nextTrackInfo = maybeTrackInfo.value();
            nextTrackInfo.level = level;
            mTrackMap.insert_or_assign(trackIndex, nextTrackInfo);
        }
    }

    float getLevel(track_index_t trackIndex) {
        auto maybeTrackInfo = getTrackInfo(trackIndex);

        if (maybeTrackInfo.has_value()) {
            TrackInfo nextTrackInfo = maybeTrackInfo.value();
            return nextTrackInfo.level;
        } else {
            return 0.0;
        }
    }

    int32_t getChannelCount() { return mChannelCount; }
    void setChannelCount(int32_t channelCount) { mChannelCount = channelCount; }

private:
    std::optional<TrackInfo> getTrackInfo(track_index_t trackIndex) {
        auto search = mTrackMap.find(trackIndex);

        if (search != mTrackMap.end()) {
            return std::optional(search->second);
        } else {
            return std::nullopt;
        }
    }

    float mixingBuffer[kBufferSize];
    std::unordered_map<track_index_t, TrackInfo> mTrackMap = {};
    int32_t mChannelCount = 1; // Default to mono
};

#endif //MIXER_H
