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

/* Common event fields */
typedef struct SDL_CommonEvent
{
    Uint32 type;
    Uint32 reserved;
    Uint64 timestamp;
} SDL_CommonEvent;

/* Window event */
typedef struct SDL_WindowEvent
{
    SDL_EventType type;
    Uint32 reserved;
    Uint64 timestamp;
    SDL_WindowID windowID;
    Sint32 data1;
    Sint32 data2;
} SDL_WindowEvent;

/* Keyboard event */
typedef struct SDL_KeyboardEvent
{
    SDL_EventType type;
    Uint32 reserved;
    Uint64 timestamp;
    SDL_WindowID windowID;
    SDL_KeyboardID which;
    SDL_Scancode scancode;
    SDL_Keycode key;
    SDL_Keymod mod;
    Uint16 raw;
    bool down;
    bool repeat;
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

/* Main event union - only includes types used in Tetrix */
typedef union SDL_Event
{
    Uint32 type;
    SDL_CommonEvent common;
    SDL_WindowEvent window;
    SDL_KeyboardEvent key;
    SDL_GamepadAxisEvent gaxis;
    SDL_GamepadButtonEvent gbutton;
    SDL_GamepadDeviceEvent gdevice;
    SDL_QuitEvent quit;
    
    /* Padding to ensure ABI compatibility */
    Uint8 padding[128];
} SDL_Event;

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
