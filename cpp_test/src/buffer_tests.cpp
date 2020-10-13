#include <gtest/gtest.h>
#include "Buffer.h"

typedef u_int8_t buffer_index_t;
const u_int32_t BUFFER_SIZE = 128;
using SmallBuffer = Buffer<BUFFER_SIZE, buffer_index_t>;

class BufferTest : public ::testing::Test {
protected:
    BufferTest(); // set up here
    virtual ~BufferTest(); // clean up here
    // virtual void SetUp(); // run before each test
    // virtual void TearDown(); // run after each test
};

BufferTest::BufferTest() {}
BufferTest::~BufferTest() {}

buffer_index_t addNEvents(SmallBuffer* buffer, buffer_index_t n, u_int8_t type, u_int32_t frameOffset) {
    SchedulerEvent events[n];

    for (buffer_index_t i = 0; i < n; i++) {
        events[i] = {
            .frame = static_cast<u_int32_t>(i * 10 + frameOffset),
            .type = type,
        };
    }

    return buffer->add(events, n);
}

void removeNEvents(SmallBuffer* buffer, buffer_index_t n) {
    for (buffer_index_t i = 0; i < n; i++) {
        buffer->removeTop();
    }
}

TEST_F(BufferTest, AddOverBufferSize) {
    SmallBuffer buffer = SmallBuffer();

    u_int32_t addResult = addNEvents(&buffer, BUFFER_SIZE + 100, 123, 0);
    EXPECT_EQ(addResult, BUFFER_SIZE);

    SchedulerEvent peekedEvent;
    buffer.peek(peekedEvent);

    EXPECT_EQ(peekedEvent.frame, 0);
    EXPECT_EQ(peekedEvent.type, 123);
}

TEST_F(BufferTest, RemoveAll) {
    SmallBuffer buffer = SmallBuffer();

    addNEvents(&buffer, 3, 111, 0);

    EXPECT_EQ(buffer.removeTop(), true);
    EXPECT_EQ(buffer.removeTop(), true);
    EXPECT_EQ(buffer.removeTop(), true);
    EXPECT_EQ(buffer.removeTop(), false);
}

TEST_F(BufferTest, AddAndRemoveAndAdd) {
    SmallBuffer buffer = SmallBuffer();

    addNEvents(&buffer, BUFFER_SIZE + 100, 111, 0);
    removeNEvents(&buffer, BUFFER_SIZE);
    EXPECT_EQ(buffer.removeTop(), false);

    addNEvents(&buffer, BUFFER_SIZE + 100, 111, 0);
    removeNEvents(&buffer, BUFFER_SIZE);
    EXPECT_EQ(buffer.removeTop(), false);

    addNEvents(&buffer, 1, 222, 0);

    SchedulerEvent peekedEvent;
    buffer.peek(peekedEvent);

    EXPECT_EQ(peekedEvent.type, 222);
}

TEST_F(BufferTest, Count) {
    SmallBuffer buffer = SmallBuffer();

    EXPECT_EQ(buffer.count(), 0);

    addNEvents(&buffer, 100, 111, 0);

    EXPECT_EQ(buffer.count(), 100);

    addNEvents(&buffer, 100, 222, 2000);

    EXPECT_EQ(buffer.count(), 128);

    buffer.clear();

    EXPECT_EQ(buffer.count(), 0);
}

TEST_F(BufferTest, ClearAfter) {
    SmallBuffer buffer = SmallBuffer();

    EXPECT_EQ(buffer.count(), 0);

    addNEvents(&buffer, 100, 111, 0);
    EXPECT_EQ(buffer.count(), 100);

    buffer.clearAfter(500);
    EXPECT_EQ(buffer.count(), 50);

    addNEvents(&buffer, 100, 111, 500);
    EXPECT_EQ(buffer.count(), 128);

    buffer.clearAfter(1000);
    EXPECT_EQ(buffer.count(), 100);

    buffer.clearAfter(0);
    EXPECT_EQ(buffer.count(), 0);
}
