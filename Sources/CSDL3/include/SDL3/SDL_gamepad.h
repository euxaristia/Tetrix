/* Clean replacement for SDL_gamepad.h - no copyright dependencies */

#ifndef SDL_gamepad_h_
#define SDL_gamepad_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_error.h>
#include <SDL3/SDL_guid.h>
#include <SDL3/SDL_iostream.h>
#include <SDL3/SDL_joystick.h>
#include <SDL3/SDL_power.h>
#include <SDL3/SDL_properties.h>
#include <SDL3/SDL_sensor.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque gamepad structure */
typedef struct SDL_Gamepad SDL_Gamepad;

/* Gamepad types */
typedef enum SDL_GamepadType {
    SDL_GAMEPAD_TYPE_UNKNOWN = 0,
    SDL_GAMEPAD_TYPE_STANDARD,
    SDL_GAMEPAD_TYPE_XBOX360,
    SDL_GAMEPAD_TYPE_XBOXONE,
    SDL_GAMEPAD_TYPE_PS3,
    SDL_GAMEPAD_TYPE_PS4,
    SDL_GAMEPAD_TYPE_PS5,
    SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_PRO,
    SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_JOYCON_LEFT,
    SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_JOYCON_RIGHT,
    SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_JOYCON_PAIR,
    SDL_GAMEPAD_TYPE_GAMECUBE,
    SDL_GAMEPAD_TYPE_COUNT
} SDL_GamepadType;

/* Gamepad buttons */
typedef enum SDL_GamepadButton {
    SDL_GAMEPAD_BUTTON_INVALID = -1,
    SDL_GAMEPAD_BUTTON_SOUTH = 0,        /* Bottom face button (e.g. Xbox A button) */
    SDL_GAMEPAD_BUTTON_EAST = 1,         /* Right face button (e.g. Xbox B button) */
    SDL_GAMEPAD_BUTTON_WEST = 2,         /* Left face button (e.g. Xbox X button) */
    SDL_GAMEPAD_BUTTON_NORTH = 3,        /* Top face button (e.g. Xbox Y button) */
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
    SDL_GAMEPAD_BUTTON_DPAD_RIGHT = 14,
    SDL_GAMEPAD_BUTTON_MISC1 = 15,
    SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1 = 16,
    SDL_GAMEPAD_BUTTON_LEFT_PADDLE1 = 17,
    SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2 = 18,
    SDL_GAMEPAD_BUTTON_LEFT_PADDLE2 = 19,
    SDL_GAMEPAD_BUTTON_TOUCHPAD = 20,
    SDL_GAMEPAD_BUTTON_MISC2 = 21,
    SDL_GAMEPAD_BUTTON_MISC3 = 22,
    SDL_GAMEPAD_BUTTON_MISC4 = 23,
    SDL_GAMEPAD_BUTTON_MISC5 = 24,
    SDL_GAMEPAD_BUTTON_MISC6 = 25,
    SDL_GAMEPAD_BUTTON_COUNT = 26
} SDL_GamepadButton;

/* Gamepad button labels */
typedef enum SDL_GamepadButtonLabel {
    SDL_GAMEPAD_BUTTON_LABEL_UNKNOWN,
    SDL_GAMEPAD_BUTTON_LABEL_A,
    SDL_GAMEPAD_BUTTON_LABEL_B,
    SDL_GAMEPAD_BUTTON_LABEL_X,
    SDL_GAMEPAD_BUTTON_LABEL_Y,
    SDL_GAMEPAD_BUTTON_LABEL_CROSS,
    SDL_GAMEPAD_BUTTON_LABEL_CIRCLE,
    SDL_GAMEPAD_BUTTON_LABEL_SQUARE,
    SDL_GAMEPAD_BUTTON_LABEL_TRIANGLE
} SDL_GamepadButtonLabel;

/* Gamepad axes */
typedef enum SDL_GamepadAxis {
    SDL_GAMEPAD_AXIS_INVALID = -1,
    SDL_GAMEPAD_AXIS_LEFTX = 0,
    SDL_GAMEPAD_AXIS_LEFTY = 1,
    SDL_GAMEPAD_AXIS_RIGHTX = 2,
    SDL_GAMEPAD_AXIS_RIGHTY = 3,
    SDL_GAMEPAD_AXIS_LEFT_TRIGGER = 4,
    SDL_GAMEPAD_AXIS_RIGHT_TRIGGER = 5,
    SDL_GAMEPAD_AXIS_COUNT = 6
} SDL_GamepadAxis;

