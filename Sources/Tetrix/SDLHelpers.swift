import Foundation
import CSDL3

#if os(Windows)
import WinSDK
#endif

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
            // Try to get error message, but provide more context if unavailable
            let errorMsg = String.sdlError() ?? "Unknown SDL error (SDL_GetError returned NULL or empty)"
            self = .failure(errorMsg)
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

/// SDL subsystem initialization flags (replaces SDL_INIT_* constants)
enum SDLSubsystem: UInt32 {
    case video = 0x00000020      // SDL_INIT_VIDEO
    case audio = 0x00000010      // SDL_INIT_AUDIO
    case gamepad = 0x00002000    // SDL_INIT_GAMEPAD
    
    static func combine(subsystems: [SDLSubsystem]) -> UInt32 {
        return subsystems.reduce(0) { $0 | $1.rawValue }
    }
}

/// Helper functions for SDL operations
struct SDLHelper {
    /// Initialize SDL subsystems
    static func initialize(_ flags: UInt32) -> SDLResult {
        // Clear any previous error
        SDL_ClearError()
        let result = SDL_Init(flags)
        // SDL_Init returns 0 on success, non-zero on failure
        if result != 0 {
            // Get the error message immediately after failure
            let errorMsg = String.sdlError() ?? "SDL_Init returned error code \(result)"
            return .failure(errorMsg)
        }
        return .success
    }
    
    /// Initialize SDL with subsystem flags
    static func initialize(subsystems: SDLSubsystem...) -> SDLResult {
        let flags = SDLSubsystem.combine(subsystems: subsystems)
        return initialize(flags)
    }
    
    // TTF initialization removed - using Swift-native text rendering
    
    /// Create a window with Swift string
    static func createWindow(title: String, width: Int32, height: Int32, flags: UInt64) -> OpaquePointer? {
        return title.withSDLString { cString in
            SDL_CreateWindow(cString, width, height, flags)
        }
    }
    
    /// Destroy a window
    static func destroyWindow(_ window: OpaquePointer?) {
        if let window = window {
            SDL_DestroyWindow(window)
        }
    }
    
    /// Quit SDL subsystems
    static func quit() {
        SDL_Quit()
    }
    
    /// Get error message or default
    static func errorMessage(default: String = "Unknown error") -> String {
        return String.sdlError() ?? `default`
    }
}

// TTFHelper removed - using Swift-native text rendering in SwiftTextRenderer

/// Swift-native window flags (replaces SDL_WINDOW_* constants)
enum WindowFlag: UInt64 {
    case hidden = 0x8
    case resizable = 0x20
    case fullscreen = 0x00000001
    
    static func combine(_ flags: WindowFlag...) -> UInt64 {
        return flags.reduce(0) { $0 | $1.rawValue }
    }
}

/// Swift-native logical presentation mode (replaces SDL_LOGICAL_PRESENTATION_* constants)
enum LogicalPresentationMode {
    case disabled
    case letterbox
    case overscan
    case integerScale
    case stretch
    
    func toSDL() -> SDL_RendererLogicalPresentation {
        switch self {
        case .disabled:
            return UInt32(SDL_LOGICAL_PRESENTATION_DISABLED.rawValue)
        case .letterbox:
            return UInt32(SDL_LOGICAL_PRESENTATION_LETTERBOX.rawValue)
        case .overscan:
            return UInt32(SDL_LOGICAL_PRESENTATION_OVERSCAN.rawValue)
        case .integerScale:
            return UInt32(SDL_LOGICAL_PRESENTATION_INTEGER_SCALE.rawValue)
        case .stretch:
            return UInt32(SDL_LOGICAL_PRESENTATION_STRETCH.rawValue)
        }
    }
}

/// Helper for SDL rendering operations
struct SDLRenderHelper {
    /// Create a renderer for a window
    static func create(window: OpaquePointer?) -> OpaquePointer? {
        return SDL_CreateRenderer(window, nil)
    }
    
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
    
