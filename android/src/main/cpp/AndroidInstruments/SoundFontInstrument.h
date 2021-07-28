/*
 * This is used on Android only, on iOS we use the built in SoundFont AudioUnit
 */

#ifndef SOUND_FONT_INSTRUMENT_H
#define SOUND_FONT_INSTRUMENT_H

#include "IInstrument.h"
#include "../Utils/AssetManager.h"

#define TSF_IMPLEMENTATION
#include "tsf.h"

class SoundFontInstrument : public IInstrument {
public:
    int presetIndex;

    SoundFontInstrument() {
    }

    ~SoundFontInstrument() {
        tsf_close(mTsf);
    }

    bool setOutputFormat(int32_t sampleRate, bool isStereo) override {
        mIsStereo = isStereo;
        mSampleRate = sampleRate;

        setTsfOutputFormat();

        return true;
    }

    void setTsfOutputFormat() {
        if (mTsf != nullptr) {
            tsf_set_output(mTsf, mIsStereo ? TSF_STEREO_INTERLEAVED : TSF_MONO, mSampleRate);
        }
    }

    bool loadSf2File(const char* path, bool isAsset, int32_t presetIndex) {
        this->presetIndex = presetIndex;

        if (isAsset) {
            auto asset = openAssetBuffer(path);
            auto assetBuffer = AAsset_getBuffer(asset);
            auto assetLength = AAsset_getLength(asset);

            mTsf = tsf_load_memory(assetBuffer, assetLength);

            AAsset_close(asset);
        } else {
            mTsf = tsf_load_filename(path);
        }

        setTsfOutputFormat();

        return mTsf != nullptr;
    }

    void renderAudio(float *audioData, int32_t numFrames) override {
        tsf_render_float(mTsf, audioData, numFrames);
    }

    void handleMidiEvent(uint8_t status, uint8_t data1, uint8_t data2) override {
        auto channel = status & 0x0F;
        auto statusCode = status >> 4;

        if (statusCode == 0x9) {
            // Note On
            tsf_note_on(mTsf, presetIndex, data1, data2 / 255.0);
        } else if (statusCode == 0x8) {
            // Note Off
            tsf_note_off(mTsf, presetIndex, data1);
        } else if (statusCode == 0xB) {
            // CC
            tsf_channel_midi_control(mTsf, channel, data1, data2);
        } else if (statusCode == 0xE) {
            // Pitch bend
            // get 14-bit number from data1 and data2
            auto pitch = (data2 << 7) | data1;

            tsf_channel_set_pitchwheel(mTsf, channel, pitch);
        }
    }

    void reset() override {
    }

private:
    tsf* mTsf = nullptr;
    bool mIsStereo;
    int32_t mSampleRate;
};

#endif //SOUND_FONT_INSTRUMENT_H
