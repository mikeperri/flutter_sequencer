#ifndef CocoaScheduler_h
#define CocoaScheduler_h

#include <AudioToolbox/AudioUnit.h>
#include "BaseScheduler.h"
#include "CallbackManager.h"
#include "SchedulerEvent.h"

const int MAX_TRACKS = 128;

#ifdef __cplusplus
#include <thread>

class CocoaScheduler : public BaseScheduler {
public:
    CocoaScheduler(AudioUnit _Nonnull mixerAudioUnit, double sampleRate);
    ~CocoaScheduler();

    void setTrackAudioUnit(track_index_t trackIndex, AudioUnit _Nonnull audioUnit);
    void onRemoveTrack(track_index_t trackIndex);
    
    void onResetTrack(track_index_t trackIndex);
    void handleRenderAudioRange(track_index_t trackIndex, uint32_t offsetFrame, uint32_t numFramesToRender);
    void handleEvent(track_index_t trackIndex, SchedulerEvent event, position_frame_t offsetFrame);
    float getTrackVolume(track_index_t trackIndex);
    int scaleFrames(track_index_t trackIndex, UInt32 inNumberFrames, bool isToDeviceFrames);
private:
    double getSampleRate(AudioUnit _Nonnull audioUnit);
    double mSampleRate;
    std::unordered_map<track_index_t, AudioUnit _Nonnull> mAudioUnitMap = {};
    std::unordered_map<track_index_t, double> mSampleRateMap = {};
    
    // Pairs from this map will be used as the "inRefCon" variable for AudioUnitAddRenderNotify.
    std::unordered_map<track_index_t, CocoaScheduler* _Nonnull> mInRefConMap = {};

    AudioUnit _Nonnull mMixerAudioUnit;
};

struct InRefCon {
    CocoaScheduler* _Nonnull scheduler;
    track_index_t trackIndex;
};
#endif


# ifdef __cplusplus
extern "C" {
#endif
void* _Nonnull InitScheduler(AudioUnit _Nonnull mixerAudioUnit, double sampleRate);
void DestroyScheduler(void* _Nonnull engine);
SInt32 SchedulerAddTrack(const void* _Nonnull engine);
void SchedulerSetTrackAudioUnit(const void* _Nonnull engine, track_index_t trackIndex, AudioUnit _Nonnull audioUnit);
void SchedulerRemoveTrack(const void* _Nonnull engine, track_index_t trackIndex);
UInt32 SchedulerGetBufferAvailableCount(const void* _Nonnull scheduler, track_index_t trackIndex);
void SchedulerHandleEventsNow(const void* _Nonnull engine, track_index_t trackIndex, const struct SchedulerEvent* _Nonnull events, UInt32 eventsCount);
UInt32 SchedulerAddEvents(const void* _Nonnull engine, track_index_t trackIndex, const struct SchedulerEvent* _Nonnull events, UInt32 eventsCount);
void SchedulerClearEvents(const void* _Nonnull engine, track_index_t trackIndex, position_frame_t fromFrame);
void SchedulerPlay(const void* _Nonnull engine);
void SchedulerPause(const void* _Nonnull engine);
void SchedulerResetTrack(const void* _Nonnull engine, track_index_t trackIndex);
UInt32 SchedulerGetPosition(const void* _Nonnull engine);
UInt64 SchedulerGetLastRenderTimeUs(const void* _Nonnull engine);
Float32 SchedulerGetTrackVolume(const void* _Nonnull engine, track_index_t trackIndex);
#ifdef __cplusplus
}
#endif

#endif /* CocoaScheduler_h */