    /// Set render logical presentation (uses Swift-native mode enum)
    static func setLogicalPresentation(renderer: OpaquePointer?, width: Int32, height: Int32, mode: LogicalPresentationMode) -> Bool {
        let rawValue = mode.toSDL()
        #if os(Windows)
        return SDL_SetRenderLogicalPresentation(renderer, width, height, CSDL3.SDL_RendererLogicalPresentation(rawValue: Int32(rawValue)))
        #else
        return SDL_SetRenderLogicalPresentation(renderer, width, height, CSDL3.SDL_RendererLogicalPresentation(rawValue: UInt32(rawValue)))
        #endif
    }
    
    /// Set render logical presentation (legacy C type version)
    static func setLogicalPresentation(renderer: OpaquePointer?, width: Int32, height: Int32, mode: SDL_RendererLogicalPresentation) -> Bool {
        #if os(Windows)
        return SDL_SetRenderLogicalPresentation(renderer, width, height, CSDL3.SDL_RendererLogicalPresentation(rawValue: Int32(mode)))
        #else
        return SDL_SetRenderLogicalPresentation(renderer, width, height, CSDL3.SDL_RendererLogicalPresentation(rawValue: UInt32(mode)))
        #endif
    }
    
    /// Show window and ensure it gets focus
    static func show(window: OpaquePointer?) {
        SDL_ShowWindow(window)
        // Raise window to ensure it gets focus and is responsive
        SDL_RaiseWindow(window)
        // Pump events multiple times to ensure window manager processes the show/raise
        // This is critical for the window to receive keyboard focus on all platforms
        for _ in 0..<10 {
            SDL_PumpEvents()
            // Small delay to allow window manager to process events
            PlatformHelper.sleep(milliseconds: 1)
        }
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
    /// Pump events from the OS into SDL's event queue
    /// This ensures window events (like X button hover) are captured immediately
    static func pumpEvents() {
        SDL_PumpEvents()
    }
    
    /// Flush analog stick events from the queue to prevent lag
    /// This removes SDL_EVENT_GAMEPAD_AXIS_MOTION and SDL_EVENT_JOYSTICK_AXIS_MOTION events
    static func flushAnalogEvents() {
        let GAMEPAD_AXIS_MOTION: UInt32 = 0x650  // SDL_EVENT_GAMEPAD_AXIS_MOTION
        let JOYSTICK_AXIS_MOTION: UInt32 = 0x600  // SDL_EVENT_JOYSTICK_AXIS_MOTION
        // Flush all analog stick events from the queue
        SDL_FlushEvents(JOYSTICK_AXIS_MOTION, GAMEPAD_AXIS_MOTION)
    }
    
    /// Poll for events - returns true if an event was available
    static func pollEvent(_ event: inout SDL_Event) -> Bool {
        return SDL_PollEvent(&event)
    }
    
    /// Check if there are pending events in the queue (without removing them)
    static func hasPendingEvents() -> Bool {
        // Use SDL_HasEvents to check without consuming events
        // SDL_EVENT_FIRST (0x0000) to SDL_EVENT_LAST (0x7FFF) covers all event types
        return SDL_HasEvents(0x0000, 0x7FFF)
    }
    
    /// Get keyboard event scancode (Swift wrapper for cleaner access)
    static func getScancode(from keyEvent: inout SDL_KeyboardEvent) -> SDL_Scancode {
        // Access scancode field directly from the structure
        // SDL_Scancode is an enum, convert to UInt32 for KeyCode
        return UInt32(keyEvent.scancode.rawValue)
    }
    
    /// Get keyboard event repeat flag
    static func isRepeat(from keyEvent: inout SDL_KeyboardEvent) -> Bool {
        return keyEvent.repeat
    }
    
    /// Get gamepad button from event
    static func getButton(from buttonEvent: inout SDL_GamepadButtonEvent) -> UInt8 {
        return buttonEvent.button
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
        // Sleep function is available from Windows API
        let sleepTime = DWORD(milliseconds)
        _ = WinSDK.Sleep(sleepTime)
        #else
        usleep(UInt32(milliseconds * 1000)) // Convert ms to microseconds
        #endif
    }
}

// MARK: - Swift-Native Types

/// Swift-native rectangle type (replaces SDL_FRect)
struct Rect {
    var x: Float
    var y: Float
    var width: Float
    var height: Float
    
