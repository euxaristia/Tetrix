/*
  Minimal SDL3 GUID header - Swift-native replacement
  Stub header for SDL_gamepad.h compatibility
*/

#ifndef SDL_guid_h_
#define SDL_guid_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * A structure that holds a globally unique identifier (GUID).
 *
 * \since This struct is available since SDL 3.0.0.
 */
typedef struct SDL_GUID
{
    Uint8 data[16];
} SDL_GUID;

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_guid_h_ */
