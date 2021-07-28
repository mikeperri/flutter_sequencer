PROJECT(Sequencer)

CMAKE_MINIMUM_REQUIRED(VERSION 3.18.1)
SET(CMAKE_CXX_STANDARD 17)
SET(CMAKE_CXX_STANDARD_REQUIRED ON)

SET(OBOE_DIR ./third_party/oboe)
ADD_SUBDIRECTORY(${OBOE_DIR} ./build/oboe)
INCLUDE_DIRECTORIES(${OBOE_DIR}/include)

SET(TSF_DIR ./third_party/TinySoundFont)
INCLUDE_DIRECTORIES(${TSF_DIR})

OPTION(SFIZZ_JACK "" OFF)
OPTION(SFIZZ_RENDER "" OFF)
OPTION(SFIZZ_LV2 "" OFF)
OPTION(SFIZZ_LV2_UI "" OFF)
OPTION(SFIZZ_VST "" OFF)
OPTION(SFIZZ_AU "" OFF)
OPTION(SFIZZ_SHARED "" OFF)
SET(SFIZZ_DIR ./third_party/sfizz)
ADD_SUBDIRECTORY(${SFIZZ_DIR})

ADD_LIBRARY(flutter_sequencer SHARED)
TARGET_INCLUDE_DIRECTORIES(flutter_sequencer PRIVATE
        ../ios/Classes/CallbackManager
        ../ios/Classes/Scheduler
        ../ios/Classes/IInstrument
        )
TARGET_SOURCES(flutter_sequencer PRIVATE
        ../ios/Classes/CallbackManager/CallbackManager.h
        ../ios/Classes/CallbackManager/CallbackManager.cpp
        ../ios/Classes/Scheduler/BaseScheduler.h
        ../ios/Classes/Scheduler/BaseScheduler.cpp
        ../ios/Classes/Scheduler/Buffer.h
        ../ios/Classes/Scheduler/SchedulerEvent.h
        ../ios/Classes/Scheduler/SchedulerEvent.cpp
        ./src/main/cpp/AndroidEngine/AndroidEngine.h
        ./src/main/cpp/AndroidEngine/AndroidEngine.cpp
        ../ios/Classes/IInstrument/IInstrument.h
        ../ios/Classes/IInstrument/SharedInstruments/SfizzSamplerInstrument.h
        ./src/main/cpp/AndroidInstruments/Mixer.h
        ./src/main/cpp/AndroidInstruments/SoundFontInstrument.h
        ./src/main/cpp/Utils/AssetManager.h
        ./src/main/cpp/Utils/Logging.h
        ./src/main/cpp/Utils/OptionArray.h
        ./src/main/cpp/Plugin.cpp
        )

FIND_LIBRARY(android-lib android)

TARGET_LINK_LIBRARIES(flutter_sequencer ${android-lib} oboe sfizz_static)
