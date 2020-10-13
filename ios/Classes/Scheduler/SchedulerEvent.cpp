#include <algorithm>
#include "SchedulerEvent.h"

// Remember to keep lib/models/events.dart in sync with this file.

MidiEventData::MidiEventData() {}

MidiEventData::MidiEventData(uint8_t* data) {
    this->midiStatus = *data;
    this->midiData1 = *(data + 1);
    this->midiData2 = *(data + 2);
}

VolumeEventData::VolumeEventData(uint8_t* data) {
    this->volume = *(float*)data;
}

void rawEventDataToEvents(const uint8_t* rawEventData, uint32_t eventsCount, struct SchedulerEvent* events) {
    for (int32_t i = 0; i < eventsCount; i++) {
        const uint8_t* nextEventPtr = rawEventData + (i * sizeof(SchedulerEvent));
        
        events[i].frame = *(position_frame_t*)nextEventPtr;
        events[i].type = *(uint32_t*)(nextEventPtr + sizeof(position_frame_t));
        
        auto dataOffset = sizeof(position_frame_t) + sizeof(uint32_t);
        std::copy(nextEventPtr + dataOffset, nextEventPtr + dataOffset + SCHEDULER_EVENT_DATA_SIZE, events[i].data);
    }
}