    init(x: Float, y: Float, width: Float, height: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    /// Convert to SDL_FRect for C interop
    func toSDL() -> SDL_FRect {
        return SDL_FRect(x: x, y: y, w: width, h: height)
    }
    
    /// Create from SDL_FRect
    static func fromSDL(_ sdlRect: SDL_FRect) -> Rect {
        return Rect(x: sdlRect.x, y: sdlRect.y, width: sdlRect.w, height: sdlRect.h)
    }
}

/// Swift-native color type (replaces SDL_Color)
struct Color {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8
    
    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    /// Convert to SDL_Color for C interop
    func toSDL() -> SDL_Color {
        return SDL_Color(r: r, g: g, b: b, a: a)
    }
    
    /// Common colors
    static let black = Color(r: 0, g: 0, b: 0)
    static let white = Color(r: 255, g: 255, b: 255)
    static let red = Color(r: 255, g: 0, b: 0)
    static let green = Color(r: 0, g: 255, b: 0)
    static let blue = Color(r: 0, g: 0, b: 255)
}

// MARK: - Renderer Protocol

/// Protocol for rendering operations (unifies SDL3 and Swift-native renderers)
protocol RendererProtocol {
    func setDrawColor(_ color: Color)
    func setDrawColor(r: UInt8, g: UInt8, b: UInt8, a: UInt8)
    func clear()
    func fillRect(_ rect: Rect)
    func drawRect(_ rect: Rect)
    func present()
    func renderTexture(_ texture: Texture, at rect: Rect, source: Rect?)
    var sdlHandle: OpaquePointer? { get }
}

// MARK: - Renderer Wrapper (SDL3)

/// Swift-native renderer wrapper (encapsulates SDL renderer operations)
class Renderer: RendererProtocol {
    private let sdlRenderer: OpaquePointer?
    
    init(sdlRenderer: OpaquePointer?) {
        self.sdlRenderer = sdlRenderer
    }
    
    /// Set draw color
    func setDrawColor(_ color: Color) {
        SDLRenderHelper.setDrawColor(renderer: sdlRenderer, r: color.r, g: color.g, b: color.b, a: color.a)
    }
    
    /// Set draw color with RGB components
    func setDrawColor(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        SDLRenderHelper.setDrawColor(renderer: sdlRenderer, r: r, g: g, b: b, a: a)
    }
    
    /// Clear the renderer
    func clear() {
        SDLRenderHelper.clear(renderer: sdlRenderer)
    }
    
    /// Fill a rectangle
    func fillRect(_ rect: Rect) {
        var sdlRect = rect.toSDL()
        SDLRenderHelper.fillRect(renderer: sdlRenderer, rect: &sdlRect)
    }
    
    /// Draw a rectangle outline
    func drawRect(_ rect: Rect) {
        var sdlRect = rect.toSDL()
        SDLRenderHelper.drawRect(renderer: sdlRenderer, rect: &sdlRect)
    }
    
    /// Present the rendered frame
    func present() {
        SDL_RenderPresent(sdlRenderer)
    }
    
    /// Render a texture
    func renderTexture(_ texture: Texture, at rect: Rect, source: Rect? = nil) {
        var destRect = rect.toSDL()
        guard let sdlTexture = texture.sdlTexture else { return }
        // SDL3 API: Convert UnsafeMutablePointer to the expected type
        let texturePtr = sdlTexture
        if let source = source {
            var srcRect = source.toSDL()
            _ = SDL_RenderTexture(sdlRenderer, texturePtr, &srcRect, &destRect)
        } else {
            _ = SDL_RenderTexture(sdlRenderer, texturePtr, nil, &destRect)
        }
    }
    