/* Query gamepad availability */
extern SDL_DECLSPEC bool SDLCALL SDL_HasGamepad(void);

/* Get list of connected gamepads */
extern SDL_DECLSPEC SDL_JoystickID * SDLCALL SDL_GetGamepads(int *count);

/* Check if joystick is a gamepad */
extern SDL_DECLSPEC bool SDLCALL SDL_IsGamepad(SDL_JoystickID instance_id);

/* Query gamepad information by ID (before opening) */
extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadNameForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadPathForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC int SDLCALL SDL_GetGamepadPlayerIndexForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC SDL_GUID SDLCALL SDL_GetGamepadGUIDForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetGamepadVendorForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetGamepadProductForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetGamepadProductVersionForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC SDL_GamepadType SDLCALL SDL_GetGamepadTypeForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC SDL_GamepadType SDLCALL SDL_GetRealGamepadTypeForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC char * SDLCALL SDL_GetGamepadMappingForID(SDL_JoystickID instance_id);

/* Open/close gamepad */
extern SDL_DECLSPEC SDL_Gamepad * SDLCALL SDL_OpenGamepad(SDL_JoystickID instance_id);
extern SDL_DECLSPEC SDL_Gamepad * SDLCALL SDL_GetGamepadFromID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC SDL_Gamepad * SDLCALL SDL_GetGamepadFromPlayerIndex(int player_index);
extern SDL_DECLSPEC void SDLCALL SDL_CloseGamepad(SDL_Gamepad *gamepad);

