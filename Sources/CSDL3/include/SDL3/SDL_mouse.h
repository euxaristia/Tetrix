/*
  Minimal SDL3 mouse header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_mouse_h_
#define SDL_mouse_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_error.h>
#include <SDL3/SDL_surface.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef Uint32 SDL_MouseID;
typedef struct SDL_Cursor SDL_Cursor;

/* Mouse button flags */
typedef Uint32 SDL_MouseButtonFlags;
#define SDL_BUTTON_LEFT     1
#define SDL_BUTTON_MIDDLE   2
#define SDL_BUTTON_RIGHT    3
#define SDL_BUTTON_X1       4
#define SDL_BUTTON_X2       5

/* Mouse wheel direction */
typedef enum SDL_MouseWheelDirection {
    SDL_MOUSEWHEEL_NORMAL,
    SDL_MOUSEWHEEL_FLIPPED
} SDL_MouseWheelDirection;

typedef enum SDL_SystemCursor {
    SDL_SYSTEM_CURSOR_DEFAULT,
    SDL_SYSTEM_CURSOR_ARROW,
    SDL_SYSTEM_CURSOR_IBEAM,
    SDL_SYSTEM_CURSOR_WAIT,
    SDL_SYSTEM_CURSOR_CROSSHAIR,
    SDL_SYSTEM_CURSOR_WAITARROW,
    SDL_SYSTEM_CURSOR_SIZENWSE,
    SDL_SYSTEM_CURSOR_SIZENESW,
    SDL_SYSTEM_CURSOR_SIZEWE,
    SDL_SYSTEM_CURSOR_SIZENS,
    SDL_SYSTEM_CURSOR_SIZEALL,
    SDL_SYSTEM_CURSOR_NO,
    SDL_SYSTEM_CURSOR_HAND,
    SDL_SYSTEM_CURSOR_COUNT
} SDL_SystemCursor;

/* Touch/pen mouse IDs */
#define SDL_TOUCH_MOUSEID ((Uint32)-1)
#define SDL_PEN_MOUSEID ((Uint32)-2)

/* Function declarations - only what's needed */
extern SDL_DECLSPEC int SDLCALL SDL_ShowCursor(void);
extern SDL_DECLSPEC int SDLCALL SDL_HideCursor(void);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_mouse_h_ */
