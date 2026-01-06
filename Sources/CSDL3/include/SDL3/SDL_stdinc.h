/* Clean replacement for SDL_stdinc.h - no copyright dependencies */

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
#define SDL_COMPILE_TIME_ASSERT(name, x) typedef char SDL_compile_time_assert_##name[(x) ? 1 : -1]
#endif
#endif

/* Variable arguments */
#include <stdarg.h>

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

/* Function pointer type */
#ifndef SDL_FunctionPointer
typedef void* SDL_FunctionPointer;
#endif

/* Memory functions - use standard C functions */
#ifndef SDL_malloc
#define SDL_malloc malloc
#endif
#ifndef SDL_calloc
#define SDL_calloc calloc
#endif
#ifndef SDL_realloc
#define SDL_realloc realloc
#endif
#ifndef SDL_free
#define SDL_free free
#endif

/* String functions - use standard C functions */
#ifndef SDL_memset
#define SDL_memset memset
#endif
#ifndef SDL_memcpy
#define SDL_memcpy memcpy
#endif
#ifndef SDL_memmove
#define SDL_memmove memmove
#endif
#ifndef SDL_memcmp
#define SDL_memcmp memcmp
#endif

/* String comparison - use standard C functions */
#ifndef SDL_strlen
#define SDL_strlen strlen
#endif
#ifndef SDL_strcmp
#define SDL_strcmp strcmp
#endif
#ifndef SDL_strncmp
#define SDL_strncmp strncmp
#endif
#ifndef SDL_strcpy
#define SDL_strcpy strcpy
#endif
#ifndef SDL_strncpy
#define SDL_strncpy strncpy
#endif

/* Character classification - use standard C functions */
#ifndef SDL_isdigit
#define SDL_isdigit isdigit
#endif
#ifndef SDL_isspace
#define SDL_isspace isspace
#endif
#ifndef SDL_toupper
#define SDL_toupper toupper
#endif
#ifndef SDL_tolower
#define SDL_tolower tolower
#endif

/* Math functions - use standard C functions */
#ifndef SDL_abs
#define SDL_abs abs
#endif
#ifndef SDL_min
#define SDL_min(x, y) (((x) < (y)) ? (x) : (y))
#endif
#ifndef SDL_max
#define SDL_max(x, y) (((x) > (y)) ? (x) : (y))
#endif

/* Endian conversion macros - these are defined in SDL_endian.h */
/* We don't define SDL_Swap16/32/64 here - let SDL_endian.h handle them */

/* Endian detection - these are defined in SDL_endian.h */
/* We don't define SDL_BYTEORDER/SDL_LIL_ENDIAN/SDL_BIG_ENDIAN here - let SDL_endian.h handle them */

#endif /* SDL_stdinc_h_ */
