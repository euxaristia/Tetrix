import Foundation

#if os(Windows)
import WinSDK
#elseif os(macOS)
import Cocoa
import AppKit
#elseif os(Linux)
import Glibc
// Linux: Use SDL3 (which handles both X11 and Wayland automatically)
// For Swift-native implementation, we'd need to use platform-specific APIs
// but since SDL3 already works, we'll keep using it for now
#endif

// MARK: - Swift-Native Graphics Library (Replacing SDL3)

/// Swift-native window class (replaces SDL_Window)
class SwiftWindow {
    #if os(Windows)
    private var hwnd: HWND?
    #elseif os(macOS)
    private var window: NSWindow?
    #elseif os(Linux)
    private var display: OpaquePointer?  // X11Display (Display*)
    private var window: UInt32 = 0  // X11Window (Window)
    #endif
    
    let width: Int32
    let height: Int32
    let title: String
    
    init?(title: String, width: Int32, height: Int32, flags: UInt64) {
        self.title = title
        self.width = width
        self.height = height
        
        #if os(Windows)
        // Windows implementation using Win32 API
        let className = "SwiftTetrixWindow"
        let hInstance = GetModuleHandleW(nil)
        
        // Register window class
        var wc = WNDCLASSW()
        wc.lpfnWndProc = DefWindowProcW
        wc.hInstance = hInstance
        var classNameUtf16 = Array(className.utf16)
        classNameUtf16.append(0) // Null terminator
        classNameUtf16.withUnsafeBufferPointer { ptr in
            wc.lpszClassName = UnsafePointer(ptr.baseAddress)
        }
        wc.hbrBackground = GetSysColorBrush(Int32(COLOR_WINDOW))
        // IDC_ARROW = 32512, MAKEINTRESOURCEW equivalent: cast integer to LPWSTR
        let cursorResource = UnsafePointer<WCHAR>(bitPattern: UInt(32512))!
        wc.hCursor = LoadCursorW(nil, cursorResource)
        
        var registeredClassName = Array(className.utf16)
        registeredClassName.append(0)
        registeredClassName.withUnsafeBufferPointer { ptr in
            wc.lpszClassName = UnsafePointer(ptr.baseAddress)
            _ = RegisterClassW(&wc)
        }
        
        // Create window
        var titleUtf16 = Array(title.utf16)
        titleUtf16.append(0) // Null terminator
        var classNameUtf16ForWindow = Array(className.utf16)
        classNameUtf16ForWindow.append(0)
        let hwnd = CreateWindowExW(
            0,
            classNameUtf16ForWindow.withUnsafeBufferPointer { UnsafePointer($0.baseAddress) },
            titleUtf16.withUnsafeBufferPointer { UnsafePointer($0.baseAddress) },
            DWORD(UInt32(WS_OVERLAPPEDWINDOW) | UInt32(WS_VISIBLE)),
            CW_USEDEFAULT, CW_USEDEFAULT,
            Int32(width), Int32(height),
            nil, nil, hInstance, nil
        )
        
        guard hwnd != nil else { return nil }
        self.hwnd = hwnd
        
        #elseif os(macOS)
        // macOS implementation using AppKit
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
        
        #elseif os(Linux)
        // Linux implementation using X11 via C interop
        // For now, fall back to SDL3 - full X11 implementation requires more work
        // This is a placeholder for future Swift-native X11 implementation
        return nil  // Will use SDL3 for now
        #endif
    }
    
    func show() {
        #if os(Windows)
        ShowWindow(hwnd, SW_SHOW)
        #elseif os(macOS)
        window?.makeKeyAndOrderFront(nil)
        #elseif os(Linux)
        // Placeholder - X11 implementation in progress
        _ = display  // Suppress unused variable warning
        #endif
    }
    
    func maximize() {
        #if os(Windows)
        ShowWindow(hwnd, SW_MAXIMIZE)
        #elseif os(macOS)
        window?.zoom(nil)
        #elseif os(Linux)
        // Placeholder - X11 implementation in progress
        _ = display  // Suppress unused variable warning
        #endif
    }
    
