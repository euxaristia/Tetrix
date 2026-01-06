// Minimal SDL3 video header - forward declarations only
// No copyright - this is a minimal stub for Swift interop

#ifndef SDL_video_h_
#define SDL_video_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_rect.h>
#include <SDL3/SDL_surface.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque window handle
typedef struct SDL_Window SDL_Window;

// Window ID type
typedef Uint32 SDL_WindowID;

// Window flags
typedef Uint64 SDL_WindowFlags;
#define SDL_WINDOW_FULLSCREEN ((Uint64)0x0000000000000001)
#define SDL_WINDOW_HIDDEN ((Uint64)0x0000000000000008)
#define SDL_WINDOW_RESIZABLE ((Uint64)0x0000000000000020)

// Function declarations - only what's used
extern SDL_DECLSPEC SDL_Window * SDLCALL SDL_CreateWindow(const char *title, int w, int h, SDL_WindowFlags flags);
extern SDL_DECLSPEC void SDLCALL SDL_DestroyWindow(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowFullscreen(SDL_Window *window, bool fullscreen);
extern SDL_DECLSPEC void SDLCALL SDL_ShowWindow(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_MaximizeWindow(SDL_Window *window);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_video_h_ */
