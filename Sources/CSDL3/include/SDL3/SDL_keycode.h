/*
  Minimal SDL3 keycode header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_keycode_h_
#define SDL_keycode_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_scancode.h>

typedef Uint32 SDL_Keycode;

#define SDLK_EXTENDED_MASK          (1u << 29)
#define SDLK_SCANCODE_MASK          (1u << 30)
#define SDL_SCANCODE_TO_KEYCODE(X)  (X | SDLK_SCANCODE_MASK)

/* Basic keycode constants - minimal set */
#define SDLK_UNKNOWN                0x00000000u
#define SDLK_RETURN                 0x0000000du
#define SDLK_ESCAPE                 0x0000001bu
#define SDLK_BACKSPACE              0x00000008u
#define SDLK_TAB                    0x00000009u
#define SDLK_SPACE                  0x00000020u
#define SDLK_0                      0x00000030u
#define SDLK_1                      0x00000031u
#define SDLK_2                      0x00000032u
#define SDLK_3                      0x00000033u
#define SDLK_4                      0x00000034u
#define SDLK_5                      0x00000035u
#define SDLK_6                      0x00000036u
#define SDLK_7                      0x00000037u
#define SDLK_8                      0x00000038u
#define SDLK_9                      0x00000039u
#define SDLK_a                      0x00000061u
#define SDLK_b                      0x00000062u
#define SDLK_c                      0x00000063u
#define SDLK_d                      0x00000064u
#define SDLK_e                      0x00000065u
#define SDLK_f                      0x00000066u
#define SDLK_g                      0x00000067u
#define SDLK_h                      0x00000068u
#define SDLK_i                      0x00000069u
#define SDLK_j                      0x0000006au
#define SDLK_k                      0x0000006bu
#define SDLK_l                      0x0000006cu
#define SDLK_m                      0x0000006du
#define SDLK_n                      0x0000006eu
#define SDLK_o                      0x0000006fu
#define SDLK_p                      0x00000070u
#define SDLK_q                      0x00000071u
#define SDLK_r                      0x00000072u
#define SDLK_s                      0x00000073u
#define SDLK_t                      0x00000074u
#define SDLK_u                      0x00000075u
#define SDLK_v                      0x00000076u
#define SDLK_w                      0x00000077u
#define SDLK_x                      0x00000078u
#define SDLK_y                      0x00000079u
#define SDLK_z                      0x0000007au
#define SDLK_UP                     0x40000052u
#define SDLK_DOWN                   0x40000051u
#define SDLK_LEFT                   0x40000050u
#define SDLK_RIGHT                  0x4000004Fu

#endif /* SDL_keycode_h_ */
