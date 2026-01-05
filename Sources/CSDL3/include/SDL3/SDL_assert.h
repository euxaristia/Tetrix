/*
  Minimal SDL3 assert header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_assert_h_
#define SDL_assert_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Minimal assertion macros - just use standard assert */
#ifndef SDL_ASSERT_LEVEL
#define SDL_ASSERT_LEVEL 0  /* Disabled by default for minimal implementation */
#endif

#if SDL_ASSERT_LEVEL >= 1
#include <assert.h>
#define SDL_assert(condition) assert(condition)
#define SDL_assert_release(condition) assert(condition)
#else
#define SDL_assert(condition) ((void)0)
#define SDL_assert_release(condition) ((void)0)
#endif

#define SDL_assert_paranoid(condition) ((void)0)
#define SDL_assert_always(condition) assert(condition)

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_assert_h_ */
