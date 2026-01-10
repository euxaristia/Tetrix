#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <alsa/asoundlib.h>

#define SAMPLE_RATE 48000
#define FREQUENCY 440.0
#define DURATION 1.0
#define AMPLITUDE 16000.0

int main() {
    printf("Testing simple ALSA playback...\n");

    snd_pcm_t *handle;
    int err;

    // Open the same device that works with aplay
    err = snd_pcm_open(&handle, "plughw:1,3", SND_PCM_STREAM_PLAYBACK, 0);
    if (err < 0) {
        printf("Failed to open ALSA device: %s\n", snd_strerror(err));
        return 1;
    }

    printf("Successfully opened ALSA device\n");

    // Set parameters to match the working aplay command
    snd_pcm_hw_params_t *params;
    snd_pcm_hw_params_alloca(&params);

    err = snd_pcm_hw_params_any(handle, params);
    if (err < 0) {
        printf("Failed to get parameters: %s\n", snd_strerror(err));
        snd_pcm_close(handle);
        return 1;
    }

    err = snd_pcm_hw_params_set_access(handle, params, SND_PCM_ACCESS_RW_INTERLEAVED);
    if (err < 0) {
        printf("Failed to set access: %s\n", snd_strerror(err));
        snd_pcm_close(handle);
        return 1;
    }

    err = snd_pcm_hw_params_set_format(handle, params, SND_PCM_FORMAT_S16_LE);
    if (err < 0) {
        printf("Failed to set format: %s\n", snd_strerror(err));
        snd_pcm_close(handle);
        return 1;
    }

    err = snd_pcm_hw_params_set_channels(handle, params, 1);
    if (err < 0) {
        printf("Failed to set channels: %s\n", snd_strerror(err));
        snd_pcm_close(handle);
        return 1;
    }

    unsigned int rate = SAMPLE_RATE;
    err = snd_pcm_hw_params_set_rate_near(handle, params, &rate, 0);
    if (err < 0) {
        printf("Failed to set rate: %s\n", snd_strerror(err));
        snd_pcm_close(handle);
        return 1;
    }

    err = snd_pcm_hw_params(handle, params);
    if (err < 0) {
        printf("Failed to set parameters: %s\n", snd_strerror(err));
        snd_pcm_close(handle);
        return 1;
    }

    err = snd_pcm_prepare(handle);
    if (err < 0) {
        printf("Failed to prepare: %s\n", snd_strerror(err));
        snd_pcm_close(handle);
        return 1;
    }

    printf("Starting simple tone playback...\n");

    // Generate and play a simple tone
    int16_t buffer[1024];
    int num_samples = SAMPLE_RATE * DURATION;
    int sample_index = 0;

    while (sample_index < num_samples) {
        int buf_idx = 0;
        while (buf_idx < 1024 && sample_index < num_samples) {
            float t = (float)sample_index / SAMPLE_RATE;
            float value = sinf(t * FREQUENCY * 2.0 * M_PI) * AMPLITUDE;
            buffer[buf_idx] = (int16_t)value;
            sample_index++;
            buf_idx++;
        }

        err = snd_pcm_writei(handle, buffer, buf_idx);
        if (err < 0) {
            printf("Write error: %s\n", snd_strerror(err));
            snd_pcm_recover(handle, err, 0);
            break;
        }

        printf("Wrote %d samples\n", buf_idx);
    }

    snd_pcm_drain(handle);
    snd_pcm_close(handle);

    printf("Finished playing simple tone\n");
    return 0;
}
