#ifndef ANDROID_LOGGING_H
#define ANDROID_LOGGING_H

#include <android/log.h>

#define APP_NAME "FLUTTER_SEQUENCER"

#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, APP_NAME, __VA_ARGS__))
#define LOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, APP_NAME, __VA_ARGS__))

#endif //ANDROID_LOGGING_H

