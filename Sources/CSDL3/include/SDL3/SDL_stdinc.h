/*
  Minimal SDL3 stdinc header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_stdinc_h_
#define SDL_stdinc_h_

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <float.h>
#include <math.h>

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
#ifndef SDL_bool
typedef bool SDL_bool;
#endif
#ifndef SDL_TRUE
#define SDL_TRUE true
#endif
#ifndef SDL_FALSE
#define SDL_FALSE false
#endif

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

/* Printf format string attribute macros */
#include <stdarg.h>
#ifndef SDL_PRINTF_FORMAT_STRING
#if defined(__GNUC__) && (__GNUC__ >= 4)
#define SDL_PRINTF_FORMAT_STRING __attribute__((format(printf, 1, 2)))
#else
#define SDL_PRINTF_FORMAT_STRING
#endif
#endif

#ifndef SDL_PRINTF_VARARG_FUNC
#if defined(__GNUC__) && (__GNUC__ >= 4)
#define SDL_PRINTF_VARARG_FUNC(x) __attribute__((format(printf, x, (x)+1)))
#else
#define SDL_PRINTF_VARARG_FUNC(x)
#endif
#endif

#ifndef SDL_PRINTF_VARARG_FUNCV
#if defined(__GNUC__) && (__GNUC__ >= 4)
#define SDL_PRINTF_VARARG_FUNCV(x) __attribute__((format(printf, x, 0)))
#else
#define SDL_PRINTF_VARARG_FUNCV(x)
#endif
#endif

/* Common constants */
#define SDL_MAX_SINT8   ((Sint8)0x7F)
#define SDL_MIN_SINT8   ((Sint8)(~0x7F))
#define SDL_MAX_UINT8   ((Uint8)0xFF)
#define SDL_MIN_UINT8   ((Uint8)0x00)
#define SDL_MAX_SINT16  ((Sint16)0x7FFF)
#define SDL_MIN_SINT16  ((Sint16)(~0x7FFF))
#define SDL_MAX_UINT16  ((Uint16)0xFFFF)
#define SDL_MIN_UINT16  ((Uint16)0x0000)
#define SDL_MAX_SINT32  ((Sint32)0x7FFFFFFF)
#define SDL_MIN_SINT32  ((Sint32)(~0x7FFFFFFF))
#define SDL_MAX_UINT32  ((Uint32)0xFFFFFFFFu)
#define SDL_MIN_UINT32  ((Uint32)0x00000000)

/* 64-bit constants */
#ifndef SDL_SINT64_C
#define SDL_SINT64_C(x) x##LL
#endif
#ifndef SDL_UINT64_C
#define SDL_UINT64_C(x) x##ULL
#endif

#define SDL_MAX_SINT64  SDL_SINT64_C(0x7FFFFFFFFFFFFFFF)
#define SDL_MIN_SINT64  ~SDL_SINT64_C(0x7FFFFFFFFFFFFFFF)
#define SDL_MAX_UINT64  SDL_UINT64_C(0xFFFFFFFFFFFFFFFF)
#define SDL_MIN_UINT64  SDL_UINT64_C(0x0000000000000000)

/* Floating-point constants */
#ifndef SDL_FLT_EPSILON
#define SDL_FLT_EPSILON FLT_EPSILON
#endif

/* Math function wrappers */
#ifndef SDL_fabsf
#define SDL_fabsf fabsf
#endif

/* Function pointer type */
#ifndef SDL_FunctionPointer
typedef void* SDL_FunctionPointer;
#endif

#endif /* SDL_stdinc_h_ */
