import Foundation

#if os(Windows)
import WinSDK
#elseif os(macOS)
import Cocoa
import AppKit
import CoreText
#elseif os(Linux)
import Glibc
import CSDL3
// Linux: Simple bitmap font renderer using SDL3 renderer
#endif

// MARK: - Swift-Native Text Renderer (Replaces SDL3_ttf)

/// Swift-native text renderer using platform-specific APIs
class SwiftTextRenderer {
    #if os(Windows)
    private var hdc: HDC?
    private var hFont: HFONT?
    
    init?(hdc: HDC) {
        self.hdc = hdc
        // Create a simple font (Arial, 20pt) using CreateFontW
        let fontName = "Arial"
        var fontArray = Array<WCHAR>()
        fontName.utf16.forEach { fontArray.append($0) }
        fontArray.append(0) // Null terminator
        
        fontArray.withUnsafeMutableBufferPointer { buffer in
            self.hFont = CreateFontW(
                20, 0, 0, 0,
                FW_NORMAL,
                DWORD(0), // not italic
                DWORD(0), // not underlined
                DWORD(0), // not strikeout
                DEFAULT_CHARSET,
                OUT_DEFAULT_PRECIS,
                CLIP_DEFAULT_PRECIS,
                DEFAULT_QUALITY,
                DWORD(DEFAULT_PITCH | FF_DONTCARE),
                buffer.baseAddress
            )
        }
        guard let hFont = hFont else { return nil }
        _ = SelectObject(hdc, hFont)
    }
    
    func drawText(_ text: String, at x: Int32, y: Int32, color: (r: UInt8, g: UInt8, b: UInt8)) {
        guard let hdc = hdc else { return }
        
        // Select the font before drawing
        if let hFont = hFont {
            _ = SelectObject(hdc, hFont)
        }
        
        SetTextColor(hdc, RGB(color.r, color.g, color.b))
        SetBkMode(hdc, TRANSPARENT)
        
        let utf16Text = Array(text.utf16)
        guard !utf16Text.isEmpty else { return }
        var utf16Buffer = utf16Text
        utf16Buffer.append(0) // Null terminator
        let textLength = Int32(utf16Text.count)
        
        utf16Buffer.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            _ = TextOutW(hdc, x, y, baseAddress, textLength)
        }
        
        // Force a redraw/invalidate to ensure text appears
        // This might be needed for immediate mode GDI
    }
    
    func measureText(_ text: String) -> (width: Int32, height: Int32) {
        guard let hdc = hdc else { return (0, 0) }
        
        let utf16Text = text.utf16
        let textLength = Int32(utf16Text.count)
        var utf16Buffer = Array(utf16Text)
        utf16Buffer.append(0) // Null terminator
        
        var size = SIZE()
        _ = GetTextExtentPoint32W(hdc, &utf16Buffer, textLength, &size)
        return (size.cx, size.cy)
    }
    
    deinit {
        if let hFont = hFont {
            DeleteObject(hFont)
        }
    }
    
    #elseif os(macOS)
    private var font: NSFont
    private var view: NSView?
    
    init?() {
        // Create system font at 20pt
        guard let font = NSFont(name: "Arial Bold", size: 20) ??
                        NSFont.systemFont(ofSize: 20) as NSFont? else {
            return nil
        }
        self.font = font
    }
    
    func setView(_ view: NSView) {
        self.view = view
    }
    
    func drawText(_ text: String, at x: Int32, y: Int32, color: (r: UInt8, g: UInt8, b: UInt8)) {
        // On macOS, we need to draw directly to the view
        guard let view = view else { return }
        
        // Lock focus on the view to get a drawing context
        view.lockFocus()
        defer { view.unlockFocus() }
        
        let nsColor = NSColor(
            red: CGFloat(color.r) / 255.0,
            green: CGFloat(color.g) / 255.0,
            blue: CGFloat(color.b) / 255.0,
            alpha: 1.0
        )
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: nsColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // Draw at the specified position
        // Note: macOS coordinate system has origin at bottom-left, but NSView drawing
        // typically uses top-left origin, so we may need to adjust
        let viewHeight = view.bounds.height
        let adjustedY = viewHeight - CGFloat(y) - font.pointSize
        attributedString.draw(at: CGPoint(x: CGFloat(x), y: adjustedY))
    }
    
    func measureText(_ text: String) -> (width: Int32, height: Int32) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, [])
        return (Int32(bounds.width), Int32(bounds.height))
    }
    
    #elseif os(Linux)
    // Linux: Simple bitmap font renderer using SDL3 renderer
    private var renderer: RendererProtocol?
    
    init?() {
        // Simple initialization - renderer will be set later
    }
    
    func setRenderer(_ renderer: RendererProtocol) {
        self.renderer = renderer
    }
    
    func drawText(_ text: String, at x: Int32, y: Int32, color: (r: UInt8, g: UInt8, b: UInt8)) {
        guard let renderer = renderer else { return }
        
        // Simple bitmap font renderer - draw characters using rectangles
        // Character size: 8x12 pixels, with 1 pixel spacing
        let charWidth: Int32 = 8
        let charHeight: Int32 = 12
        let spacing: Int32 = 1
        
        var currentX = x
        for char in text {
            drawChar(char, at: currentX, y: y, color: color, renderer: renderer, charWidth: charWidth, charHeight: charHeight)
            currentX += charWidth + spacing
        }
    }
    
    private func drawChar(_ char: Character, at x: Int32, y: Int32, color: (r: UInt8, g: UInt8, b: UInt8), renderer: RendererProtocol, charWidth: Int32, charHeight: Int32) {
        // Simple 8x12 bitmap font for basic ASCII characters
        // Each character is represented as a pattern of filled rectangles
        let pattern = getCharPattern(char)
        
        let pixelSize: Int32 = 1
        for row in 0..<Int(charHeight) {
            for col in 0..<Int(charWidth) {
                if row < pattern.count && col < pattern[row].count && pattern[row][col] {
                    let pixelX = x + Int32(col) * pixelSize
                    let pixelY = y + Int32(row) * pixelSize
                    let rect = Rect(x: Float(pixelX), y: Float(pixelY), width: Float(pixelSize), height: Float(pixelSize))
                    renderer.setDrawColor(r: color.r, g: color.g, b: color.b, a: 255)
                    renderer.fillRect(rect)
                }
            }
        }
    }
    
    private func getCharPattern(_ char: Character) -> [[Bool]] {
        return BitmapFont.getPattern(char)
    }
    
    func measureText(_ text: String) -> (width: Int32, height: Int32) {
        let charWidth: Int32 = 8
        let charHeight: Int32 = 12
        let spacing: Int32 = 1
        let width = Int32(text.count) * (charWidth + spacing) - spacing
        return (width, charHeight)
    }
    #endif
}
