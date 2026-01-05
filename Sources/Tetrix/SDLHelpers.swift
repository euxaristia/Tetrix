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

// MARK: - Renderer Wrapper

/// Swift-native renderer wrapper (encapsulates SDL renderer operations)
class Renderer {
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
        // SDL3 API: Convert OpaquePointer to UnsafeMutablePointer<SDL_Texture>
        let texturePtr = unsafeBitCast(sdlTexture, to: UnsafeMutablePointer<SDL_Texture>.self)
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
        
        var width: Float = 0
        var height: Float = 0
        SDL_GetTextureSize(texture, &width, &height)
        
        return Texture(sdlTexture: texture, width: width, height: height)
    }
    
    /// Create texture from text
    static func fromText(renderer: OpaquePointer?, font: OpaquePointer?, text: String, color: Color) -> Texture? {
        let sdlColor = color.toSDL()
        guard let surface = TTFHelper.renderText(font: font, text: text, color: sdlColor) else {
            return nil
        }
        return fromSurface(renderer: renderer, surface: surface)
    }
    
    deinit {
        if let texture = sdlTexture {
            SDL_DestroyTexture(texture)
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
        switch scancode {
        case SDL_SCANCODE_A: self = .a
        case SDL_SCANCODE_B: self = .b
        case SDL_SCANCODE_C: self = .c
        case SDL_SCANCODE_D: self = .d
        case SDL_SCANCODE_E: self = .e
        case SDL_SCANCODE_F: self = .f
        case SDL_SCANCODE_G: self = .g
        case SDL_SCANCODE_H: self = .h
        case SDL_SCANCODE_I: self = .i
        case SDL_SCANCODE_J: self = .j
        case SDL_SCANCODE_K: self = .k
        case SDL_SCANCODE_L: self = .l
        case SDL_SCANCODE_M: self = .m
        case SDL_SCANCODE_N: self = .n
        case SDL_SCANCODE_O: self = .o
        case SDL_SCANCODE_P: self = .p
        case SDL_SCANCODE_Q: self = .q
        case SDL_SCANCODE_R: self = .r
        case SDL_SCANCODE_S: self = .s
        case SDL_SCANCODE_T: self = .t
        case SDL_SCANCODE_U: self = .u
        case SDL_SCANCODE_V: self = .v
        case SDL_SCANCODE_W: self = .w
        case SDL_SCANCODE_X: self = .x
        case SDL_SCANCODE_Y: self = .y
        case SDL_SCANCODE_Z: self = .z
        case SDL_SCANCODE_SPACE: self = .space
        case SDL_SCANCODE_ESCAPE: self = .escape
        case SDL_SCANCODE_LEFT: self = .left
        case SDL_SCANCODE_RIGHT: self = .right
        case SDL_SCANCODE_UP: self = .up
        case SDL_SCANCODE_DOWN: self = .down
        case SDL_SCANCODE_F11: self = .f11
        default: self = .unknown(scancode.rawValue)
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
        
        switch UInt32(sdlEvent.type) {
        case UInt32(SDL_EVENT_QUIT.rawValue):
            return .quit
            
        case UInt32(SDL_EVENT_KEY_DOWN.rawValue):
            let keyEvent = withUnsafePointer(to: &sdlEvent.key) { $0 }
            let scancode = SDLEventHelper.getScancode(from: keyEvent)
            let isRepeat = SDLEventHelper.isRepeat(from: keyEvent)
            return .keyDown(KeyCode(from: scancode), isRepeat: isRepeat)
            
        case UInt32(SDL_EVENT_KEY_UP.rawValue):
            let keyEvent = withUnsafePointer(to: &sdlEvent.key) { $0 }
            let scancode = SDLEventHelper.getScancode(from: keyEvent)
            return .keyUp(KeyCode(from: scancode))
            
        case UInt32(SDL_EVENT_GAMEPAD_ADDED.rawValue):
            let gamepadEvent = withUnsafePointer(to: &sdlEvent.gdevice) { $0 }
            return .gamepadAdded(gamepadEvent.pointee.which)
            
        case UInt32(SDL_EVENT_GAMEPAD_REMOVED.rawValue):
            let gamepadEvent = withUnsafePointer(to: &sdlEvent.gdevice) { $0 }
            return .gamepadRemoved(gamepadEvent.pointee.which)
            
        case UInt32(SDL_EVENT_GAMEPAD_BUTTON_DOWN.rawValue):
            let buttonEvent = withUnsafePointer(to: &sdlEvent.gbutton) { $0 }
            return .gamepadButtonDown(SDLEventHelper.getButton(from: buttonEvent))
            
        case UInt32(SDL_EVENT_GAMEPAD_BUTTON_UP.rawValue):
            let buttonEvent = withUnsafePointer(to: &sdlEvent.gbutton) { $0 }
            return .gamepadButtonUp(SDLEventHelper.getButton(from: buttonEvent))
            
        case UInt32(SDL_EVENT_WINDOW_FOCUS_LOST.rawValue):
            return .windowFocusLost
            
        case UInt32(SDL_EVENT_WINDOW_FOCUS_GAINED.rawValue):
            return .windowFocusGained
            
        default:
            return nil
        }
    }
}

// MARK: - Renderer Creation Helper

/// Helper to create renderer
struct RendererHelper {
    static func create(window: OpaquePointer?) -> OpaquePointer? {
        return SDL_CreateRenderer(window, nil)
    }
}
