#ifndef SFZ_INSTRUMENT_H
#define SFZ_INSTRUMENT_H

#include "AKCoreSampler.hpp"
#include "Decoders.h"

#include "IInstrument.h"
#include "../Utils/AssetManager.h"

class SamplerInstrument : public IInstrument {
public:
    SamplerInstrument(int32_t sampleRate, bool isStereo) {
        mChannelCount = isStereo ? 2 : 1;

        mSampler = std::make_unique<AKCoreSampler>();
        mSampler->init(double(sampleRate));
    }

    ~SamplerInstrument() {
        mSampler->deinit();
    }

    bool loadSample(std::string path, AKSampleDescriptor sampleDescriptor, bool isAsset) {
        LOGI("Loading sample %s", path.c_str());

        auto audioData =
                isAsset
                    ? loadSampleFromAsset(path)
                    : loadSampleFromFile(path);

        if (!audioData.has_value()) return false;

        AKSampleDataDescriptor sdd = {
                .sampleDescriptor = sampleDescriptor,
                .sampleRate = float(audioData.value().sampleRate),
                .isInterleaved = true,
                .channelCount = audioData.value().channelCount,
                .sampleCount = int(audioData.value().samples.size() / audioData.value().channelCount),
                .data = audioData.value().samples.data(),
        };

        mSampler->loadSampleData(sdd);

        return true;
    }

    void buildKeyMap() {
        mSampler->buildSimpleKeyMap();
    }

    void renderAudio(float *audioData, int32_t numFrames) override {
        float leftBuffer[numFrames];
        float rightBuffer[numFrames];
        float* buffers[2];

        buffers[0] = leftBuffer;
        buffers[1] = rightBuffer;

        for (int f = 0; f < numFrames; f++) {
            leftBuffer[f] = 0.;
            rightBuffer[f] = 0.;
        }

        mSampler->render(mChannelCount, numFrames, buffers);

        for (int f = 0; f < numFrames; f++) {
            for (int c = 0; c < 2; c++) {
                audioData[f * 2 + c] = buffers[c][f];
            }
        }
    }

    void handleMidiEvent(uint8_t status, uint8_t data1, uint8_t data2) override {
        if (status == 0x90) {
            // Note On
            mSampler->playNote(data1, data2);
        } else if (status == 0x80) {
            // Note Off
            mSampler->stopNote(data1, false);
        }
    }

    void reset() override {
    }

private:
    std::unique_ptr<AKCoreSampler> mSampler;
    int32_t mChannelCount;

    std::optional<nqr::AudioData> loadSampleFromAsset(std::string path) {
        auto nyquistLoader = std::make_unique<nqr::NyquistIO>();
        auto asset = openAssetBuffer(path.c_str());

        if (asset == nullptr) return std::nullopt;

        auto assetBuffer = ((uint8_t*) AAsset_getBuffer(asset));
        auto assetLength = AAsset_getLength(asset);

        std::vector<uint8_t> assetDataVector { assetBuffer, assetBuffer + assetLength };
        AAsset_close(asset);
        nqr::AudioData audioData;

        auto fileExtension = path.substr(path.find_last_of(".") + 1);

        try {
            nyquistLoader->Load(&audioData, fileExtension, assetDataVector);
            LOGI("Successfully loaded sample %s", path.c_str());
        } catch (const std::exception& e) {
            LOGE("Could not load sample %s: %s", path.c_str(), e.what());
            return std::nullopt;
        }

        return std::optional(audioData);
    }

    std::optional<nqr::AudioData> loadSampleFromFile(std::string path) {
        auto nyquistLoader = std::make_unique<nqr::NyquistIO>();
        nqr::AudioData audioData;

        // "/storage/emulated/0/Android/data/com.michaeljperri.flutter_sequencer_example/files/sample.wav";
        try {
            nyquistLoader->Load(&audioData, path.c_str());
        } catch (const std::exception& e) {
            return std::nullopt;
        }

        return std::optional(audioData);
    }
};

#endif //SFZ_INSTRUMENT_H
