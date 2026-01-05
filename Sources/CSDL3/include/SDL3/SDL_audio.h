/*
  Minimal SDL3 audio header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_audio_h_
#define SDL_audio_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_error.h>
#include <SDL3/SDL_endian.h>
#include <SDL3/SDL_mutex.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Audio format masks */
#define SDL_AUDIO_MASK_BITSIZE       (0xFF)
#define SDL_AUDIO_MASK_FLOAT         (1<<8)
#define SDL_AUDIO_MASK_BIG_ENDIAN    (1<<12)
#define SDL_AUDIO_MASK_SIGNED        (1<<15)

/* Audio format enum */
typedef enum SDL_AudioFormat {
    SDL_AUDIO_UNKNOWN   = 0x0000u,
    SDL_AUDIO_U8        = 0x0008u,
    SDL_AUDIO_S8        = 0x8008u,
    SDL_AUDIO_S16LE     = 0x8010u,
    SDL_AUDIO_S16BE     = 0x9010u,
    SDL_AUDIO_S32LE     = 0x8020u,
    SDL_AUDIO_S32BE     = 0x9020u,
    SDL_AUDIO_F32LE     = 0x8120u,
    SDL_AUDIO_F32BE     = 0x9120u,
    #if SDL_BYTEORDER == SDL_LIL_ENDIAN
    SDL_AUDIO_S16 = SDL_AUDIO_S16LE,
    SDL_AUDIO_S32 = SDL_AUDIO_S32LE,
    SDL_AUDIO_F32 = SDL_AUDIO_F32LE
    #else
    SDL_AUDIO_S16 = SDL_AUDIO_S16BE,
    SDL_AUDIO_S32 = SDL_AUDIO_S32BE,
    SDL_AUDIO_F32 = SDL_AUDIO_F32BE
    #endif
} SDL_AudioFormat;

/* Audio format macros */
#define SDL_AUDIO_BITSIZE(x)         ((x) & SDL_AUDIO_MASK_BITSIZE)
#define SDL_AUDIO_BYTESIZE(x)        (SDL_AUDIO_BITSIZE(x) / 8)
#define SDL_AUDIO_ISFLOAT(x)         ((x) & SDL_AUDIO_MASK_FLOAT)
#define SDL_AUDIO_ISBIGENDIAN(x)     ((x) & SDL_AUDIO_MASK_BIG_ENDIAN)
#define SDL_AUDIO_ISLITTLEENDIAN(x)  (!SDL_AUDIO_ISBIGENDIAN(x))
#define SDL_AUDIO_ISSIGNED(x)        ((x) & SDL_AUDIO_MASK_SIGNED)
#define SDL_AUDIO_ISINT(x)           (!SDL_AUDIO_ISFLOAT(x))
#define SDL_AUDIO_ISUNSIGNED(x)      (!SDL_AUDIO_ISSIGNED(x))

/* Audio device ID */
typedef Uint32 SDL_AudioDeviceID;
#define SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK ((SDL_AudioDeviceID) 0xFFFFFFFFu)
#define SDL_AUDIO_DEVICE_DEFAULT_RECORDING ((SDL_AudioDeviceID) 0xFFFFFFFEu)

/* Audio spec structure */
typedef struct SDL_AudioSpec {
    SDL_AudioFormat format;
    int channels;
    int freq;
} SDL_AudioSpec;

#define SDL_AUDIO_FRAMESIZE(x) (SDL_AUDIO_BYTESIZE((x).format) * (x).channels)

/* Audio stream - opaque handle */
typedef struct SDL_AudioStream SDL_AudioStream;

/* Audio stream callback */
typedef void (SDLCALL *SDL_AudioStreamCallback)(void *userdata, SDL_AudioStream *stream, int additional_amount, int total_amount);

/* Function declarations - only what's needed */
extern SDL_DECLSPEC SDL_AudioStream * SDLCALL SDL_OpenAudioDeviceStream(SDL_AudioDeviceID devid, const SDL_AudioSpec *spec, SDL_AudioStreamCallback callback, void *userdata);
extern SDL_DECLSPEC void SDLCALL SDL_DestroyAudioStream(SDL_AudioStream *stream);
extern SDL_DECLSPEC SDL_AudioDeviceID SDLCALL SDL_GetAudioStreamDevice(SDL_AudioStream *stream);
extern SDL_DECLSPEC bool SDLCALL SDL_ResumeAudioStreamDevice(SDL_AudioDeviceID devid);
extern SDL_DECLSPEC bool SDLCALL SDL_PauseAudioStreamDevice(SDL_AudioStream *stream);
extern SDL_DECLSPEC Uint32 SDLCALL SDL_GetAudioStreamQueued(SDL_AudioStream *stream);
extern SDL_DECLSPEC bool SDLCALL SDL_PutAudioStreamData(SDL_AudioStream *stream, const void *buf, int len);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_audio_h_ */
