#ifndef Buffer_h
#define Buffer_h

#ifdef __cplusplus
#include "SchedulerEvent.h"
#include <atomic>

template <
    uint32_t BUFFER_SIZE = 1024,
    typename buffer_index_t = uint32_t
>
class Buffer {
public:
    buffer_index_t add(const SchedulerEvent* eventsToAdd, buffer_index_t toAddCount) {
        if (toAddCount == 0) return 0;
        buffer_index_t existingEventsCount = count();

        // Can fill remaining space, at most
        buffer_index_t maxEventsToAdd;

        if (existingEventsCount + toAddCount <= BUFFER_SIZE) {
            maxEventsToAdd = toAddCount;
        } else {
            maxEventsToAdd = BUFFER_SIZE - existingEventsCount;
        }

        for (buffer_index_t i = 0; i < maxEventsToAdd; i++) {
            mEvents[mask(mWritePosition + i)] = eventsToAdd[i];
        }

        mWritePosition += maxEventsToAdd;

        return maxEventsToAdd;
    }
    
    void clearAfter(position_frame_t frame) {
        buffer_index_t existingEventsCount = count();

        for (buffer_index_t i = mReadPosition; i - mReadPosition < existingEventsCount; i++) {
            if (mEvents[mask(i)].frame >= frame) {
                mWritePosition = i;
                break;
            }
        }
    }

    bool peek(SchedulerEvent& event) {
        if (isEmpty()) {
            return false;
        } else {
            event = mEvents[mask(mReadPosition)];
            return true;
        }
    }

    bool removeTop() {
        if (isEmpty()) {
            return false;
        } else {
            mReadPosition++;
            return true;
        }
    }
    
    void clear() {
        buffer_index_t lastReadPosition = mReadPosition;
        mWritePosition = lastReadPosition;
    }

    buffer_index_t count() {
        return mWritePosition - mReadPosition;
    }
    
    buffer_index_t availableCount() {
        return BUFFER_SIZE - count();
    }

private:
    std::atomic<buffer_index_t> mReadPosition { 0 };
    std::atomic<buffer_index_t> mWritePosition { 0 };
    SchedulerEvent mEvents[BUFFER_SIZE];

    bool isEmpty() {
        return mReadPosition == mWritePosition;
    }

    bool isFull() {
        return count() == BUFFER_SIZE;
    }

    buffer_index_t mask(buffer_index_t n) {
        return static_cast<buffer_index_t>(n & (BUFFER_SIZE - 1));
    }
};
#endif

#endif /* Buffer_h */
