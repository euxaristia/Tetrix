import Foundation

#if os(Windows)
import WinSDK
    #elseif os(macOS)
// macOS uses SDL3 for rendering, no special imports needed
#elseif os(Linux)
import Glibc
import CSDL3
// Linux: Simple bitmap font renderer using SDL3 renderer
#endif

// MARK: - Swift-Native Text Renderer (Replaces SDL3_ttf)

/// Swift-native text renderer using platform-specific APIs
class SwiftTextRenderer {
    #if os(Windows)
    // Windows now uses SDL3 for rendering, so use the same bitmap font approach as Linux
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
        let pattern = BitmapFont.getPattern(char)
        
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
    
    func measureText(_ text: String) -> (width: Int32, height: Int32) {
        let charWidth: Int32 = 8
        let charHeight: Int32 = 12
        let spacing: Int32 = 1
        let width = Int32(text.count) * (charWidth + spacing) - spacing
        return (width, charHeight)
    }
    
    #elseif os(macOS)
    // macOS now uses SDL3 for rendering, so use the same bitmap font approach as Linux/Windows
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
        let pattern = BitmapFont.getPattern(char)
        
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
    
    func measureText(_ text: String) -> (width: Int32, height: Int32) {
        let charWidth: Int32 = 8
        let charHeight: Int32 = 12
        let spacing: Int32 = 1
        let width = Int32(text.count) * (charWidth + spacing) - spacing
        return (width, charHeight)
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