    func setFullscreen(_ fullscreen: Bool) {
        #if os(Windows)
        var style: DWORD = 0
        if fullscreen {
            style = DWORD(UInt32(WS_POPUP) | UInt32(WS_VISIBLE))
        } else {
            style = DWORD(UInt32(WS_OVERLAPPEDWINDOW) | UInt32(WS_VISIBLE))
        }
        SetWindowLongPtrW(hwnd, GWL_STYLE, LONG_PTR(style))
        #elseif os(macOS)
        window?.toggleFullScreen(nil)
        #elseif os(Linux)
        // Placeholder - X11 implementation in progress
        _ = display  // Suppress unused variable warning
        #endif
    }
    
    #if os(Windows)
    var handle: HWND? { return hwnd }
    #elseif os(macOS)
    var nsWindow: NSWindow? { return window }
    #elseif os(Linux)
    var x11Display: OpaquePointer? { return display }
    var x11Window: UInt32 { return window }
    #endif
}

/// Swift-native renderer class (replaces SDL_Renderer)
class SwiftRenderer: RendererProtocol {
    #if os(Windows)
    private var _hdc: HDC?
    private var hwnd: HWND?
    #elseif os(macOS)
    var view: NSView?
    #elseif os(Linux)
    private var display: OpaquePointer?  // X11Display (Display*)
    private var window: UInt32 = 0  // X11Window (Window)
    private var gc: OpaquePointer?  // X11GC (GC)
    #endif
    
    private var drawColor: Color = Color.black
    
    init?(window: SwiftWindow) {
        #if os(Windows)
        guard let hwnd = window.handle else { return nil }
        self.hwnd = hwnd
        self._hdc = GetDC(hwnd)
        guard _hdc != nil else { return nil }
        
        #elseif os(macOS)
        guard let nsWindow = window.nsWindow else { return nil }
        self.view = nsWindow.contentView
        
        #elseif os(Linux)
        // For now, Linux X11 implementation is incomplete
        // Will use SDL3 fallback
        return nil
        #endif
    }
    
    #if os(Windows)
    var hdc: HDC? {
        return self._hdc
    }
    #endif
    
    func setDrawColor(_ color: Color) {
        self.drawColor = color
        #if os(Linux)
        // Placeholder - X11 color handling in progress
        _ = display
        _ = gc
        #endif
    }
    
    func setDrawColor(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        setDrawColor(Color(r: r, g: g, b: b, a: a))
    }
    
    func clear() {
        #if os(Windows)
        guard let hdc = hdc, let hwnd = hwnd else { return }
        var rect = RECT()
        GetClientRect(hwnd, &rect)
        // RGB macro equivalent: (blue << 16) | (green << 8) | red
        let colorRef = DWORD(drawColor.b) << 16 | DWORD(drawColor.g) << 8 | DWORD(drawColor.r)
        let brush = CreateSolidBrush(colorRef)
        FillRect(hdc, &rect, brush)
        DeleteObject(brush)
        
        #elseif os(macOS)
        guard view != nil else { return }
        view?.layer?.backgroundColor = CGColor(
            red: CGFloat(drawColor.r) / 255.0,
            green: CGFloat(drawColor.g) / 255.0,
            blue: CGFloat(drawColor.b) / 255.0,
            alpha: CGFloat(drawColor.a) / 255.0
        )
        
        #elseif os(Linux)
        // Placeholder - X11 implementation in progress
        _ = display  // Suppress unused variable warning
        #endif
    }
    
