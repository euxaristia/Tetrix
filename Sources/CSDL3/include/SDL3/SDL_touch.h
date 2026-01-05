/*
  Minimal SDL3 touch header - Swift-native replacement
  Stub header for SDL_events.h compatibility
*/

#ifndef SDL_touch_h_
#define SDL_touch_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Touch ID types - minimal stub */
typedef Uint64 SDL_FingerID;
typedef Uint32 SDL_TouchID;

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_touch_h_ */
