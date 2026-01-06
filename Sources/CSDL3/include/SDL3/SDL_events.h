/* Clean replacement for SDL_events.h - no copyright dependencies */

#ifndef SDL_events_h_
#define SDL_events_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_keyboard.h>
#include <SDL3/SDL_keycode.h>
#include <SDL3/SDL_scancode.h>
#include <SDL3/SDL_gamepad.h>
#include <SDL3/SDL_joystick.h>
#include <SDL3/SDL_video.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Event type enumeration - only types used in Tetrix */
typedef enum SDL_EventType
{
    SDL_EVENT_FIRST = 0,
    
    /* Application events */
    SDL_EVENT_QUIT = 0x100,
    
    /* Window events */
    SDL_EVENT_WINDOW_SHOWN = 0x202,
    SDL_EVENT_WINDOW_HIDDEN,
    SDL_EVENT_WINDOW_EXPOSED,
    SDL_EVENT_WINDOW_MOVED,
    SDL_EVENT_WINDOW_RESIZED,
    SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED,
    SDL_EVENT_WINDOW_MINIMIZED,
    SDL_EVENT_WINDOW_MAXIMIZED,
    SDL_EVENT_WINDOW_RESTORED,
    SDL_EVENT_WINDOW_MOUSE_ENTER,
    SDL_EVENT_WINDOW_MOUSE_LEAVE,
    SDL_EVENT_WINDOW_FOCUS_GAINED,
    SDL_EVENT_WINDOW_FOCUS_LOST,
    SDL_EVENT_WINDOW_CLOSE_REQUESTED,
    
    /* Keyboard events */
    SDL_EVENT_KEY_DOWN = 0x300,
    SDL_EVENT_KEY_UP,
    
    /* Joystick events */
    SDL_EVENT_JOYSTICK_AXIS_MOTION = 0x600,
    
    /* Gamepad events */
    SDL_EVENT_GAMEPAD_AXIS_MOTION = 0x650,
    SDL_EVENT_GAMEPAD_BUTTON_DOWN,
    SDL_EVENT_GAMEPAD_BUTTON_UP,
    SDL_EVENT_GAMEPAD_ADDED,
    SDL_EVENT_GAMEPAD_REMOVED,
    
    /* Bounds */
    SDL_EVENT_LAST = 0xFFFF,
    SDL_EVENT_ENUM_PADDING = 0x7FFFFFFF
} SDL_EventType;

/* Common event fields - must match SDL3 binary layout exactly */
typedef struct SDL_CommonEvent
{
    Uint32 type;
    Uint32 reserved;
    Uint64 timestamp;
} SDL_CommonEvent;

/* Window event - must match SDL3 binary layout exactly */
typedef struct SDL_WindowEvent
{
    SDL_EventType type;
    Uint32 reserved;
    Uint64 timestamp;
    SDL_WindowID windowID;
    Sint32 data1;
    Sint32 data2;
} SDL_WindowEvent;

/* Keyboard event - must match SDL3 binary layout exactly */
/* Field order and sizes must match SDL3 library's structure */
typedef struct SDL_KeyboardEvent
{
    SDL_EventType type;       /* Uint32 - 4 bytes */
    Uint32 reserved;          /* 4 bytes */
    Uint64 timestamp;         /* 8 bytes - offset 8 */
    SDL_WindowID windowID;    /* Uint32 - 4 bytes - offset 16 */
    SDL_KeyboardID which;     /* Uint32 - 4 bytes - offset 20 */
    SDL_Scancode scancode;    /* enum (int) - 4 bytes - offset 24 */
    SDL_Keycode key;          /* Uint32 - 4 bytes - offset 28 */
    SDL_Keymod mod;           /* Uint16 - 2 bytes - offset 32 */
    Uint16 raw;               /* 2 bytes - offset 34 */
    bool down;                /* 1 byte - offset 36 */
    bool repeat;              /* 1 byte - offset 37 */
    /* Padding to ensure proper alignment */
} SDL_KeyboardEvent;

/* Gamepad axis event */
typedef struct SDL_GamepadAxisEvent
{
    SDL_EventType type;
    Uint32 reserved;
    Uint64 timestamp;
    SDL_JoystickID which;
    Uint8 axis;
    Sint16 value;
    Uint16 padding;
} SDL_GamepadAxisEvent;

/* Gamepad button event */
typedef struct SDL_GamepadButtonEvent
{
    SDL_EventType type;
    Uint32 reserved;
    Uint64 timestamp;
    SDL_JoystickID which;
    Uint8 button;
    bool down;
    Uint8 padding1;
    Uint8 padding2;
} SDL_GamepadButtonEvent;

/* Gamepad device event */
typedef struct SDL_GamepadDeviceEvent
{
    SDL_EventType type;
    Uint32 reserved;
    Uint64 timestamp;
    SDL_JoystickID which;
} SDL_GamepadDeviceEvent;

/* Quit event */
typedef struct SDL_QuitEvent
{
    SDL_EventType type;
    Uint32 reserved;
    Uint64 timestamp;
} SDL_QuitEvent;

/* Main event union - must match SDL3 binary layout exactly */
/* All union members start at offset 0 and overlap in memory */
typedef union SDL_Event
{
    Uint32 type;                              /* Event type - shared by all events */
    SDL_CommonEvent common;                   /* Common event data */
    SDL_WindowEvent window;                   /* Window event data */
    SDL_KeyboardEvent key;                    /* Keyboard event data */
    SDL_GamepadAxisEvent gaxis;               /* Gamepad axis event data */
    SDL_GamepadButtonEvent gbutton;           /* Gamepad button event data */
    SDL_GamepadDeviceEvent gdevice;           /* Gamepad device event data */
    SDL_QuitEvent quit;                       /* Quit event data */
    
    /* Padding to ensure union is exactly 128 bytes - SDL3 ABI requirement */
    /* This must match the actual SDL3 library's union size */
    Uint8 padding[128];
} SDL_Event;

/* Verify union size matches SDL3 expectation (128 bytes) */
SDL_COMPILE_TIME_ASSERT(SDL_Event, sizeof(SDL_Event) == 128);

/* Event functions */
extern SDL_DECLSPEC void SDLCALL SDL_PumpEvents(void);
extern SDL_DECLSPEC bool SDLCALL SDL_PollEvent(SDL_Event *event);
extern SDL_DECLSPEC bool SDLCALL SDL_HasEvent(Uint32 type);
extern SDL_DECLSPEC bool SDLCALL SDL_HasEvents(Uint32 minType, Uint32 maxType);
extern SDL_DECLSPEC void SDLCALL SDL_FlushEvent(Uint32 type);
extern SDL_DECLSPEC void SDLCALL SDL_FlushEvents(Uint32 minType, Uint32 maxType);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_events_h_ */
