#ifndef PULSE_AUDIO_WRAPPER_H
#define PULSE_AUDIO_WRAPPER_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

void* pulse_audio_create(int sample_rate, int channels, int format);
int pulse_audio_write(void* context, const void* data, size_t bytes);
int pulse_audio_drain(void* context);
void pulse_audio_destroy(void* context);

#ifdef __cplusplus
}
#endif

#endif /* PULSE_AUDIO_WRAPPER_H */
