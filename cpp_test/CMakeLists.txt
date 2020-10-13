cmake_minimum_required(VERSION 3.11)
project(SequencerTests)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)
enable_testing()

## BEGIN GoogleTest setup ##
SET(GOOGLETEST_DIR ${CMAKE_CURRENT_BINARY_DIR}/googletest)
file(MAKE_DIRECTORY ${GOOGLETEST_DIR})
configure_file(CMakeLists.txt.in ${GOOGLETEST_DIR}/googletest-download/CMakeLists.txt)

execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${GOOGLETEST_DIR}/googletest-download )
if(result)
  message(FATAL_ERROR "CMake step for googletest failed: ${result}")
endif()
execute_process(COMMAND ${CMAKE_COMMAND} --build .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${GOOGLETEST_DIR}/googletest-download )
if(result)
  message(FATAL_ERROR "Build step for googletest failed: ${result}")
endif()

# Prevent overriding the parent project's compiler/linker
# settings on Windows
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

# Add googletest directly to our build. This defines
# the gtest and gtest_main targets.
add_subdirectory(${GOOGLETEST_DIR}/googletest-src
                 ${GOOGLETEST_DIR}/googletest-build
                 EXCLUDE_FROM_ALL)
## END GoogleTest setup ##


set (SCHEDULER_DIR ../ios/Classes/Scheduler)

file (GLOB TEST_SRCS ./src/*.cpp)

add_executable(sequencer_test ${TEST_SRCS})
set_target_properties(sequencer_test PROPERTIES
    LINKER_LANGUAGE CXX
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})

target_link_libraries(sequencer_test gtest_main)
target_include_directories(sequencer_test PUBLIC ${SCHEDULER_DIR})

add_test(NAME test COMMAND sequencer_test)
