/* Clean replacement for SDL_joystick.h - no copyright dependencies */

#ifndef SDL_joystick_h_
#define SDL_joystick_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_error.h>
#include <SDL3/SDL_guid.h>
#include <SDL3/SDL_mutex.h>
#include <SDL3/SDL_power.h>
#include <SDL3/SDL_properties.h>
#include <SDL3/SDL_sensor.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque joystick structure */
typedef struct SDL_Joystick SDL_Joystick;

/* Joystick instance ID - unique per joystick connection */
typedef Uint32 SDL_JoystickID;

/* Joystick types */
typedef enum SDL_JoystickType {
    SDL_JOYSTICK_TYPE_UNKNOWN,
    SDL_JOYSTICK_TYPE_GAMEPAD,
    SDL_JOYSTICK_TYPE_WHEEL,
    SDL_JOYSTICK_TYPE_ARCADE_STICK,
    SDL_JOYSTICK_TYPE_FLIGHT_STICK,
    SDL_JOYSTICK_TYPE_DANCE_PAD,
    SDL_JOYSTICK_TYPE_GUITAR,
    SDL_JOYSTICK_TYPE_DRUM_KIT,
    SDL_JOYSTICK_TYPE_ARCADE_PAD,
    SDL_JOYSTICK_TYPE_THROTTLE,
    SDL_JOYSTICK_TYPE_COUNT
} SDL_JoystickType;

/* Joystick connection states */
typedef enum SDL_JoystickConnectionState {
    SDL_JOYSTICK_CONNECTION_INVALID = -1,
    SDL_JOYSTICK_CONNECTION_UNKNOWN,
    SDL_JOYSTICK_CONNECTION_WIRED,
    SDL_JOYSTICK_CONNECTION_WIRELESS
} SDL_JoystickConnectionState;

/* Axis value limits */
#define SDL_JOYSTICK_AXIS_MAX   32767
#define SDL_JOYSTICK_AXIS_MIN   -32768

/* Thread safety lock/unlock */
extern SDL_DECLSPEC void SDLCALL SDL_LockJoysticks(void);
extern SDL_DECLSPEC void SDLCALL SDL_UnlockJoysticks(void);

/* Query joystick availability */
extern SDL_DECLSPEC bool SDLCALL SDL_HasJoystick(void);

/* Get list of connected joysticks */
extern SDL_DECLSPEC SDL_JoystickID * SDLCALL SDL_GetJoysticks(int *count);

/* Query joystick information by ID (before opening) */
extern SDL_DECLSPEC const char * SDLCALL SDL_GetJoystickNameForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetJoystickPathForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC int SDLCALL SDL_GetJoystickPlayerIndexForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC SDL_GUID SDLCALL SDL_GetJoystickGUIDForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetJoystickVendorForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetJoystickProductForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetJoystickProductVersionForID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC SDL_JoystickType SDLCALL SDL_GetJoystickTypeForID(SDL_JoystickID instance_id);

/* Open/close joystick */
extern SDL_DECLSPEC SDL_Joystick * SDLCALL SDL_OpenJoystick(SDL_JoystickID instance_id);
extern SDL_DECLSPEC SDL_Joystick * SDLCALL SDL_GetJoystickFromID(SDL_JoystickID instance_id);
extern SDL_DECLSPEC SDL_Joystick * SDLCALL SDL_GetJoystickFromPlayerIndex(int player_index);
extern SDL_DECLSPEC void SDLCALL SDL_CloseJoystick(SDL_Joystick *joystick);

/* Query opened joystick information */
extern SDL_DECLSPEC SDL_PropertiesID SDLCALL SDL_GetJoystickProperties(SDL_Joystick *joystick);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetJoystickName(SDL_Joystick *joystick);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetJoystickPath(SDL_Joystick *joystick);
extern SDL_DECLSPEC int SDLCALL SDL_GetJoystickPlayerIndex(SDL_Joystick *joystick);
extern SDL_DECLSPEC bool SDLCALL SDL_SetJoystickPlayerIndex(SDL_Joystick *joystick, int player_index);
extern SDL_DECLSPEC SDL_GUID SDLCALL SDL_GetJoystickGUID(SDL_Joystick *joystick);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetJoystickVendor(SDL_Joystick *joystick);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetJoystickProduct(SDL_Joystick *joystick);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetJoystickProductVersion(SDL_Joystick *joystick);
extern SDL_DECLSPEC Uint16 SDLCALL SDL_GetJoystickFirmwareVersion(SDL_Joystick *joystick);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetJoystickSerial(SDL_Joystick *joystick);
extern SDL_DECLSPEC SDL_JoystickType SDLCALL SDL_GetJoystickType(SDL_Joystick *joystick);
extern SDL_DECLSPEC bool SDLCALL SDL_JoystickConnected(SDL_Joystick *joystick);
extern SDL_DECLSPEC SDL_JoystickID SDLCALL SDL_GetJoystickID(SDL_Joystick *joystick);
extern SDL_DECLSPEC SDL_JoystickConnectionState SDLCALL SDL_GetJoystickConnectionState(SDL_Joystick *joystick);

/* Query joystick capabilities */
extern SDL_DECLSPEC int SDLCALL SDL_GetNumJoystickAxes(SDL_Joystick *joystick);
extern SDL_DECLSPEC int SDLCALL SDL_GetNumJoystickBalls(SDL_Joystick *joystick);
extern SDL_DECLSPEC int SDLCALL SDL_GetNumJoystickHats(SDL_Joystick *joystick);
extern SDL_DECLSPEC int SDLCALL SDL_GetNumJoystickButtons(SDL_Joystick *joystick);

/* Query joystick state */
extern SDL_DECLSPEC Sint16 SDLCALL SDL_GetJoystickAxis(SDL_Joystick *joystick, int axis);
extern SDL_DECLSPEC bool SDLCALL SDL_GetJoystickAxisInitialState(SDL_Joystick *joystick, int axis, Sint16 *state);
extern SDL_DECLSPEC bool SDLCALL SDL_GetJoystickBall(SDL_Joystick *joystick, int ball, int *dx, int *dy);
extern SDL_DECLSPEC Uint8 SDLCALL SDL_GetJoystickHat(SDL_Joystick *joystick, int hat);
extern SDL_DECLSPEC bool SDLCALL SDL_GetJoystickButton(SDL_Joystick *joystick, int button);

/* Event state */
extern SDL_DECLSPEC bool SDLCALL SDL_JoystickEventsEnabled(void);

/* Rumble/LED/effects */
extern SDL_DECLSPEC bool SDLCALL SDL_RumbleJoystick(SDL_Joystick *joystick, Uint16 low_frequency_rumble, Uint16 high_frequency_rumble, Uint32 duration_ms);
extern SDL_DECLSPEC bool SDLCALL SDL_RumbleJoystickTriggers(SDL_Joystick *joystick, Uint16 left_rumble, Uint16 right_rumble, Uint32 duration_ms);
extern SDL_DECLSPEC bool SDLCALL SDL_SetJoystickLED(SDL_Joystick *joystick, Uint8 red, Uint8 green, Uint8 blue);
extern SDL_DECLSPEC bool SDLCALL SDL_SendJoystickEffect(SDL_Joystick *joystick, const void *data, int size);

/* Power information */
extern SDL_DECLSPEC SDL_PowerState SDLCALL SDL_GetJoystickPowerInfo(SDL_Joystick *joystick, int *percent);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_joystick_h_ */
