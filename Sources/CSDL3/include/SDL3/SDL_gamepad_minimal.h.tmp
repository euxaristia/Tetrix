// Minimal SDL3 gamepad header - forward declarations only
// No copyright - this is a minimal stub for Swift interop

#ifndef SDL_gamepad_h_
#define SDL_gamepad_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_error.h>
#include <SDL3/SDL_guid.h>
#include <SDL3/SDL_joystick.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque gamepad handle
typedef struct SDL_Gamepad SDL_Gamepad;

// Gamepad button enum (minimal - only what's needed)
typedef enum {
    SDL_GAMEPAD_BUTTON_INVALID = -1,
    SDL_GAMEPAD_BUTTON_SOUTH = 0,
    SDL_GAMEPAD_BUTTON_EAST = 1,
    SDL_GAMEPAD_BUTTON_WEST = 2,
    SDL_GAMEPAD_BUTTON_NORTH = 3,
    SDL_GAMEPAD_BUTTON_BACK = 4,
    SDL_GAMEPAD_BUTTON_GUIDE = 5,
    SDL_GAMEPAD_BUTTON_START = 6,
    SDL_GAMEPAD_BUTTON_LEFT_STICK = 7,
    SDL_GAMEPAD_BUTTON_RIGHT_STICK = 8,
    SDL_GAMEPAD_BUTTON_LEFT_SHOULDER = 9,
    SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER = 10,
    SDL_GAMEPAD_BUTTON_DPAD_UP = 11,
    SDL_GAMEPAD_BUTTON_DPAD_DOWN = 12,
    SDL_GAMEPAD_BUTTON_DPAD_LEFT = 13,
    SDL_GAMEPAD_BUTTON_DPAD_RIGHT = 14
} SDL_GamepadButton;

// Function declarations - only what's used
extern SDL_DECLSPEC bool SDLCALL SDL_IsGamepad(SDL_JoystickID instance_id);
extern SDL_DECLSPEC SDL_Gamepad * SDLCALL SDL_OpenGamepad(SDL_JoystickID instance_id);
extern SDL_DECLSPEC void SDLCALL SDL_CloseGamepad(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadName(SDL_Gamepad *gamepad);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_gamepad_h_ */
