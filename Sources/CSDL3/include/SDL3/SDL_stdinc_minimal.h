/*
  Minimal SDL3 stdinc header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_stdinc_h_
#define SDL_stdinc_h_

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

/* Basic SDL integer types - match standard C types */
typedef int8_t Sint8;
typedef uint8_t Uint8;
typedef int16_t Sint16;
typedef uint16_t Uint16;
typedef int32_t Sint32;
typedef uint32_t Uint32;
typedef int64_t Sint64;
typedef uint64_t Uint64;

/* SDL boolean type */
typedef bool SDL_bool;
#define SDL_TRUE true
#define SDL_FALSE false

/* SDL time type */
typedef Sint64 SDL_Time;

/* Size max */
#ifndef SDL_SIZE_MAX
#define SDL_SIZE_MAX SIZE_MAX
#endif

/* Compile-time assertion */
#ifndef SDL_COMPILE_TIME_ASSERT
#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
#define SDL_COMPILE_TIME_ASSERT(name, x) _Static_assert(x, #x)
#elif defined(__cplusplus) && (__cplusplus >= 201103L)
#define SDL_COMPILE_TIME_ASSERT(name, x) static_assert(x, #x)
#else
#define SDL_COMPILE_TIME_ASSERT(name, x) typedef int SDL_compile_time_assert_ ## name[(x) * 2 - 1]
#endif
#endif

/* Array size macro */
#define SDL_arraysize(array) (sizeof(array)/sizeof(array[0]))

/* Stringify macro */
#define SDL_STRINGIFY_ARG(arg) #arg

/* Cast macros - minimal implementation */
#ifdef __cplusplus
#define SDL_reinterpret_cast(type, expression) reinterpret_cast<type>(expression)
#define SDL_static_cast(type, expression) static_cast<type>(expression)
#define SDL_const_cast(type, expression) const_cast<type>(expression)
#else
#define SDL_reinterpret_cast(type, expression) ((type)(expression))
#define SDL_static_cast(type, expression) ((type)(expression))
#define SDL_const_cast(type, expression) ((type)(expression))
#endif

#endif /* SDL_stdinc_h_ */
