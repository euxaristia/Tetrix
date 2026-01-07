import Foundation
import SwiftSDL

/// Tetris-specific renderer implementation
class TetrisGameRenderer: GameRenderer {
    private weak var engine: TetrisEngine?
    private var highScore: Int = 0
    private var usingController: Bool = false
    private var gamepadExists: Bool = false
    private var musicIsPlaying: Bool = false
    private var currentFPS: Double = 0.0
    private var rendererBackend: String = "unknown"
    private let settingsManager = SettingsManager.shared
    
    private let cellSize: Int32 = 30
    private let boardWidth = GameBoard.width
    private let boardHeight = GameBoard.height
    private let logicalWidth: Int32
    private let logicalHeight: Int32
    
    init(engine: TetrisEngine, logicalWidth: Int32, logicalHeight: Int32) {
        self.engine = engine
        self.logicalWidth = logicalWidth
        self.logicalHeight = logicalHeight
        
        // Load high score from settings
        let settings = settingsManager.loadSettings()
        highScore = settings.highScore
    }
    
    func updateUIState(usingController: Bool, gamepadExists: Bool, musicIsPlaying: Bool, currentFPS: Double, rendererBackend: String) {
        self.usingController = usingController
        self.gamepadExists = gamepadExists
        self.musicIsPlaying = musicIsPlaying
        self.currentFPS = currentFPS
        self.rendererBackend = rendererBackend
    }
    
    func updateHighScore(_ score: Int) {
        if score > highScore {
            highScore = score
            var settings = settingsManager.loadSettings()
            settings.highScore = highScore
            settingsManager.saveSettings(settings)
        }
    }
    