    /// Get underlying SDL renderer (for advanced operations)
    var sdlHandle: OpaquePointer? {
        return sdlRenderer
    }
}

// MARK: - Texture Wrapper

/// Swift-native texture wrapper
class Texture {
    let sdlTexture: UnsafeMutablePointer<SDL_Texture>?
    let width: Float
    let height: Float
    
    private init(sdlTexture: UnsafeMutablePointer<SDL_Texture>?, width: Float, height: Float) {
        self.sdlTexture = sdlTexture
        self.width = width
        self.height = height
    }
    
    /// Create texture from surface
    static func fromSurface(renderer: OpaquePointer?, surface: UnsafeMutablePointer<SDL_Surface>?) -> Texture? {
        guard let surface = surface else { return nil }
        guard let texture = SDL_CreateTextureFromSurface(renderer, surface) else { return nil }
        SDL_DestroySurface(surface)
        
        var width: Int32 = 0
        var height: Int32 = 0
        SDL_GetTextureSize(texture, &width, &height)
        
        return Texture(sdlTexture: texture, width: Float(width), height: Float(height))
    }
    
    /// Create texture from text (Linux only - uses SDL3 text rendering)
    static func fromText(renderer: OpaquePointer?, font: OpaquePointer?, text: String, color: Color) -> Texture? {
        // This method is only used on Linux where we still use SDL3
        // On Windows/macOS, text rendering is handled natively
        #if os(Linux)
        // For Linux, we'll create a simple bitmap text renderer
        // For now, return nil - text rendering will be handled differently
        return nil
        #else
        return nil
        #endif
    }
    
    deinit {
        if let texture = sdlTexture {
            SDL_DestroyTexture(texture)
        }
    }
}

// MARK: - Gamepad Button Enum (replaces SDL_GAMEPAD_BUTTON_* constants)

/// Swift-native gamepad button enum (replaces SDL_GAMEPAD_BUTTON_* constants)
enum GamepadButton: UInt8 {
    case a = 0           // SDL_GAMEPAD_BUTTON_A
    case b = 1           // SDL_GAMEPAD_BUTTON_B
    case x = 2           // SDL_GAMEPAD_BUTTON_X
    case y = 3           // SDL_GAMEPAD_BUTTON_Y
    case back = 4        // SDL_GAMEPAD_BUTTON_BACK (Share on DualSense)
    case guide = 5       // SDL_GAMEPAD_BUTTON_GUIDE
    case start = 6       // SDL_GAMEPAD_BUTTON_START (Options on DualSense)
    case leftStick = 7   // SDL_GAMEPAD_BUTTON_LEFT_STICK
    case rightStick = 8  // SDL_GAMEPAD_BUTTON_RIGHT_STICK
    case leftShoulder = 9 // SDL_GAMEPAD_BUTTON_LEFT_SHOULDER
    case rightShoulder = 10 // SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER
    case dpadUp = 11     // SDL_GAMEPAD_BUTTON_DPAD_UP
    case dpadDown = 12   // SDL_GAMEPAD_BUTTON_DPAD_DOWN
    case dpadLeft = 13   // SDL_GAMEPAD_BUTTON_DPAD_LEFT
    case dpadRight = 14  // SDL_GAMEPAD_BUTTON_DPAD_RIGHT
    
    init?(rawValue: UInt8) {
        switch rawValue {
        case 0: self = .a
        case 1: self = .b
        case 2: self = .x
        case 3: self = .y
        case 4: self = .back
        case 5: self = .guide
        case 6: self = .start
        case 7: self = .leftStick
        case 8: self = .rightStick
        case 9: self = .leftShoulder
        case 10: self = .rightShoulder
        case 11: self = .dpadUp
        case 12: self = .dpadDown
        case 13: self = .dpadLeft
        case 14: self = .dpadRight
        default: return nil
        }
    }
}

// MARK: - Gamepad Wrapper

/// Swift-native gamepad wrapper
class Gamepad {
    private let sdlGamepad: OpaquePointer?
    let id: UInt32
    
