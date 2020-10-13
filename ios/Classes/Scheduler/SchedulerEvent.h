#ifndef SchedulerEvent_h
#define SchedulerEvent_h

typedef uint32_t position_frame_t;

const int SCHEDULER_EVENT_DATA_SIZE = 8;

struct SchedulerEvent {
    position_frame_t frame;
    uint32_t type; // This could be a uint8_t, but then we get alignment errors on Android devices, like this: https://stackoverflow.com/questions/43559712/
    uint8_t data[SCHEDULER_EVENT_DATA_SIZE];
};

enum EventType {
    MIDI_EVENT = 0,
    VOLUME_EVENT = 1,
};

#ifdef __cplusplus
class MidiEventData {
public:
    MidiEventData();
    MidiEventData(uint8_t* data);

    uint8_t midiStatus;
    uint8_t midiData1;
    uint8_t midiData2;
};

class VolumeEventData {
public:
    VolumeEventData(uint8_t* data);
    
    float volume;
};
#endif

#ifdef __cplusplus
extern "C" {
#endif
void rawEventDataToEvents(const uint8_t* rawEventData, uint32_t eventsCount, struct SchedulerEvent* events);
#ifdef __cplusplus
}
#endif

#endif /* SchedulerEvent_h */
