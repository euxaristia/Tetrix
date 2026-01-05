/*
  Minimal SDL3 surface header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_surface_h_
#define SDL_surface_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_error.h>
#include <SDL3/SDL_blendmode.h>
#include <SDL3/SDL_pixels.h>
#include <SDL3/SDL_properties.h>
#include <SDL3/SDL_rect.h>
#include <SDL3/SDL_iostream.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Surface flags */
typedef Uint32 SDL_SurfaceFlags;
#define SDL_SURFACE_PREALLOCATED    0x00000001u
#define SDL_SURFACE_LOCK_NEEDED     0x00000002u
#define SDL_SURFACE_LOCKED          0x00000004u
#define SDL_SURFACE_SIMD_ALIGNED    0x00000008u

/* Scale mode */
typedef enum SDL_ScaleMode {
    SDL_SCALEMODE_INVALID = -1,
    SDL_SCALEMODE_NEAREST,
    SDL_SCALEMODE_LINEAR,
    SDL_SCALEMODE_PIXELART
} SDL_ScaleMode;

/* Flip mode */
typedef enum SDL_FlipMode {
    SDL_FLIP_NONE,
    SDL_FLIP_HORIZONTAL,
    SDL_FLIP_VERTICAL,
    SDL_FLIP_HORIZONTAL_AND_VERTICAL = (SDL_FLIP_HORIZONTAL | SDL_FLIP_VERTICAL)
} SDL_FlipMode;

/* Surface structure - minimal definition */
struct SDL_Surface {
    SDL_SurfaceFlags flags;
    SDL_PixelFormat *format;
    int w;
    int h;
    int pitch;
    void *pixels;
    int refcount;
    void *reserved;
};

typedef struct SDL_Surface SDL_Surface;

/* Function declarations - only what's actually used */
extern SDL_DECLSPEC void SDLCALL SDL_DestroySurface(SDL_Surface *surface);

/* Note: SDL_CreateTextureFromSurface is declared in SDL_render.h, not here */

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_surface_h_ */