    init?(id: UInt32) {
        self.id = id
        self.sdlGamepad = SDL_OpenGamepad(id)
        if sdlGamepad == nil {
            return nil
        }
    }
    
    var name: String? {
        return SDLGamepadHelper.getName(gamepad: sdlGamepad)
    }
    
    func close() {
        if let gamepad = sdlGamepad {
            SDL_CloseGamepad(gamepad)
        }
    }
    
    deinit {
        close()
    }
}

// MARK: - Event System

/// Swift-native event types
enum GameEvent {
    case quit
    case keyDown(KeyCode, isRepeat: Bool)
    case keyUp(KeyCode)
    case gamepadAdded(UInt32)
    case gamepadRemoved(UInt32)
    case gamepadButtonDown(UInt8)
    case gamepadButtonUp(UInt8)
    case windowFocusLost
    case windowFocusGained
}

/// Swift-native key code enum (replaces SDL_Scancode usage)
enum KeyCode {
    case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
    case space
    case escape
    case left, right, up, down
    case f11
    case unknown(UInt32)
    
    init(from scancode: SDL_Scancode) {
        let scancodeValue = UInt32(scancode)
        switch scancodeValue {
        case UInt32(SDL_SCANCODE_A.rawValue): self = .a
        case UInt32(SDL_SCANCODE_B.rawValue): self = .b
        case UInt32(SDL_SCANCODE_C.rawValue): self = .c
        case UInt32(SDL_SCANCODE_D.rawValue): self = .d
        case UInt32(SDL_SCANCODE_E.rawValue): self = .e
        case UInt32(SDL_SCANCODE_F.rawValue): self = .f
        case UInt32(SDL_SCANCODE_G.rawValue): self = .g
        case UInt32(SDL_SCANCODE_H.rawValue): self = .h
        case UInt32(SDL_SCANCODE_I.rawValue): self = .i
        case UInt32(SDL_SCANCODE_J.rawValue): self = .j
        case UInt32(SDL_SCANCODE_K.rawValue): self = .k
        case UInt32(SDL_SCANCODE_L.rawValue): self = .l
        case UInt32(SDL_SCANCODE_M.rawValue): self = .m
        case UInt32(SDL_SCANCODE_N.rawValue): self = .n
        case UInt32(SDL_SCANCODE_O.rawValue): self = .o
        case UInt32(SDL_SCANCODE_P.rawValue): self = .p
        case UInt32(SDL_SCANCODE_Q.rawValue): self = .q
        case UInt32(SDL_SCANCODE_R.rawValue): self = .r
        case UInt32(SDL_SCANCODE_S.rawValue): self = .s
        case UInt32(SDL_SCANCODE_T.rawValue): self = .t
        case UInt32(SDL_SCANCODE_U.rawValue): self = .u
        case UInt32(SDL_SCANCODE_V.rawValue): self = .v
        case UInt32(SDL_SCANCODE_W.rawValue): self = .w
        case UInt32(SDL_SCANCODE_X.rawValue): self = .x
        case UInt32(SDL_SCANCODE_Y.rawValue): self = .y
        case UInt32(SDL_SCANCODE_Z.rawValue): self = .z
        case UInt32(SDL_SCANCODE_SPACE.rawValue): self = .space
        case UInt32(SDL_SCANCODE_ESCAPE.rawValue): self = .escape
        case UInt32(SDL_SCANCODE_LEFT.rawValue): self = .left
        case UInt32(SDL_SCANCODE_RIGHT.rawValue): self = .right
        case UInt32(SDL_SCANCODE_UP.rawValue): self = .up
        case UInt32(SDL_SCANCODE_DOWN.rawValue): self = .down
        case UInt32(SDL_SCANCODE_F11.rawValue): self = .f11
        default: self = .unknown(scancodeValue)
        }
    }
}

/// Event poller that converts SDL events to Swift-native events
struct EventPoller {
    /// Poll for next event, returns Swift-native event or nil
    static func poll() -> GameEvent? {
        var sdlEvent = SDL_Event()
        guard SDLEventHelper.pollEvent(&sdlEvent) else {
            return nil
        }
        
        let eventType = UInt32(sdlEvent.type)
        
        // Filter out analog stick events immediately - they flood the queue and cause lag
        // We only use D-pad buttons, so we don't need axis motion events
        let GAMEPAD_AXIS_MOTION: UInt32 = 0x650  // SDL_EVENT_GAMEPAD_AXIS_MOTION
        let JOYSTICK_AXIS_MOTION: UInt32 = 0x600  // SDL_EVENT_JOYSTICK_AXIS_MOTION
        if eventType == GAMEPAD_AXIS_MOTION || eventType == JOYSTICK_AXIS_MOTION {
            // Skip analog stick events - return nil to continue polling
            return nil
        }
        
        // Also filter out other gamepad events we don't need
        let GAMEPAD_TOUCHPAD_DOWN: UInt32 = 0x655
        let GAMEPAD_TOUCHPAD_MOTION: UInt32 = 0x656
        let GAMEPAD_TOUCHPAD_UP: UInt32 = 0x657
        let GAMEPAD_SENSOR_UPDATE: UInt32 = 0x658
        let GAMEPAD_UPDATE_COMPLETE: UInt32 = 0x659
        if eventType == GAMEPAD_TOUCHPAD_DOWN || eventType == GAMEPAD_TOUCHPAD_MOTION ||
           eventType == GAMEPAD_TOUCHPAD_UP || eventType == GAMEPAD_SENSOR_UPDATE ||
           eventType == GAMEPAD_UPDATE_COMPLETE {
            // Skip these events too
            return nil
        }
        
        switch eventType {
        case UInt32(SDL_EVENT_QUIT.rawValue):
            return .quit
            
        case UInt32(SDL_EVENT_KEY_DOWN.rawValue):
            // Access union member directly - all union members share the same memory at offset 0
            var keyEvent = sdlEvent.key
            let scancode = SDLEventHelper.getScancode(from: &keyEvent)
            let isRepeat = SDLEventHelper.isRepeat(from: &keyEvent)
            return .keyDown(KeyCode(from: scancode), isRepeat: isRepeat)
            
        case UInt32(SDL_EVENT_KEY_UP.rawValue):
            // Access union member directly
            var keyEvent = sdlEvent.key
            let scancode = SDLEventHelper.getScancode(from: &keyEvent)
            return .keyUp(KeyCode(from: scancode))
            
        case UInt32(SDL_EVENT_GAMEPAD_ADDED.rawValue):
            // Access union member directly
            let gamepadEvent = sdlEvent.gdevice
            return .gamepadAdded(gamepadEvent.which)
            
        case UInt32(SDL_EVENT_GAMEPAD_REMOVED.rawValue):
            // Access union member directly
            let gamepadEvent = sdlEvent.gdevice
            return .gamepadRemoved(gamepadEvent.which)
            
        case UInt32(SDL_EVENT_GAMEPAD_BUTTON_DOWN.rawValue):
            // Access union member directly
            var buttonEvent = sdlEvent.gbutton
            return .gamepadButtonDown(SDLEventHelper.getButton(from: &buttonEvent))
            
        case UInt32(SDL_EVENT_GAMEPAD_BUTTON_UP.rawValue):
            // Access union member directly
            var buttonEvent = sdlEvent.gbutton
            return .gamepadButtonUp(SDLEventHelper.getButton(from: &buttonEvent))
            
        case UInt32(SDL_EVENT_WINDOW_FOCUS_LOST.rawValue):
            return .windowFocusLost
            
        case UInt32(SDL_EVENT_WINDOW_FOCUS_GAINED.rawValue):
            return .windowFocusGained
            
        default:
            // Skip all other events (including analog stick, touchpad, sensor, etc.)
            return nil
        }
    }
}

// MARK: - Renderer Creation Helper

/// Helper to create renderer
// RendererHelper removed - using Renderer class directly
