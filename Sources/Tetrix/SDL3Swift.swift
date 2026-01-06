// Swift-native SDL3 bindings
// This file replaces the need for direct C header imports in Swift code
// The underlying SDL3 C library is still linked, but Swift code uses these types

import Foundation

// MARK: - Basic Types

public typealias SDL_InitFlags = UInt32
public typealias SDL_Scancode = UInt32
public typealias SDL_Keycode = Int32
public typealias SDL_GamepadButton = Int32
public typealias SDL_GamepadAxis = Int32
public typealias SDL_EventType = UInt32
public typealias SDL_RendererLogicalPresentation = UInt32

// MARK: - Init Flags

public struct SDLInitFlags {
    public static let AUDIO: UInt32 = 0x00000010
    public static let VIDEO: UInt32 = 0x00000020
    public static let JOYSTICK: UInt32 = 0x00000200
    public static let HAPTIC: UInt32 = 0x00001000
    public static let GAMEPAD: UInt32 = 0x00002000
    public static let EVENTS: UInt32 = 0x00004000
    public static let SENSOR: UInt32 = 0x00008000
    public static let CAMERA: UInt32 = 0x00010000
}

// MARK: - Scancode Constants

public struct SDLScancode {
    public static let A: UInt32 = 4
    public static let B: UInt32 = 5
    public static let C: UInt32 = 6
    public static let D: UInt32 = 7
    public static let E: UInt32 = 8
    public static let F: UInt32 = 9
    public static let G: UInt32 = 10
    public static let H: UInt32 = 11
    public static let I: UInt32 = 12
    public static let J: UInt32 = 13
    public static let K: UInt32 = 14
    public static let L: UInt32 = 15
    public static let M: UInt32 = 16
    public static let N: UInt32 = 17
    public static let O: UInt32 = 18
    public static let P: UInt32 = 19
    public static let Q: UInt32 = 20
    public static let R: UInt32 = 21
    public static let S: UInt32 = 22
    public static let T: UInt32 = 23
    public static let U: UInt32 = 24
    public static let V: UInt32 = 25
    public static let W: UInt32 = 26
    public static let X: UInt32 = 27
    public static let Y: UInt32 = 28
    public static let Z: UInt32 = 29
    public static let SPACE: UInt32 = 44
    public static let ESCAPE: UInt32 = 41
    public static let LEFT: UInt32 = 80
    public static let RIGHT: UInt32 = 79
    public static let UP: UInt32 = 82
    public static let DOWN: UInt32 = 81
    public static let F11: UInt32 = 95
}

// MARK: - Gamepad Button Constants

public struct SDLGamepadButton {
    public static let INVALID: Int32 = -1
    public static let SOUTH: Int32 = 0      // A button
    public static let EAST: Int32 = 1      // B button
    public static let WEST: Int32 = 2      // X button
    public static let NORTH: Int32 = 3     // Y button
    public static let BACK: Int32 = 4
    public static let GUIDE: Int32 = 5
    public static let START: Int32 = 6
    public static let LEFT_STICK: Int32 = 7
    public static let RIGHT_STICK: Int32 = 8
    public static let LEFT_SHOULDER: Int32 = 9
    public static let RIGHT_SHOULDER: Int32 = 10
    public static let DPAD_UP: Int32 = 11
    public static let DPAD_DOWN: Int32 = 12
    public static let DPAD_LEFT: Int32 = 13
    public static let DPAD_RIGHT: Int32 = 14
}

// MARK: - Event Type Constants

public struct SDLEventType {
    public static let QUIT: UInt32 = 0x100
    public static let KEY_DOWN: UInt32 = 0x300
    public static let KEY_UP: UInt32 = 0x301
    public static let GAMEPAD_ADDED: UInt32 = 0x650
    public static let GAMEPAD_REMOVED: UInt32 = 0x651
    public static let GAMEPAD_BUTTON_DOWN: UInt32 = 0x652
    public static let GAMEPAD_BUTTON_UP: UInt32 = 0x653
    public static let GAMEPAD_AXIS_MOTION: UInt32 = 0x654
    public static let JOYSTICK_AXIS_MOTION: UInt32 = 0x600
    public static let WINDOW_FOCUS_LOST: UInt32 = 0x203
    public static let WINDOW_FOCUS_GAINED: UInt32 = 0x202
}

// MARK: - Renderer Logical Presentation

public struct SDLLogicalPresentation {
    public static let DISABLED: UInt32 = 0
    public static let LETTERBOX: UInt32 = 1
    public static let OVERSCAN: UInt32 = 2
    public static let INTEGER_SCALE: UInt32 = 3
    public static let STRETCH: UInt32 = 4
}

// MARK: - Window Flags

public struct SDLWindowFlags {
    public static let HIDDEN: UInt64 = 0x8
    public static let RESIZABLE: UInt64 = 0x20
    public static let FULLSCREEN: UInt64 = 0x00000001
}

// MARK: - C Interop Types (still needed for C function calls)

// These types are imported from the C module but re-exported here for convenience
// The actual C structs are defined in the C headers but we provide Swift-friendly access
