#!/bin/zsh

if [ ! -d third_party ]; then
    mkdir third_party
fi
cd third_party

if [ ! -d ios-cmake ]; then
    git clone https://github.com/leetal/ios-cmake.git
    cd ios-cmake
    git checkout a7a5dd0e9ca8e818c0d73a1d3da06d830fa45970
    cd ..
fi

if [ ! -d sfizz ]; then
    git clone https://github.com/sfztools/sfizz.git
    cd sfizz
    git checkout fc1f0451cebd8996992cbc4f983fcf76b03295c5
    git submodule update --init --recursive
    cd ..
fi

cd sfizz

if [ ! -d build ]; then
    mkdir build
fi

cd build

# Generate XCode project for Sfizz
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DSFIZZ_JACK=OFF \
    -DSFIZZ_RENDER=OFF \
    -DSFIZZ_LV2=OFF \
    -DSFIZZ_LV2_UI=OFF \
    -DSFIZZ_VST=OFF \
    -DSFIZZ_AU=OFF \
    -DSFIZZ_SHARED=OFF \
    -DCMAKE_TOOLCHAIN_FILE=../../ios-cmake/ios.toolchain.cmake \
    -DAPPLE_APPKIT_LIBRARY=/System/Library/Frameworks/AppKit.framework \
    -DAPPLE_CARBON_LIBRARY=/System/Library/Frameworks/Carbon.framework \
    -DAPPLE_COCOA_LIBRARY=/System/Library/Frameworks/Cocoa.framework \
    -DAPPLE_OPENGL_LIBRARY=/System/Library/Frameworks/OpenGL.framework \
    -DPLATFORM=OS64COMBINED \
    -G Xcode \
    ..

xcodebuild -project sfizz.xcodeproj -scheme ALL_BUILD -xcconfig ../../../overrides.xcconfig -configuration Release -destination "generic/platform=iOS" -destination "generic/platform=iOS Simulator"

# Create fat libraries
deviceLibs=(**/Release-iphoneos/*.a);
simulatorLibs=(**/Release-iphonesimulator/*.a);

libtool -static -o libsfizz_all_iphoneos.a $deviceLibs
libtool -static -o libsfizz_all_iphonesimulator.a $simulatorLibs
lipo \
    -create libsfizz_all_iphoneos.a libsfizz_all_iphonesimulator.a \
    -output libsfizz_fat.a
