/*
  Minimal SDL3 platform header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_platform_h_
#define SDL_platform_h_

#include <SDL3/SDL_platform_defines.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Platform identification function */
extern SDL_DECLSPEC const char * SDLCALL SDL_GetPlatform(void);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_platform_h_ */