    func fillRect(_ rect: Rect) {
        #if os(Windows)
        guard let hdc = hdc else { return }
        // RGB macro equivalent: (blue << 16) | (green << 8) | red
        let colorRef = DWORD(drawColor.b) << 16 | DWORD(drawColor.g) << 8 | DWORD(drawColor.r)
        let brush = CreateSolidBrush(colorRef)
        var r = RECT(
            left: LONG(rect.x),
            top: LONG(rect.y),
            right: LONG(rect.x + rect.width),
            bottom: LONG(rect.y + rect.height)
        )
        FillRect(hdc, &r, brush)
        DeleteObject(brush)
        
        #elseif os(macOS)
        guard view != nil else { return }
        let cgRect = CGRect(x: CGFloat(rect.x), y: CGFloat(rect.y), width: CGFloat(rect.width), height: CGFloat(rect.height))
        let cgColor = CGColor(
            red: CGFloat(drawColor.r) / 255.0,
            green: CGFloat(drawColor.g) / 255.0,
            blue: CGFloat(drawColor.b) / 255.0,
            alpha: CGFloat(drawColor.a) / 255.0
        )
        let context = NSGraphicsContext.current?.cgContext
        context?.setFillColor(cgColor)
        context?.fill(cgRect)
        
        #elseif os(Linux)
        // Placeholder - X11 implementation in progress
        _ = display  // Suppress unused variable warning
        #endif
    }
    
    func drawRect(_ rect: Rect) {
        #if os(Windows)
        guard let hdc = hdc else { return }
        // RGB macro equivalent: (blue << 16) | (green << 8) | red
        let colorRef = DWORD(drawColor.b) << 16 | DWORD(drawColor.g) << 8 | DWORD(drawColor.r)
        let pen = CreatePen(PS_SOLID, 1, colorRef)
        let oldPen = SelectObject(hdc, pen)
        var r = RECT(
            left: LONG(rect.x),
            top: LONG(rect.y),
            right: LONG(rect.x + rect.width),
            bottom: LONG(rect.y + rect.height)
        )
        // RGB macro equivalent: (blue << 16) | (green << 8) | red
        let frameColorRef = DWORD(drawColor.b) << 16 | DWORD(drawColor.g) << 8 | DWORD(drawColor.r)
        FrameRect(hdc, &r, CreateSolidBrush(frameColorRef))
        SelectObject(hdc, oldPen)
        DeleteObject(pen)
        
        #elseif os(macOS)
        guard view != nil else { return }
        let cgRect = CGRect(x: CGFloat(rect.x), y: CGFloat(rect.y), width: CGFloat(rect.width), height: CGFloat(rect.height))
        let cgColor = CGColor(
            red: CGFloat(drawColor.r) / 255.0,
            green: CGFloat(drawColor.g) / 255.0,
            blue: CGFloat(drawColor.b) / 255.0,
            alpha: CGFloat(drawColor.a) / 255.0
        )
        let context = NSGraphicsContext.current?.cgContext
        context?.setStrokeColor(cgColor)
        context?.stroke(cgRect)
        
        #elseif os(Linux)
        // Placeholder - X11 implementation in progress
        _ = display  // Suppress unused variable warning
        #endif
    }
    
    func present() {
        #if os(Windows)
        // Windows GDI doesn't need explicit present
        
        #elseif os(macOS)
        view?.needsDisplay = true
        
        #elseif os(Linux)
        // Placeholder - X11 implementation in progress
        _ = display  // Suppress unused variable warning
        #endif
    }
    
    // MARK: - RendererProtocol Conformance
    
    var sdlHandle: OpaquePointer? {
        // Swift-native renderer doesn't expose SDL handle
        return nil
    }
    
    func renderTexture(_ texture: Texture, at rect: Rect, source: Rect? = nil) {
        // TODO: Implement texture rendering for Swift-native renderer
        // For now, this is a placeholder
    }
    
    deinit {
        #if os(Windows)
        if let hdc = hdc, let hwnd = hwnd {
            ReleaseDC(hwnd, hdc)
        }
        #elseif os(Linux)
        // Placeholder - X11 implementation in progress
        _ = display  // Suppress unused variable warning
        #endif
    }
}
