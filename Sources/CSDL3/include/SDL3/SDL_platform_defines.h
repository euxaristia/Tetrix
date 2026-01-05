/*
  Minimal SDL3 platform defines header - Swift-native replacement
  Only includes essential platform detection macros
*/

#ifndef SDL_platform_defines_h_
#define SDL_platform_defines_h_

/* Minimal platform detection - only what's needed for compilation */
#ifdef _WIN32
#define SDL_PLATFORM_WINDOWS 1
#elif defined(__APPLE__)
#define SDL_PLATFORM_APPLE 1
#ifdef __MACH__
#define SDL_PLATFORM_MACOS 1
#endif
#elif defined(__linux__)
#define SDL_PLATFORM_LINUX 1
#elif defined(__ANDROID__)
#define SDL_PLATFORM_ANDROID 1
#elif defined(__FreeBSD__)
#define SDL_PLATFORM_FREEBSD 1
#elif defined(__DragonFly__)
#define SDL_PLATFORM_DRAGONFLY 1
#elif defined(__NetBSD__)
#define SDL_PLATFORM_NETBSD 1
#elif defined(__OpenBSD__)
#define SDL_PLATFORM_OPENBSD 1
#elif defined(__unix__)
#define SDL_PLATFORM_UNIX 1
#endif

#endif /* SDL_platform_defines_h_ */
