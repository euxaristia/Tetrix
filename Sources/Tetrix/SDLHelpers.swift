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
