import Foundation
import CSDL3

// Swift wrappers to reduce C interop code

extension String {
    /// Get SDL error message as a Swift String, or nil if no error
    static func sdlError() -> String? {
        guard let error = SDL_GetError() else { return nil }
        let errorString = String(cString: error)
        return errorString.isEmpty ? nil : errorString
    }
    
    /// Execute a closure with a C string pointer, automatically handling conversion
    func withSDLString<T>(_ body: (UnsafePointer<CChar>) -> T) -> T {
        return self.withCString(body)
    }
    
    /// Get the UTF-8 byte length (for SDL functions that need length)
    var sdlLength: Int32 {
        return Int32(self.utf8.count)
    }
}

/// SDL initialization result
enum SDLResult {
    case success
    case failure(String)
    
    init(_ success: Bool) {
        if success {
            self = .success
        } else {
            self = .failure(String.sdlError() ?? "Unknown SDL error")
        }
    }
    
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self {
            return message
        }
        return nil
    }
}

/// Helper functions for SDL operations
struct SDLHelper {
    /// Initialize SDL subsystems
    static func initialize(_ flags: UInt32) -> SDLResult {
        let success = SDL_Init(flags)
        return SDLResult(success)
    }
    
    /// Initialize TTF
    static func initializeTTF() -> SDLResult {
        let success = TTF_Init()
        return SDLResult(success)
    }
    
    /// Create a window with Swift string
    static func createWindow(title: String, width: Int32, height: Int32, flags: UInt64) -> OpaquePointer? {
        return title.withSDLString { cString in
            SDL_CreateWindow(cString, width, height, flags)
        }
    }
    
    /// Get error message or default
    static func errorMessage(default: String = "Unknown error") -> String {
        return String.sdlError() ?? `default`
    }
}

/// Helper for TTF font operations
struct TTFHelper {
    /// Open a font file with Swift string path
    static func openFont(path: String, pointSize: Float) -> OpaquePointer? {
        return path.withSDLString { cString in
            TTF_OpenFont(cString, pointSize)
        }
    }
    
    /// Render text to a surface
    static func renderText(font: OpaquePointer?, text: String, color: SDL_Color) -> UnsafeMutablePointer<SDL_Surface>? {
        return text.withSDLString { cString in
            let length = Int(text.utf8.count)
            return TTF_RenderText_Solid(font, cString, length, color)
        }
    }
}

/// Helper for SDL rendering operations
struct SDLRenderHelper {
    /// Set render draw color
    static func setDrawColor(renderer: OpaquePointer?, r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        SDL_SetRenderDrawColor(renderer, r, g, b, a)
    }
    
    /// Clear the renderer
    static func clear(renderer: OpaquePointer?) {
        SDL_RenderClear(renderer)
    }
    
    /// Fill a rectangle
    static func fillRect(renderer: OpaquePointer?, rect: inout SDL_FRect) {
        SDL_RenderFillRect(renderer, &rect)
    }
    
    /// Fill a rectangle (non-mutable version)
    static func fillRect(renderer: OpaquePointer?, rect: SDL_FRect) {
        var mutableRect = rect
        SDL_RenderFillRect(renderer, &mutableRect)
    }
    
    /// Draw a rectangle outline
    static func drawRect(renderer: OpaquePointer?, rect: inout SDL_FRect) {
        SDL_RenderRect(renderer, &rect)
    }
    
    /// Draw a rectangle outline (non-mutable version)
    static func drawRect(renderer: OpaquePointer?, rect: SDL_FRect) {
        var mutableRect = rect
        SDL_RenderRect(renderer, &mutableRect)
    }
}

/// Helper for SDL window operations
struct SDLWindowHelper {
    /// Set window fullscreen state
    static func setFullscreen(window: OpaquePointer?, fullscreen: Bool) -> Bool {
        return SDL_SetWindowFullscreen(window, fullscreen)
    }
    
    /// Set render logical presentation
    static func setLogicalPresentation(renderer: OpaquePointer?, width: Int32, height: Int32, mode: SDL_RendererLogicalPresentation) -> Bool {
        return SDL_SetRenderLogicalPresentation(renderer, width, height, mode)
    }
    
    /// Show window
    static func show(window: OpaquePointer?) {
        SDL_ShowWindow(window)
    }
    
    /// Maximize window
    static func maximize(window: OpaquePointer?) -> Bool {
        return SDL_MaximizeWindow(window)
    }
}

/// Helper for SDL cursor operations
struct SDLCursorHelper {
    /// Show cursor
    static func show() {
        _ = SDL_ShowCursor()
    }
    
    /// Hide cursor
    static func hide() {
        _ = SDL_HideCursor()
    }
}

/// Helper for SDL event operations
struct SDLEventHelper {
    /// Poll for events - returns true if an event was available
    static func pollEvent(_ event: inout SDL_Event) -> Bool {
        return SDL_PollEvent(&event)
    }
    
    /// Get keyboard event scancode (Swift wrapper for cleaner access)
    static func getScancode(from keyEvent: UnsafePointer<SDL_KeyboardEvent>) -> SDL_Scancode {
        return keyEvent.pointee.scancode
    }
    
    /// Get keyboard event repeat flag
    static func isRepeat(from keyEvent: UnsafePointer<SDL_KeyboardEvent>) -> Bool {
        return keyEvent.pointee.repeat
    }
    
    /// Get gamepad button from event
    static func getButton(from buttonEvent: UnsafePointer<SDL_GamepadButtonEvent>) -> UInt8 {
        return buttonEvent.pointee.button
    }
    
    /// Get gamepad axis from event
    static func getAxis(from axisEvent: UnsafePointer<SDL_GamepadAxisEvent>) -> UInt8 {
        return axisEvent.pointee.axis
    }
    
    /// Get gamepad axis value from event
    static func getAxisValue(from axisEvent: UnsafePointer<SDL_GamepadAxisEvent>) -> Int16 {
        return axisEvent.pointee.value
    }
}

/// Helper for SDL gamepad operations
struct SDLGamepadHelper {
    /// Get gamepad name
    static func getName(gamepad: OpaquePointer?) -> String? {
        guard let name = SDL_GetGamepadName(gamepad) else { return nil }
        return String(cString: name)
    }
    
    /// Get all joystick IDs that are gamepads
    static func getGamepadJoystickIDs() -> [UInt32] {
        var count: Int32 = 0
        guard let joystickIDs = SDL_GetJoysticks(&count) else { return [] }
        
        var result: [UInt32] = []
        for i in 0..<Int(count) {
            let id = joystickIDs[i]
            // Check if this joystick ID is a gamepad
            if SDL_IsGamepad(id) {
                result.append(id)
            }
        }
        return result
    }
}

/// Helper for platform-specific sleep operations
struct PlatformHelper {
    /// Sleep for specified milliseconds
    static func sleep(milliseconds: UInt32) {
        #if os(Windows)
        Sleep(milliseconds)
        #else
        usleep(UInt32(milliseconds * 1000)) // Convert ms to microseconds
        #endif
    }
}
