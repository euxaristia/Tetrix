/*
  Minimal SDL3 keyboard header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_keyboard_h_
#define SDL_keyboard_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_error.h>
#include <SDL3/SDL_keycode.h>
#include <SDL3/SDL_properties.h>
#include <SDL3/SDL_rect.h>
#include <SDL3/SDL_scancode.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef Uint32 SDL_KeyboardID;

/* Key modifier type */
typedef Uint16 SDL_Keymod;
#define SDL_KMOD_NONE       0x0000
#define SDL_KMOD_LSHIFT     0x0001
#define SDL_KMOD_RSHIFT     0x0002
#define SDL_KMOD_LCTRL      0x0040
#define SDL_KMOD_RCTRL      0x0080
#define SDL_KMOD_LALT       0x0100
#define SDL_KMOD_RALT       0x0200
#define SDL_KMOD_LGUI       0x0400
#define SDL_KMOD_RGUI       0x0800
#define SDL_KMOD_NUM        0x1000
#define SDL_KMOD_CAPS       0x2000
#define SDL_KMOD_MODE       0x4000
#define SDL_KMOD_SCROLL     0x8000
#define SDL_KMOD_CTRL       (SDL_KMOD_LCTRL|SDL_KMOD_RCTRL)
#define SDL_KMOD_SHIFT      (SDL_KMOD_LSHIFT|SDL_KMOD_RSHIFT)
#define SDL_KMOD_ALT        (SDL_KMOD_LALT|SDL_KMOD_RALT)
#define SDL_KMOD_GUI        (SDL_KMOD_LGUI|SDL_KMOD_RGUI)

/* Function declarations - only what's needed */
extern SDL_DECLSPEC bool SDLCALL SDL_HasKeyboard(void);
extern SDL_DECLSPEC SDL_KeyboardID * SDLCALL SDL_GetKeyboards(int *count);
extern SDL_DECLSPEC SDL_Keymod SDLCALL SDL_GetModState(void);
extern SDL_DECLSPEC void SDLCALL SDL_SetModState(SDL_Keymod modstate);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_keyboard_h_ */
