/*
 * Minimal PulseAudio wrapper for audio playback
 * This bypasses SDL3's crashing resume function
 */

#include <pulse/simple.h>
#include <pulse/error.h>
#include <pulse/gccmacro.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    pa_simple *pa;
    int sample_rate;
    int channels;
    int format;  // 16 for S16LE
} PulseAudioContext;

void* pulse_audio_create(int sample_rate, int channels, int format) {
    PulseAudioContext *ctx = malloc(sizeof(PulseAudioContext));
    if (!ctx) return NULL;
    
    ctx->sample_rate = sample_rate;
    ctx->channels = channels;
    ctx->format = format;
    
    pa_sample_spec ss;
    ss.format = PA_SAMPLE_S16LE;
    ss.channels = (uint8_t)channels;
    ss.rate = (uint32_t)sample_rate;
    
    pa_buffer_attr ba;
    ba.maxlength = (uint32_t)(sample_rate * channels * 2 * 2);  // 2 seconds
    ba.tlength = (uint32_t)(sample_rate * channels * 2 / 10);  // 100ms
    ba.prebuf = (uint32_t)(sample_rate * channels * 2 / 20);    // 50ms
    ba.minreq = (uint32_t)(sample_rate * channels * 2 / 40);    // 25ms
    ba.fragsize = (uint32_t)(sample_rate * channels * 2 / 40);   // 25ms
    
    int error;
    ctx->pa = pa_simple_new(NULL, "Tetrix", PA_STREAM_PLAYBACK, NULL, "Tetris Music", &ss, NULL, &ba, &error);
    
    if (!ctx->pa) {
        free(ctx);
        return NULL;
    }
    
    return ctx;
}

int pulse_audio_write(void* context, const void* data, size_t bytes) {
    PulseAudioContext *ctx = (PulseAudioContext*)context;
    if (!ctx || !ctx->pa) return 0;
    
    int error;
    if (pa_simple_write(ctx->pa, data, bytes, &error) < 0) {
        return 0;
    }
    
    return 1;
}

int pulse_audio_drain(void* context) {
    PulseAudioContext *ctx = (PulseAudioContext*)context;
    if (!ctx || !ctx->pa) return 0;
    
    int error;
    if (pa_simple_drain(ctx->pa, &error) < 0) {
        return 0;
    }
    
    return 1;
}

void pulse_audio_destroy(void* context) {
    PulseAudioContext *ctx = (PulseAudioContext*)context;
    if (!ctx) return;
    
    if (ctx->pa) {
        pa_simple_free(ctx->pa);
    }
    
    free(ctx);
}
