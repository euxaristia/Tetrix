#ifndef WASAPI_WRAPPER_H
#define WASAPI_WRAPPER_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WIN32
void* wasapi_audio_create(int sample_rate, int channels);
int wasapi_audio_write(void* context, const void* data, size_t bytes);
int wasapi_audio_start(void* context, void* userData, int32_t (*dataProvider)(void* userData, int16_t* buffer, int32_t samples));
void wasapi_audio_stop(void* context);
void wasapi_audio_destroy(void* context);
#endif

#ifdef __cplusplus
}
#endif

#endif /* WASAPI_WRAPPER_H */
