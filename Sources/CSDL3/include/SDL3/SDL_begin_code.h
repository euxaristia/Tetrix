/* Clean replacement for SDL_begin_code.h - no copyright dependencies */

/* This shouldn't be nested -- included it around code only. */
#ifdef SDL_begin_code_h
/* Disabled nested inclusion check for Swift module compatibility */
#endif
#define SDL_begin_code_h

/* Basic SDL function attribute macros - minimal implementation */
#ifndef SDL_DEPRECATED
#ifdef __GNUC__
#define SDL_DEPRECATED __attribute__((deprecated))
#elif defined(_MSC_VER)
#define SDL_DEPRECATED __declspec(deprecated)
#else
#define SDL_DEPRECATED
#endif
#endif

#ifndef SDL_UNUSED
#ifdef __GNUC__
#define SDL_UNUSED __attribute__((unused))
#else
#define SDL_UNUSED
#endif
#endif

/* Function export/visibility macros */
#ifndef SDL_DECLSPEC
#if defined(SDL_PLATFORM_WINDOWS)
#ifdef DLL_EXPORT
#define SDL_DECLSPEC __declspec(dllexport)
#else
#define SDL_DECLSPEC
#endif
#else
#if defined(__GNUC__) && __GNUC__ >= 4
#define SDL_DECLSPEC __attribute__ ((visibility("default")))
#else
#define SDL_DECLSPEC
#endif
#endif
#endif

/* Calling convention */
#ifndef SDLCALL
#if defined(SDL_PLATFORM_WINDOWS) && !defined(__GNUC__)
#define SDLCALL __cdecl
#else
#define SDLCALL
#endif
#endif

/* Inline function macros */
#ifndef SDL_INLINE
#ifdef __GNUC__
#define SDL_INLINE __inline__
#elif defined(_MSC_VER)
#define SDL_INLINE __inline
#else
#define SDL_INLINE inline
#endif
#endif

#ifndef SDL_FORCE_INLINE
#if defined(_MSC_VER) && (_MSC_VER >= 1200)
#define SDL_FORCE_INLINE __forceinline
#elif (defined(__GNUC__) && (__GNUC__ >= 4)) || defined(__clang__)
#define SDL_FORCE_INLINE __attribute__((always_inline)) static __inline__
#else
#define SDL_FORCE_INLINE static SDL_INLINE
#endif
#endif

/* Noreturn attribute */
#ifndef SDL_NORETURN
#if defined(__GNUC__)
#define SDL_NORETURN __attribute__((noreturn))
#elif defined(_MSC_VER)
#define SDL_NORETURN __declspec(noreturn)
#else
#define SDL_NORETURN
#endif
#endif

#ifndef SDL_ANALYZER_NORETURN
#define SDL_ANALYZER_NORETURN
#endif

/* Fallthrough attribute */
#ifndef SDL_FALLTHROUGH
#if (defined(__cplusplus) && __cplusplus >= 201703L) || \
    (defined(__STDC_VERSION__) && __STDC_VERSION__ >= 202000L)
#define SDL_FALLTHROUGH [[fallthrough]]
#elif defined(__has_attribute) && __has_attribute(__fallthrough__)
#if (defined(__GNUC__) && __GNUC__ >= 7) || \
    (defined(__clang_major__) && __clang_major__ >= 10)
#define SDL_FALLTHROUGH __attribute__((__fallthrough__))
#else
#define SDL_FALLTHROUGH do {} while (0)
#endif
#else
#define SDL_FALLTHROUGH do {} while (0)
#endif
#endif

/* Nodiscard attribute */
#ifndef SDL_NODISCARD
#if (defined(__cplusplus) && __cplusplus >= 201703L) || \
    (defined(__STDC_VERSION__) && __STDC_VERSION__ >= 202311L)
#define SDL_NODISCARD [[nodiscard]]
#elif (defined(__GNUC__) && (__GNUC__ >= 4)) || defined(__clang__)
#define SDL_NODISCARD __attribute__((warn_unused_result))
#elif defined(_MSC_VER) && (_MSC_VER >= 1700)
#define SDL_NODISCARD _Check_return_
#else
#define SDL_NODISCARD
#endif
#endif

/* Malloc attribute */
#ifndef SDL_MALLOC
#if defined(__GNUC__) && (__GNUC__ >= 3)
#define SDL_MALLOC __attribute__((malloc))
#else
#define SDL_MALLOC
#endif
#endif

/* Restrict keyword */
#ifndef SDL_RESTRICT
#if defined(restrict) || (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L))
#define SDL_RESTRICT restrict
#elif defined(_MSC_VER) || defined(__GNUC__) || defined(__clang__)
#define SDL_RESTRICT __restrict
#else
#define SDL_RESTRICT
#endif
#endif

/* Has builtin check */
#ifndef SDL_HAS_BUILTIN
#ifdef __has_builtin
#define SDL_HAS_BUILTIN(x) __has_builtin(x)
#else
#define SDL_HAS_BUILTIN(x) 0
#endif
#endif

/* Alignment attribute */
#ifndef SDL_ALIGNED
#if defined(__clang__) || defined(__GNUC__)
#define SDL_ALIGNED(x) __attribute__((aligned(x)))
#elif defined(_MSC_VER)
#define SDL_ALIGNED(x) __declspec(align(x))
#elif defined(__cplusplus) && (__cplusplus >= 201103L)
#define SDL_ALIGNED(x) alignas(x)
#elif defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
#define SDL_ALIGNED(x) _Alignas(x)
#else
#define SDL_ALIGNED(x) /* alignment not supported */
#endif
#endif

/* Thread safety annotations (for Clang thread safety analysis) */
#ifndef SDL_ACQUIRE
#ifdef __has_capability
#if __has_capability(thread_safety)
#define SDL_ACQUIRE(...) __attribute__((acquire_capability(__VA_ARGS__)))
#else
#define SDL_ACQUIRE(...)
#endif
#else
#define SDL_ACQUIRE(...)
#endif
#endif

#ifndef SDL_RELEASE
#ifdef __has_capability
#if __has_capability(thread_safety)
#define SDL_RELEASE(...) __attribute__((release_capability(__VA_ARGS__)))
#else
#define SDL_RELEASE(...)
#endif
#else
#define SDL_RELEASE(...)
#endif
#endif

/* Force structure packing at 4 byte alignment (minimal - only for MSVC) */
#if defined(_MSC_VER) || defined(__MWERKS__) || defined(__BORLANDC__)
#ifdef _MSC_VER
#pragma warning(disable: 4103)
#endif
#ifdef __clang__
#pragma clang diagnostic ignored "-Wpragma-pack"
#endif
#ifdef _WIN64
#pragma pack(push,8)
#else
#pragma pack(push,4)
#endif
#endif
