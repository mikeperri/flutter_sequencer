#ifndef OPTION_ARRAY_H
#define OPTION_ARRAY_H

#include <array>
#include <optional>
template<typename TIndex, typename TValue, int maxCount>
class OptionArray {
public:

    // Inserts a value at the lowest free index. Returns nullopt if the array was full, and an
    // option containing the new index otherwise.
    std::optional<TIndex> add(TValue value){
        TIndex index = 0;

        for (index = 0; index < maxCount; ++index) {
            if (!mArray[index].has_value()) break;
        }

        if (index == maxCount) {
            return std::nullopt;
        }

        mArray[index].emplace(value);
        return std::optional(index);
    }

    // Gets the value at the given index. Returns nullopt if there is no value for that index, and
    // an option containing the value otherwise.
    std::optional<TValue> get(TIndex index) {
        if (index < maxCount && mArray[index].has_value()) {
            return mArray[index];
        } else {
            return std::nullopt;
        }
    }

    void set(TIndex index, TValue value) {
        if (index >= 0 && index < maxCount) {
            mArray[index] = value;
        }
    }

    // Removes the value at the given index. Returns true if there was a value, false otherwise.
    bool remove(TIndex index) {
        if (mArray[index].has_value()) {
            mArray[index].reset();

            return true;
        }

        return false;
    }
private:
    std::array<std::optional<TValue>, maxCount> mArray;
};

#endif //OPTION_ARRAY
