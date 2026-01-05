/*
  Minimal SDL3 pixels header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_pixels_h_
#define SDL_pixels_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_error.h>
#include <SDL3/SDL_endian.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Alpha values */
#define SDL_ALPHA_OPAQUE 255
#define SDL_ALPHA_TRANSPARENT 0

/* Color structures */
typedef struct SDL_Color {
    Uint8 r;
    Uint8 g;
    Uint8 b;
    Uint8 a;
} SDL_Color;

typedef struct SDL_FColor {
    float r;
    float g;
    float b;
    float a;
} SDL_FColor;

/* Palette structure - minimal definition */
typedef struct SDL_Palette {
    int ncolors;
    SDL_Color *colors;
    Uint32 version;
    int refcount;
} SDL_Palette;

/* Pixel format - minimal structure definition */
typedef struct SDL_PixelFormat {
    Uint32 format;
    SDL_Palette *palette;
    Uint8 bits_per_pixel;
    Uint8 bytes_per_pixel;
    Uint32 Rmask;
    Uint32 Gmask;
    Uint32 Bmask;
    Uint32 Amask;
    Uint8 Rloss;
    Uint8 Gloss;
    Uint8 Bloss;
    Uint8 Aloss;
    Uint8 Rshift;
    Uint8 Gshift;
    Uint8 Bshift;
    Uint8 Ashift;
    int refcount;
    struct SDL_PixelFormat *next;
} SDL_PixelFormat;

/* Function declarations - only what's needed */
extern SDL_DECLSPEC Uint32 SDLCALL SDL_MapRGB(const SDL_PixelFormat *format, Uint8 r, Uint8 g, Uint8 b);
extern SDL_DECLSPEC Uint32 SDLCALL SDL_MapRGBA(const SDL_PixelFormat *format, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
extern SDL_DECLSPEC void SDLCALL SDL_GetRGB(Uint32 pixel, const SDL_PixelFormat *format, Uint8 *r, Uint8 *g, Uint8 *b);
extern SDL_DECLSPEC void SDLCALL SDL_GetRGBA(Uint32 pixel, const SDL_PixelFormat *format, Uint8 *r, Uint8 *g, Uint8 *b, Uint8 *a);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_pixels_h_ */