    func render(renderer: RendererProtocol, textRenderer: SwiftTextRenderer?) {
        guard let engine = engine else { return }
        
        // Clear screen with dark background
        renderer.setDrawColor(r: 20, g: 20, b: 30, a: 255)
        renderer.clear()
        
        // Draw board background
        let boardX: Int32 = 20
        let boardY: Int32 = 20
        let boardPixelWidth = Int32(boardWidth) * cellSize
        let boardPixelHeight = Int32(boardHeight) * cellSize
        
        // Board border
        renderer.setDrawColor(r: 100, g: 100, b: 120, a: 255)
        let borderRect = Rect(x: Float(boardX - 2), y: Float(boardY - 2), width: Float(boardPixelWidth + 4), height: Float(boardPixelHeight + 4))
        renderer.fillRect(borderRect)
        
        // Board background
        renderer.setDrawColor(r: 30, g: 30, b: 40, a: 255)
        let boardRect = Rect(x: Float(boardX), y: Float(boardY), width: Float(boardPixelWidth), height: Float(boardPixelHeight))
        renderer.fillRect(boardRect)
        
        // Draw placed blocks
        let cells = engine.board.getAllCells()
        let linesToClear = engine.linesToClear
        var flashProgress: Double = 0.0
        var fadeProgress: Double = 0.0
        
        if let startTime = engine.lineClearStartTime, !linesToClear.isEmpty {
            let elapsed = Date().timeIntervalSince(startTime)
            let flashDuration: TimeInterval = 0.35
            let fadeDuration: TimeInterval = 0.25
            if elapsed <= flashDuration {
                flashProgress = min(elapsed / flashDuration, 1.0)
            } else {
                flashProgress = 1.0
                let fadeStart = flashDuration
                let fadeElapsed = elapsed - fadeStart
                fadeProgress = min(fadeElapsed / fadeDuration, 1.0)
            }
        }
        
        for y in 0..<boardHeight {
            let isClearing = linesToClear.contains(y)
            for x in 0..<boardWidth {
                if let type = cells[y][x] {
                    let pixelX = boardX + Int32(x) * cellSize
                    let pixelY = boardY + Int32(y) * cellSize
                    
                    if isClearing {
                        let blockAlpha: UInt8
                        if fadeProgress > 0 {
                            blockAlpha = UInt8(max(0, min(255, (1.0 - fadeProgress) * 255)))
                        } else {
                            blockAlpha = 255
                        }
                        
                        if fadeProgress > 0 {
                            drawBlockWithAlpha(renderer: renderer, x: x, y: y, type: type, boardX: boardX, boardY: boardY, alpha: blockAlpha)
                        } else {
                            drawBlock(renderer: renderer, x: x, y: y, type: type, boardX: boardX, boardY: boardY)
                        }
                        
                        if flashProgress > 0 && fadeProgress == 0 {
                            let oscillation = sin(flashProgress * Double.pi * 10)
                            let intensityCurve = sin(flashProgress * Double.pi * 0.5)
                            let baseIntensity = 0.7 + (intensityCurve * 0.3)
                            let flashIntensity = (oscillation * 0.5 + 0.5) * baseIntensity
                            let flashAlpha = UInt8(max(0, min(255, flashIntensity * 255)))
                            let flashRect = Rect(x: Float(pixelX), y: Float(pixelY), width: Float(cellSize - 2), height: Float(cellSize - 2))
                            
                            var glowRect = Rect(
                                x: Float(pixelX) - 2,
                                y: Float(pixelY) - 2,
                                width: Float(cellSize + 2),
                                height: Float(cellSize + 2)
                            )
                            renderer.setDrawColor(r: 255, g: 255, b: 200, a: UInt8(flashAlpha / 3))
                            renderer.fillRect(glowRect)
                            
                            glowRect = Rect(
                                x: Float(pixelX) - 1,
                                y: Float(pixelY) - 1,
                                width: Float(cellSize),
                                height: Float(cellSize)
                            )
                            renderer.setDrawColor(r: 255, g: 255, b: 150, a: UInt8(flashAlpha / 2))
                            renderer.fillRect(glowRect)
                            
                            renderer.setDrawColor(r: 255, g: 255, b: 200, a: flashAlpha)
                            renderer.fillRect(flashRect)
                        }
                    } else {
                        drawBlock(renderer: renderer, x: x, y: y, type: type, boardX: boardX, boardY: boardY)
                    }
                }
            }
        }
        
        // Draw ghost piece
        if let ghostPiece = engine.getGhostPiece(), let currentPiece = engine.currentPiece {
            if ghostPiece.position.y != currentPiece.position.y {
                let ghostBlocks = ghostPiece.getAbsoluteBlocks()
                for block in ghostBlocks {
                    drawGhostBlock(renderer: renderer, x: block.x, y: block.y, type: ghostPiece.type, boardX: boardX, boardY: boardY)
                }
            }
        }
        
        // Draw current piece
        if let piece = engine.currentPiece {
            let blocks = piece.getAbsoluteBlocks()
            for block in blocks {
                drawBlock(renderer: renderer, x: block.x, y: block.y, type: piece.type, boardX: boardX, boardY: boardY)
            }
        }
        
        // Draw side panel
        let panelX = boardX + boardPixelWidth + 20
        let panelY = boardY
        
        // Update high score if current score is higher
        if engine.score > highScore {
            highScore = engine.score
            var settings = settingsManager.loadSettings()
            settings.highScore = highScore
            settingsManager.saveSettings(settings)
        }
        
        // Score and info
        drawText(textRenderer: textRenderer, x: panelX, y: panelY, text: "Score: \(engine.score)", r: 255, g: 255, b: 255)
        drawText(textRenderer: textRenderer, x: panelX, y: panelY + 30, text: "High: \(highScore)", r: 255, g: 255, b: 255)
        drawText(textRenderer: textRenderer, x: panelX, y: panelY + 60, text: "Lines: \(engine.linesCleared)", r: 255, g: 255, b: 255)
        drawText(textRenderer: textRenderer, x: panelX, y: panelY + 90, text: "Level: \(engine.level)", r: 255, g: 255, b: 255)
        
        // FPS counter
        let fpsText = String(format: "FPS: %.1f", currentFPS)
        let fpsColor: (r: UInt8, g: UInt8, b: UInt8) = currentFPS >= 170.0 ? (r: 100, g: 255, b: 100) : (r: 255, g: 200, b: 100)
        drawText(textRenderer: textRenderer, x: panelX, y: panelY + 120, text: fpsText, r: fpsColor.r, g: fpsColor.g, b: fpsColor.b)

        // Renderer backend indicator
        let backendDisplay = formatRendererBackend(rendererBackend)
        let backendColor: (r: UInt8, g: UInt8, b: UInt8) = backendDisplay.lowercased().contains("directx") ? (r: 255, g: 100, b: 100) : (r: 160, g: 200, b: 255)
        drawText(textRenderer: textRenderer, x: panelX, y: panelY + 140, text: "Renderer: \(backendDisplay)", r: backendColor.r, g: backendColor.g, b: backendColor.b)
        
        // Next piece
        drawText(textRenderer: textRenderer, x: panelX, y: panelY + 160, text: "Next:", r: 255, g: 255, b: 255)
        
        let nextBlocks = engine.nextPiece.getBlocks()
        let minX = nextBlocks.map { $0.x }.min() ?? 0
        let minY = nextBlocks.map { $0.y }.min() ?? 0
        let nextStartX = panelX
        let nextStartY = panelY + 190
        
        for block in nextBlocks {
            let x = block.x - minX
            let y = block.y - minY
            let blockX = nextStartX + Int32(x) * cellSize
            let blockY = nextStartY + Int32(y) * cellSize
            let rect = Rect(x: Float(blockX), y: Float(blockY), width: Float(cellSize - 2), height: Float(cellSize - 2))
            let color = getColor(engine.nextPiece.type.color)
            renderer.setDrawColor(r: color.r, g: color.g, b: color.b, a: 255)
            renderer.fillRect(rect)
            
            renderer.setDrawColor(r: 255, g: 255, b: 255, a: 100)
            renderer.drawRect(rect)
        }
        
        // Next next piece (smaller)
        let smallCellSize = Int32(Double(cellSize) * 0.6)
        let nextNextBlocks = engine.nextNextPiece.getBlocks()
        let nextNextMinX = nextNextBlocks.map { $0.x }.min() ?? 0
        let nextNextMinY = nextNextBlocks.map { $0.y }.min() ?? 0
        let nextNextStartX = panelX
        let nextNextStartY = panelY + 280
        
        drawText(textRenderer: textRenderer, x: panelX, y: panelY + 250, text: "After:", r: 200, g: 200, b: 200)
        
        for block in nextNextBlocks {
            let x = block.x - nextNextMinX
            let y = block.y - nextNextMinY
            let blockX = nextNextStartX + Int32(x) * smallCellSize
            let blockY = nextNextStartY + Int32(y) * smallCellSize
            let rect = Rect(x: Float(blockX), y: Float(blockY), width: Float(smallCellSize - 1), height: Float(smallCellSize - 1))
            let color = getColor(engine.nextNextPiece.type.color)
            renderer.setDrawColor(r: color.r, g: color.g, b: color.b, a: 255)
            renderer.fillRect(rect)
            
            renderer.setDrawColor(r: 255, g: 255, b: 255, a: 80)
            renderer.drawRect(rect)
        }
        
        // Game state
        if engine.gameState == .paused {
            drawText(textRenderer: textRenderer, x: panelX, y: panelY + 300, text: "PAUSED", r: 255, g: 255, b: 0)
            if usingController && gamepadExists {
                drawText(textRenderer: textRenderer, x: panelX, y: panelY + 330, text: "Press Options", r: 200, g: 200, b: 200)
            } else {
                drawText(textRenderer: textRenderer, x: panelX, y: panelY + 330, text: "Press ESC", r: 200, g: 200, b: 200)
            }
        }
        
        if engine.gameState == .gameOver {
            let boxWidth: Float = 200
            let boxHeight: Float = 80
            let boxX = Float(boardX + boardPixelWidth / 2) - boxWidth / 2
            let boxY = Float(boardY + boardPixelHeight / 2) - boxHeight / 2 - 10
            
            let borderRect = Rect(x: boxX - 4, y: boxY - 4, width: boxWidth + 8, height: boxHeight + 8)
            renderer.setDrawColor(r: 0, g: 0, b: 0, a: 200)
            renderer.fillRect(borderRect)
            
            let boxRect = Rect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)
            renderer.setDrawColor(r: 30, g: 30, b: 40, a: 240)
            renderer.fillRect(boxRect)
            
            drawText(textRenderer: textRenderer, x: Int32(boxX + boxWidth / 2 - 80), y: Int32(boxY + 15), text: "GAME OVER", r: 255, g: 0, b: 0)
            if usingController && gamepadExists {
                drawText(textRenderer: textRenderer, x: Int32(boxX + boxWidth / 2 - 80), y: Int32(boxY + 50), text: "Press Share", r: 200, g: 200, b: 200)
            } else {
                drawText(textRenderer: textRenderer, x: Int32(boxX + boxWidth / 2 - 60), y: Int32(boxY + 50), text: "Press R", r: 200, g: 200, b: 200)
            }
        }
        
