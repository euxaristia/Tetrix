/*
  Minimal SDL3 Header - Only includes headers actually used in Tetrix
  Based on SDL3 3.5.0, but stripped down to reduce C content
*/

#ifndef SDL_h_
#define SDL_h_

// Core SDL headers we actually use
#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_platform.h>
#include <SDL3/SDL_error.h>
#include <SDL3/SDL_assert.h>

// Video and rendering
#include <SDL3/SDL_video.h>
#include <SDL3/SDL_render.h>
#include <SDL3/SDL_surface.h>
#include <SDL3/SDL_rect.h>
#include <SDL3/SDL_pixels.h>

// Input
#include <SDL3/SDL_events.h>
#include <SDL3/SDL_keyboard.h>
#include <SDL3/SDL_keycode.h>
#include <SDL3/SDL_scancode.h>
#include <SDL3/SDL_mouse.h>
#include <SDL3/SDL_gamepad.h>
#include <SDL3/SDL_joystick.h>

// Audio
#include <SDL3/SDL_audio.h>

// Initialization
#include <SDL3/SDL_init.h>

// Compatibility (may be needed) - commented out to avoid conflicts with minimal headers
// #include <SDL3/SDL_oldnames.h>

#endif /* SDL_h_ */
