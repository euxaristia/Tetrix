/*
  Minimal SDL3 endian header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_endian_h_
#define SDL_endian_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Byte order definitions */
#if defined(__BYTE_ORDER__) && defined(__ORDER_LITTLE_ENDIAN__) && defined(__ORDER_BIG_ENDIAN__)
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
#define SDL_BYTEORDER SDL_LIL_ENDIAN
#elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define SDL_BYTEORDER SDL_BIG_ENDIAN
#else
#error "Unknown byte order"
#endif
#elif defined(__LITTLE_ENDIAN__) || defined(_LITTLE_ENDIAN) || \
      defined(__ARMEL__) || defined(__THUMBEL__) || defined(__AARCH64EL__) || \
      (defined(__BYTE_ORDER) && __BYTE_ORDER == __LITTLE_ENDIAN) || \
      (defined(_BYTE_ORDER) && _BYTE_ORDER == _LITTLE_ENDIAN) || \
      defined(__i386__) || defined(__x86_64__) || defined(_M_IX86) || defined(_M_X64) || defined(_M_AMD64)
#define SDL_BYTEORDER SDL_LIL_ENDIAN
#elif defined(__BIG_ENDIAN__) || defined(_BIG_ENDIAN) || \
      defined(__ARMEB__) || defined(__THUMBEB__) || defined(__AARCH64EB__) || \
      (defined(__BYTE_ORDER) && __BYTE_ORDER == __BIG_ENDIAN) || \
      (defined(_BYTE_ORDER) && _BYTE_ORDER == _BIG_ENDIAN) || \
      defined(__m68k__) || defined(__PPC__) || defined(__POWERPC__) || defined(__ppc__) || defined(__PPC64__) || defined(__powerpc64__)
#define SDL_BYTEORDER SDL_BIG_ENDIAN
#else
#error "Unknown byte order"
#endif

#define SDL_LIL_ENDIAN 1234
#define SDL_BIG_ENDIAN 4321

/* Byte swap functions */
#if defined(__GNUC__) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3))
#define SDL_Swap16(x) __builtin_bswap16(x)
#define SDL_Swap32(x) __builtin_bswap32(x)
#define SDL_Swap64(x) __builtin_bswap64(x)
#elif defined(_MSC_VER) && (_MSC_VER >= 1400)
#include <stdlib.h>
#define SDL_Swap16(x) _byteswap_ushort(x)
#define SDL_Swap32(x) _byteswap_ulong(x)
#define SDL_Swap64(x) _byteswap_uint64(x)
#else
static SDL_INLINE Uint16 SDL_Swap16(Uint16 x)
{
    return ((x << 8) | (x >> 8));
}

static SDL_INLINE Uint32 SDL_Swap32(Uint32 x)
{
    return ((x << 24) | ((x << 8) & 0x00FF0000) | ((x >> 8) & 0x0000FF00) | (x >> 24));
}

static SDL_INLINE Uint64 SDL_Swap64(Uint64 x)
{
    return (((Uint64)SDL_Swap32((Uint32)(x & 0xFFFFFFFF)) << 32) | (Uint64)SDL_Swap32((Uint32)(x >> 32)));
}
#endif

/* Native to little/big endian conversions */
#if SDL_BYTEORDER == SDL_LIL_ENDIAN
#define SDL_SwapLE16(x) (x)
#define SDL_SwapLE32(x) (x)
#define SDL_SwapLE64(x) (x)
#define SDL_SwapBE16(x) SDL_Swap16(x)
#define SDL_SwapBE32(x) SDL_Swap32(x)
#define SDL_SwapBE64(x) SDL_Swap64(x)
#else
#define SDL_SwapLE16(x) SDL_Swap16(x)
#define SDL_SwapLE32(x) SDL_Swap32(x)
#define SDL_SwapLE64(x) SDL_Swap64(x)
#define SDL_SwapBE16(x) (x)
#define SDL_SwapBE32(x) (x)
#define SDL_SwapBE64(x) (x)
#endif

/* Runtime byte order check */
SDL_DECLSPEC SDL_bool SDLCALL SDL_IsLittleEndian(void);
SDL_DECLSPEC SDL_bool SDLCALL SDL_IsBigEndian(void);

/* Get current byte order */
static SDL_INLINE Uint32 SDL_GetByteOrder(void)
{
    return SDL_BYTEORDER;
}

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_endian_h_ */
