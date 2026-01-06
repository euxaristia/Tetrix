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

/* Endian conversion macros */
#ifndef SDL_SwapLE16
#define SDL_SwapLE16(x) (x)
#endif
#ifndef SDL_SwapBE16
#define SDL_SwapBE16(x) SDL_Swap16(x)
#endif
#ifndef SDL_SwapLE32
#define SDL_SwapLE32(x) (x)
#endif
#ifndef SDL_SwapBE32
#define SDL_SwapBE32(x) SDL_Swap32(x)
#endif
#ifndef SDL_SwapLE64
#define SDL_SwapLE64(x) (x)
#endif
#ifndef SDL_SwapBE64
#define SDL_SwapBE64(x) SDL_Swap64(x)
#endif

/* Placeholder swap functions - these may need proper implementation */
#ifndef SDL_Swap16
#define SDL_Swap16(x) ((Uint16)(((x) << 8) | ((x) >> 8)))
#endif
#ifndef SDL_Swap32
#define SDL_Swap32(x) ((Uint32)(((x) << 24) | (((x) << 8) & 0x00FF0000) | (((x) >> 8) & 0x0000FF00) | ((x) >> 24)))
#endif
#ifndef SDL_Swap64
#define SDL_Swap64(x) ((Uint64)(((x) << 56) | (((x) << 40) & 0x00FF000000000000ULL) | (((x) << 24) & 0x0000FF0000000000ULL) | (((x) << 8) & 0x000000FF00000000ULL) | (((x) >> 8) & 0x00000000FF000000ULL) | (((x) >> 24) & 0x0000000000FF0000ULL) | (((x) >> 40) & 0x000000000000FF00ULL) | ((x) >> 56)))
#endif

/* Endian detection */
#ifndef SDL_BYTEORDER
#if defined(__LITTLE_ENDIAN__) || defined(__LITTLE_ENDIAN) || defined(_LITTLE_ENDIAN) || \
    (defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#define SDL_BYTEORDER SDL_LIL_ENDIAN
#elif defined(__BIG_ENDIAN__) || defined(__BIG_ENDIAN) || defined(_BIG_ENDIAN) || \
      (defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__)
#define SDL_BYTEORDER SDL_BIG_ENDIAN
#else
/* Default to little endian for x86/x64 */
#define SDL_BYTEORDER SDL_LIL_ENDIAN
#endif
#endif

#ifndef SDL_LIL_ENDIAN
#define SDL_LIL_ENDIAN 1234
#endif
#ifndef SDL_BIG_ENDIAN
#define SDL_BIG_ENDIAN 4321
#endif

#endif /* SDL_stdinc_h_ */