/* Query opened gamepad information */
extern SDL_DECLSPEC SDL_PropertiesID SDLCALL SDL_GetGamepadProperties(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC SDL_JoystickID SDLCALL SDL_GetGamepadID(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadName(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadPath(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC SDL_GamepadType SDLCALL SDL_GetGamepadType(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC SDL_GamepadType SDLCALL SDL_GetRealGamepadType(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC int SDLCALL SDL_GetGamepadPlayerIndex(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC bool SDLCALL SDL_SetGamepadPlayerIndex(SDL_Gamepad *gamepad, int player_index);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetGamepadVendor(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetGamepadProduct(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetGamepadProductVersion(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetGamepadFirmwareVersion(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadSerial(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC Uint64 SDLCALL SDL_GetGamepadSteamHandle(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC SDL_JoystickConnectionState SDLCALL SDL_GetGamepadConnectionState(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC SDL_PowerState SDLCALL SDL_GetGamepadPowerInfo(SDL_Gamepad *gamepad, int *percent);
extern SDL_DECLSPEC bool SDLCALL SDL_GamepadConnected(SDL_Gamepad *gamepad);

/* Get underlying joystick */
extern SDL_DECLSPEC SDL_Joystick * SDLCALL SDL_GetGamepadJoystick(SDL_Gamepad *gamepad);

/* Query gamepad state */
extern SDL_DECLSPEC bool SDLCALL SDL_GamepadHasAxis(SDL_Gamepad *gamepad, SDL_GamepadAxis axis);
extern SDL_DECLSPEC Sint16 SDLCALL SDL_GetGamepadAxis(SDL_Gamepad *gamepad, SDL_GamepadAxis axis);
extern SDL_DECLSPEC bool SDLCALL SDL_GamepadHasButton(SDL_Gamepad *gamepad, SDL_GamepadButton button);
extern SDL_DECLSPEC bool SDLCALL SDL_GetGamepadButton(SDL_Gamepad *gamepad, SDL_GamepadButton button);
extern SDL_DECLSPEC SDL_GamepadButtonLabel SDLCALL SDL_GetGamepadButtonLabelForType(SDL_GamepadType type, SDL_GamepadButton button);
extern SDL_DECLSPEC SDL_GamepadButtonLabel SDLCALL SDL_GetGamepadButtonLabel(SDL_Gamepad *gamepad, SDL_GamepadButton button);

/* Touchpad support */
extern SDL_DECLSPEC int SDLCALL SDL_GetNumGamepadTouchpads(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC int SDLCALL SDL_GetNumGamepadTouchpadFingers(SDL_Gamepad *gamepad, int touchpad);
extern SDL_DECLSPEC bool SDLCALL SDL_GetGamepadTouchpadFinger(SDL_Gamepad *gamepad, int touchpad, int finger, bool *down, float *x, float *y, float *pressure);

/* Sensor support */
extern SDL_DECLSPEC bool SDLCALL SDL_GamepadHasSensor(SDL_Gamepad *gamepad, SDL_SensorType type);
extern SDL_DECLSPEC bool SDLCALL SDL_SetGamepadSensorEnabled(SDL_Gamepad *gamepad, SDL_SensorType type, bool enabled);
extern SDL_DECLSPEC bool SDLCALL SDL_GamepadSensorEnabled(SDL_Gamepad *gamepad, SDL_SensorType type);
extern SDL_DECLSPEC float SDLCALL SDL_GetGamepadSensorDataRate(SDL_Gamepad *gamepad, SDL_SensorType type);
extern SDL_DECLSPEC bool SDLCALL SDL_GetGamepadSensorData(SDL_Gamepad *gamepad, SDL_SensorType type, float *data, int num_values);

/* Rumble/LED/effects */
extern SDL_DECLSPEC bool SDLCALL SDL_RumbleGamepad(SDL_Gamepad *gamepad, Uint16 low_frequency_rumble, Uint16 high_frequency_rumble, Uint32 duration_ms);
extern SDL_DECLSPEC bool SDLCALL SDL_RumbleGamepadTriggers(SDL_Gamepad *gamepad, Uint16 left_rumble, Uint16 right_rumble, Uint32 duration_ms);
extern SDL_DECLSPEC bool SDLCALL SDL_SetGamepadLED(SDL_Gamepad *gamepad, Uint8 red, Uint8 green, Uint8 blue);
extern SDL_DECLSPEC bool SDLCALL SDL_SendGamepadEffect(SDL_Gamepad *gamepad, const void *data, int size);

/* Event state */
extern SDL_DECLSPEC void SDLCALL SDL_SetGamepadEventsEnabled(bool enabled);
extern SDL_DECLSPEC bool SDLCALL SDL_GamepadEventsEnabled(void);
extern SDL_DECLSPEC void SDLCALL SDL_UpdateGamepads(void);

/* Mapping functions */
extern SDL_DECLSPEC int SDLCALL SDL_AddGamepadMapping(const char *mapping);
extern SDL_DECLSPEC int SDLCALL SDL_AddGamepadMappingsFromIO(SDL_IOStream *src, bool closeio);
extern SDL_DECLSPEC int SDLCALL SDL_AddGamepadMappingsFromFile(const char *file);
extern SDL_DECLSPEC bool SDLCALL SDL_ReloadGamepadMappings(void);
extern SDL_DECLSPEC char ** SDLCALL SDL_GetGamepadMappings(int *count);
extern SDL_DECLSPEC char * SDLCALL SDL_GetGamepadMappingForGUID(SDL_GUID guid);
extern SDL_DECLSPEC char * SDLCALL SDL_GetGamepadMapping(SDL_Gamepad *gamepad);
extern SDL_DECLSPEC bool SDLCALL SDL_SetGamepadMapping(SDL_JoystickID instance_id, const char *mapping);

/* Type conversion utilities */
extern SDL_DECLSPEC SDL_GamepadType SDLCALL SDL_GetGamepadTypeFromString(const char *str);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadStringForType(SDL_GamepadType type);
extern SDL_DECLSPEC SDL_GamepadAxis SDLCALL SDL_GetGamepadAxisFromString(const char *str);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadStringForAxis(SDL_GamepadAxis axis);
extern SDL_DECLSPEC SDL_GamepadButton SDLCALL SDL_GetGamepadButtonFromString(const char *str);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadStringForButton(SDL_GamepadButton button);

/* Apple platform support */
extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadAppleSFSymbolsNameForButton(SDL_Gamepad *gamepad, SDL_GamepadButton button);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetGamepadAppleSFSymbolsNameForAxis(SDL_Gamepad *gamepad, SDL_GamepadAxis axis);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_gamepad_h_ */
