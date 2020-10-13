#include "BaseScheduler.h"

#include <limits>
#include "SchedulerEvent.h"

track_index_t BaseScheduler::addTrack() {
    auto maxTracks = std::numeric_limits<track_index_t>::max();
    
    for (track_index_t trackIndex = 0; trackIndex < maxTracks; trackIndex++) {
        if (mBufferMap[trackIndex] == nullptr) {
            auto buffer = std::make_shared<Buffer<>>();
            
            mBufferMap[trackIndex] = buffer;
            
            return trackIndex;
        }
    }
    
    return -1;
}

void BaseScheduler::removeTrack(track_index_t trackIndex) {
    mBufferMap.erase(trackIndex);

    onRemoveTrack(trackIndex);
}

void BaseScheduler::handleEventsNow(track_index_t trackIndex, const SchedulerEvent* events, uint32_t eventsCount) {
    for (uint32_t i = 0; i < eventsCount; i++) {
        handleEvent(trackIndex, events[i], 0);
    }
}

uint32_t BaseScheduler::scheduleEvents(track_index_t trackIndex, const SchedulerEvent* events, uint32_t eventsCount) {
    // Events must come after anything already in the buffer and be sorted by frame, ascending.
    return mBufferMap[trackIndex]->add(events, eventsCount);
};

void BaseScheduler::clearEvents(track_index_t trackIndex, position_frame_t fromFrame) {
    mBufferMap[trackIndex]->clearAfter(fromFrame);
};

void BaseScheduler::play() {
    if (mIsPlaying) return;

    mIsPlaying = true;
};

void BaseScheduler::pause() {
    if (!mIsPlaying) return;
    
    mIsPlaying = false;
};

void BaseScheduler::resetTrack(track_index_t trackIndex) {
    SchedulerEvent events[128];
    for (uint8_t noteNumber = 0; noteNumber < 128; noteNumber++) {
        events[noteNumber].frame = 0;
        events[noteNumber].type = MIDI_EVENT;
        events[noteNumber].data[0] = 128;
        events[noteNumber].data[1] = noteNumber;
        events[noteNumber].data[2] = 0;
    }
    handleEventsNow(trackIndex, std::as_const(events), 128);

    onResetTrack(trackIndex);
}

uint32_t BaseScheduler::getBufferAvailableCount(track_index_t trackIndex) {
    return mBufferMap[trackIndex]->availableCount();
}

position_frame_t BaseScheduler::getPosition() {
    return mPositionFrames;
}

uint64_t BaseScheduler::getLastRenderTimeUs() {
    timeval t;
    gettimeofday(&t, NULL);
    return t.tv_sec*uint64_t(1000000) + uint64_t(t.tv_usec);
}

void BaseScheduler::handleFrames(track_index_t trackIndex, uint32_t numFramesToRender) {
    if (!mIsPlaying) return;
    
    auto buffer = mBufferMap[trackIndex];
    auto originalPositionFrames = mPositionFrames; // so we can check if setPosition was called
    auto startFrame = mPositionFrames;
    auto lastFrameRendered = startFrame;
    uint32_t framesRendered = 0;

    SchedulerEvent nextEvent;

    while (buffer->peek(nextEvent)) {
        auto eventFrame = nextEvent.frame;
        
        if (eventFrame < startFrame) {
            // Skip events that are more than 1024 frames the past
            if (eventFrame + 1024 < startFrame) {
                // printf("Track %i: Skipping event with frame %i, which is less than start frame %i\n", trackIndex, eventFrame, startFrame);
                buffer->removeTop();
                continue;
            } else {
                // printf("Track %i: Accepting late event with frame %i, which is less than start frame %i\n", trackIndex, eventFrame, startFrame);
                eventFrame = startFrame;
            }
        }

        // If the next event is after numFramesToRender, then ignore it for now and just render
        if ((framesRendered + eventFrame - lastFrameRendered) >= numFramesToRender) {
            break;
        }

        // Render frames until event
        handleRenderAudioRange(trackIndex, framesRendered, eventFrame - lastFrameRendered);
        framesRendered += (eventFrame - lastFrameRendered);
        lastFrameRendered = eventFrame;
        
        handleEvent(trackIndex, nextEvent, framesRendered);
        buffer->removeTop();
    }
    
    handleRenderAudioRange(trackIndex, framesRendered, numFramesToRender - framesRendered);
    

    mHasRenderedMap[trackIndex] = true;
    bool allTracksHaveRendered = true;
    
    for (auto pair : mHasRenderedMap) {
        if (pair.second == false) {
            allTracksHaveRendered = false;
            break;
        }
    }
    
    if (allTracksHaveRendered) {
        // Don't update the position if setPosition was called during this function
        if (mPositionFrames == originalPositionFrames) {
            mPositionFrames = startFrame + numFramesToRender;
            // printf("Track %i: Updated position to %i\n", trackIndex, mPositionFrames);
        // } else {
            // printf("Track %i: Not updating position since it changed during render\n", trackIndex);
        }
        
        for (auto pair : mHasRenderedMap) {
            mHasRenderedMap[pair.first] = false;
        }
    }
}
