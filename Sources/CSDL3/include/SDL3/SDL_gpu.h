/*
  Minimal SDL3 GPU header - Swift-native replacement
  Stub header for SDL_render.h compatibility
*/

#ifndef SDL_gpu_h_
#define SDL_gpu_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * An opaque structure representing a GPU device.
 *
 * \since This struct is available since SDL 3.0.0.
 */
typedef struct SDL_GpuDevice SDL_GpuDevice;
/* Compatibility alias for SDL_render.h (which uses SDL_GPUDevice) */
typedef struct SDL_GpuDevice SDL_GPUDevice;

/**
 * An opaque structure representing a GPU texture.
 *
 * \since This struct is available since SDL 3.0.0.
 */
typedef struct SDL_GPUTexture SDL_GPUTexture;

/**
 * An opaque structure representing GPU render state.
 *
 * \since This struct is available since SDL 3.0.0.
 */
typedef struct SDL_GPURenderState SDL_GPURenderState;

/**
 * An opaque structure representing a GPU shader.
 *
 * \since This struct is available since SDL 3.0.0.
 */
typedef struct SDL_GPUShader SDL_GPUShader;

/**
 * An opaque structure representing a GPU buffer.
 *
 * \since This struct is available since SDL 3.0.0.
 */
typedef struct SDL_GPUBuffer SDL_GPUBuffer;

/**
 * GPU texture sampler binding structure - minimal stub.
 *
 * \since This struct is available since SDL 3.0.0.
 */
typedef struct {
    Sint32 binding_index;
    SDL_GPUTexture *texture;
} SDL_GPUTextureSamplerBinding;

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_gpu_h_ */
