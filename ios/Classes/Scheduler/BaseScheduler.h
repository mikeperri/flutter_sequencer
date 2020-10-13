#ifndef BaseScheduler_h
#define BaseScheduler_h
#include <stdint.h>

typedef int32_t track_index_t;

#ifdef __cplusplus
#include <memory>
#include <unordered_map>
#include <sys/time.h>
#include <Buffer.h>
#include <CallbackManager.h>
#include <SchedulerEvent.h>

class BaseScheduler {
public:
    track_index_t addTrack();
    void removeTrack(track_index_t trackIndex);
    virtual void onRemoveTrack(track_index_t trackIndex) = 0; // Will be called at the end of removeTrack.

    void handleEventsNow(track_index_t trackIndex, const SchedulerEvent* events, uint32_t eventsCount);
    uint32_t scheduleEvents(track_index_t trackIndex, const SchedulerEvent* events, uint32_t eventsCount);
    void clearEvents(track_index_t trackIndex, position_frame_t fromFrame);
    void play();
    void pause();
    void resetTrack(track_index_t trackIndex);
    virtual void onResetTrack(track_index_t trackIndex) = 0;

    void handleFrames(track_index_t trackIndex, uint32_t numFramesToRender);
    virtual void handleRenderAudioRange(track_index_t trackIndex, uint32_t offsetFrame, uint32_t numFramesToRender) = 0;
    virtual void handleEvent(track_index_t trackIndex, SchedulerEvent event, position_frame_t offsetFrame) = 0;

    uint32_t getBufferAvailableCount(track_index_t trackIndex);
    position_frame_t getPosition();
    uint64_t getLastRenderTimeUs();
protected:
    std::unordered_map<track_index_t, std::shared_ptr<Buffer<>>> mBufferMap = {};
    std::unordered_map<track_index_t, bool> mHasRenderedMap = {};
private:
    bool mIsPlaying = false;
    position_frame_t mPositionFrames = 0;
};

#endif
#endif /* BaseScheduler_h */
