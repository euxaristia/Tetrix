/*
  Minimal SDL3 pen header - Swift-native replacement
  Stub header for SDL_events.h compatibility
*/

#ifndef SDL_pen_h_
#define SDL_pen_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Pen ID type - minimal stub */
typedef Uint32 SDL_PenID;

/* Pen input flags - minimal stub */
typedef Uint32 SDL_PenInputFlags;

/* Pen axis enumeration - minimal stub */
typedef enum {
    SDL_PEN_AXIS_PRESSURE = 0,
    SDL_PEN_AXIS_TILT_X,
    SDL_PEN_AXIS_TILT_Y,
    SDL_PEN_AXIS_ROTATION,
    SDL_PEN_AXIS_DISTANCE
} SDL_PenAxis;

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_pen_h_ */
