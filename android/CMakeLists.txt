Project(Sequencer)

CMake_Minimum_Required(VERSION 3.10.2)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

Set (OBOE_DIR ./third_party/oboe)
Add_Subdirectory (${OBOE_DIR} ./build/oboe)
Include_Directories (${OBOE_DIR}/include)
INCLUDE_DIRECTORIES(../ios/Classes/CallbackManager)
INCLUDE_DIRECTORIES(../ios/Classes/Scheduler)

Set (TSF_DIR ./third_party/TinySoundFont)
Include_Directories (${TSF_DIR})

SET (AUDIOKIT_CORE_DIR ./third_party/AudioKit/AudioKit/Core/AudioKitCore)
INCLUDE_DIRECTORIES(${AUDIOKIT_CORE_DIR}/Common)
INCLUDE_DIRECTORIES(${AUDIOKIT_CORE_DIR}/Sampler)

FILE(GLOB AUDIOKIT_CORE_SRCS
        ${AUDIOKIT_CORE_DIR}/Common/*.hpp
        ${AUDIOKIT_CORE_DIR}/Common/*.cpp
        ${AUDIOKIT_CORE_DIR}/Sampler/*.h
        ${AUDIOKIT_CORE_DIR}/Sampler/*.hpp
        ${AUDIOKIT_CORE_DIR}/Sampler/*.cpp
    )

SET(BUILD_EXAMPLE OFF CACHE BOOL "Build example application" FORCE)
SET (LIBNYQUIST_DIR ./third_party/libnyquist)
ADD_SUBDIRECTORY(${LIBNYQUIST_DIR})
INCLUDE_DIRECTORIES(${LIBNYQUIST_DIR}/include/libnyquist)

Add_Library(
        flutter_sequencer
        SHARED
        ../ios/Classes/CallbackManager/CallbackManager.h
        ../ios/Classes/CallbackManager/CallbackManager.cpp
        ../ios/Classes/Scheduler/BaseScheduler.h
        ../ios/Classes/Scheduler/BaseScheduler.cpp
        ../ios/Classes/Scheduler/Buffer.h
        ../ios/Classes/Scheduler/SchedulerEvent.h
        ../ios/Classes/Scheduler/SchedulerEvent.cpp
        ./src/main/cpp/AndroidEngine/AndroidEngine.h
        ./src/main/cpp/AndroidEngine/AndroidEngine.cpp
        ./src/main/cpp/Engine/IInstrument.h
        ./src/main/cpp/Engine/Mixer.h
        ./src/main/cpp/Engine/SoundFontInstrument.h
        ./src/main/cpp/Engine/SamplerInstrument.h
        ./src/main/cpp/Utils/AssetManager.h
        ./src/main/cpp/Utils/Logging.h
        ./src/main/cpp/Utils/OptionArray.h
        ./src/main/cpp/Plugin.cpp

        ${AUDIOKIT_CORE_SRCS}
    )

Find_Library(android-lib android)

Target_Link_Libraries(flutter_sequencer ${android-lib} oboe libnyquist)