        // Controls hint
        let maxControlsHeight: Int32 = 140
        let controlsStartY = logicalHeight - maxControlsHeight - 10
        drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY, text: "Controls:", r: 150, g: 150, b: 150)
        
        let musicStatusSuffix = musicIsPlaying ? " (ON)" : " (OFF)"
        let musicStatusColor: (r: UInt8, g: UInt8, b: UInt8) = musicIsPlaying ? (r: 100, g: 255, b: 100) : (r: 255, g: 100, b: 100)
        
        if usingController && gamepadExists {
            drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY + 20, text: "D-Pad: Move", r: 130, g: 130, b: 130)
            drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY + 40, text: "D-Pad Dn: Drop", r: 130, g: 130, b: 130)
            drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY + 60, text: "Up/X: Rotate", r: 130, g: 130, b: 130)
            drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY + 80, text: "Opt: Pause", r: 130, g: 130, b: 130)
            drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY + 100, text: "Share: Restart", r: 130, g: 130, b: 130)
            drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY + 120, text: "M: Music", r: 130, g: 130, b: 130)
            drawText(textRenderer: textRenderer, x: panelX + 90, y: controlsStartY + 120, text: musicStatusSuffix, r: musicStatusColor.r, g: musicStatusColor.g, b: musicStatusColor.b)
        } else {
            drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY + 20, text: "WASD/Arrows", r: 130, g: 130, b: 130)
            drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY + 40, text: "Space: Drop", r: 130, g: 130, b: 130)
            drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY + 60, text: "ESC: Pause", r: 130, g: 130, b: 130)
            drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY + 80, text: "F11: Fullscreen", r: 130, g: 130, b: 130)
            drawText(textRenderer: textRenderer, x: panelX, y: controlsStartY + 100, text: "M: Music", r: 130, g: 130, b: 130)
            drawText(textRenderer: textRenderer, x: panelX + 90, y: controlsStartY + 100, text: musicStatusSuffix, r: musicStatusColor.r, g: musicStatusColor.g, b: musicStatusColor.b)
        }
    }
    
    private func drawBlock(renderer: RendererProtocol, x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32) {
        drawBlockWithAlpha(renderer: renderer, x: x, y: y, type: type, boardX: boardX, boardY: boardY, alpha: 255)
    }
    
    private func drawBlockWithAlpha(renderer: RendererProtocol, x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32, alpha: UInt8) {
        let pixelX = boardX + Int32(x) * cellSize
        let pixelY = boardY + Int32(y) * cellSize
        let rect = Rect(x: Float(pixelX), y: Float(pixelY), width: Float(cellSize - 2), height: Float(cellSize - 2))
        
        let color = getColor(type.color)
        renderer.setDrawColor(r: color.r, g: color.g, b: color.b, a: alpha)
        renderer.fillRect(rect)
        
        renderer.setDrawColor(r: 255, g: 255, b: 255, a: UInt8((UInt16(alpha) * 100) / 255))
        renderer.drawRect(rect)
    }
    
    private func drawGhostBlock(renderer: RendererProtocol, x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32) {
        let pixelX = boardX + Int32(x) * cellSize
        let pixelY = boardY + Int32(y) * cellSize
        let rect = Rect(x: Float(pixelX), y: Float(pixelY), width: Float(cellSize - 2), height: Float(cellSize - 2))
        
        let color = getColor(type.color)
        renderer.setDrawColor(r: color.r, g: color.g, b: color.b, a: 80)
        renderer.drawRect(rect)
    }
    
    private func getColor(_ colorName: String) -> (r: UInt8, g: UInt8, b: UInt8) {
        switch colorName.lowercased() {
        case "cyan": return (0, 255, 255)
        case "yellow": return (255, 255, 0)
        case "purple": return (200, 0, 255)
        case "green": return (0, 255, 0)
        case "red": return (255, 0, 0)
        case "blue": return (0, 100, 255)
        case "orange": return (255, 165, 0)
        default: return (128, 128, 128)
        }
    }

    private func formatRendererBackend(_ raw: String) -> String {
        let v = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if v.isEmpty || v == "unknown" { return "Unknown" }
        if v.contains("vulkan") { return "Vulkan" }
        if v.contains("opengl") { return "OpenGL" }
        if v.contains("metal") { return "Metal" }
        if v.contains("software") { return "Software" }
        if v.contains("direct3d12") { return "DirectX 12" }
        if v.contains("direct3d11") { return "DirectX 11" }
        if v.contains("direct3d") { return "DirectX" }
        return raw
    }
    
    private func drawText(textRenderer: SwiftTextRenderer?, x: Int32, y: Int32, text: String, r: UInt8, g: UInt8, b: UInt8) {
        guard let textRenderer = textRenderer else { return }
        textRenderer.drawText(text, at: x, y: y, color: (r: r, g: g, b: b))
    }
}
