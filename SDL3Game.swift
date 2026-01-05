import Foundation
#if os(Linux)
import Glibc
#elseif os(Windows)
import WinSDK
#else
import Darwin
#endif
import CSDL3

#if os(Windows)
// strlen is in string.h which should be available via WinSDK, but let's make sure
#endif

class SDL3Game {
    private var window: OpaquePointer?
    private var renderer: OpaquePointer?
    private var font: OpaquePointer?
    private let engine: TetrisEngine
    private var running = true
    
    private var gamepad: OpaquePointer? = nil
    private var usingController = false
    private var isFullscreen = false
    private var dPadDownHeld = false
    private var dPadDownRepeatTimer: Date = Date()
    private let dPadDownRepeatInterval: TimeInterval = 0.05 // Repeat interval for soft drop
    private var lastDropTime: Date = Date() // Track automatic drop timing, reset when piece locks
    private var music: TetrisMusic?
    private var musicEnabled = true
    
    private let cellSize: Int32 = 30
    private let boardWidth = GameBoard.width
    private let boardHeight = GameBoard.height
    private let windowWidth: Int32
    private let windowHeight: Int32
    
    init() {
        engine = TetrisEngine()
        
        // No need to set video driver - SDL3 will auto-detect on Windows
        
        // Calculate window size: board + side panel for next piece and score
        let boardPixelWidth = Int32(boardWidth) * cellSize
        let boardPixelHeight = Int32(boardHeight) * cellSize
        let sidePanelWidth: Int32 = 200
        windowWidth = boardPixelWidth + sidePanelWidth + 40 // 40 for padding (20 on each side)
        windowHeight = boardPixelHeight + 40 // 40 for padding (20 on top and bottom)
        
        // SDL3: SDL_Init returns Bool (true = success, false = failure)
        if !SDL_Init(UInt32(SDL_INIT_VIDEO) | UInt32(SDL_INIT_GAMEPAD) | UInt32(SDL_INIT_AUDIO)) {
            if let error = SDL_GetError() {
                let errorString = String(cString: error)
                print("SDL_Init failed: \(errorString)")
            } else {
                print("SDL_Init failed (unknown error)")
            }
            return
        }
        
        // Initialize music (after SDL audio subsystem is initialized)
        music = TetrisMusic()
        
        // Initialize game controller subsystem and detect controllers
        detectGamepad()
        
        // Initialize TTF for text rendering
        if !TTF_Init() {
            if let error = SDL_GetError() {
                let errorString = String(cString: error)
                print("Warning: TTF_Init failed: \(errorString), text rendering disabled")
            } else {
                print("Warning: TTF_Init failed, text rendering disabled")
            }
        }
        
        let title = "Tetrix"
        // SDL3: SDL_CreateWindow(title, width, height, flags)
        title.withCString { cString in
            // SDL3: Use SDL_WINDOW_HIDDEN flag (0x8) to create window hidden initially
            window = SDL_CreateWindow(cString, windowWidth, windowHeight, 0x8)  // SDL_WINDOW_HIDDEN
        }
        if window == nil {
            print("Failed to create window")
        }
        
        // SDL3: Renderer creation API changed - takes (window, name) where name can be nil for default
        renderer = SDL_CreateRenderer(window, nil)  // nil = use default renderer
        if renderer == nil {
            print("Failed to create renderer")
        }
        
        // Try to load a default font, fallback to built-in if not available
        // On Windows, try common font paths
        #if os(Windows)
        // Try Windows font paths
        font = TTF_OpenFont("C:\\Windows\\Fonts\\arial.ttf", 20)
        if font == nil {
            font = TTF_OpenFont("C:\\Windows\\Fonts\\calibri.ttf", 20)
        }
        if font == nil {
            font = TTF_OpenFont("C:\\Windows\\Fonts\\verdana.ttf", 20)
        }
        #else
        // Try Linux font paths
        font = TTF_OpenFont("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf", 20)
        if font == nil {
            font = TTF_OpenFont("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)
        }
        if font == nil {
            font = TTF_OpenFont("/usr/share/fonts/TTF/liberation/LiberationSans-Bold.ttf", 20)
        }
        #endif
        // If no font found, we'll render without text (just colors)
        if font == nil {
            print("Warning: Could not load font, text rendering disabled")
        }
        
        // Render initial frame while window is hidden
        render()
        
        // Now show the window after first frame is rendered
        SDL_ShowWindow(window)
        
        // Start playing the classic Tetris theme
        music?.start()
    }
    
    deinit {
        if gamepad != nil {
            SDL_CloseGamepad(gamepad)
        }
        if font != nil {
            TTF_CloseFont(font)
        }
        if renderer != nil {
            SDL_DestroyRenderer(renderer)
        }
        if window != nil {
            SDL_DestroyWindow(window)
        }
        TTF_Quit()
        SDL_Quit()
    }
    
    func run() {
        lastDropTime = Date() // Initialize drop timer
        var lastFrameTime = Date()
        let targetFPS = 60.0
        let frameTime = 1.0 / targetFPS
        
        while running {
            let now = Date()
            
            // Handle events
            handleEvents()
            
            // Handle held D-pad down for soft drop
            handleDPadDownRepeat()
            
        // Update music (only if enabled)
        if musicEnabled {
            music?.update()
        }
            
            // Update line clearing animation
            engine.updateLineClearing()
            
            // Update game (drop piece based on level)
            let dropInterval = getDropInterval()
            if now.timeIntervalSince(lastDropTime) >= dropInterval {
                engine.update()
                lastDropTime = now
            }
            
            // Render at target FPS
            if now.timeIntervalSince(lastFrameTime) >= frameTime {
                render()
                lastFrameTime = now
            } else {
                // Sleep a bit to not waste CPU
                #if os(Windows)
                Sleep(1) // 1ms on Windows
                #else
                usleep(1000) // 1ms
                #endif
            }
        }
    }
    
    private func getDropInterval() -> TimeInterval {
        // Speed increases with level
        let baseInterval: TimeInterval = 1.0
        let minInterval: TimeInterval = 0.1
        let levelFactor = Double(min(engine.level, 10))
        return max(minInterval, baseInterval - (levelFactor * 0.09))
    }
    
    private func handleEvents() {
        var event = SDL_Event()
        // SDL3: SDL_PollEvent returns Bool (true = event available, false = no events)
        while SDL_PollEvent(&event) {
            switch event.type {
            case UInt32(SDL_EVENT_QUIT.rawValue):
                running = false
            case UInt32(SDL_EVENT_KEY_DOWN.rawValue):
                usingController = false
                handleKeyPress(&event.key)
            case UInt32(SDL_EVENT_GAMEPAD_ADDED.rawValue):
                detectGamepad()
            case UInt32(SDL_EVENT_GAMEPAD_REMOVED.rawValue):
                if gamepad != nil {
                    SDL_CloseGamepad(gamepad)
                    gamepad = nil
                    usingController = false
                }
            case UInt32(SDL_EVENT_GAMEPAD_BUTTON_DOWN.rawValue):
                usingController = true
                handleGamepadButtonDown(UInt32(event.gbutton.button))
            case UInt32(SDL_EVENT_GAMEPAD_BUTTON_UP.rawValue):
                handleGamepadButtonUp(UInt32(event.gbutton.button))
            default:
                break
            }
        }
    }
    
    private func detectGamepad() {
        // Close existing gamepad if any
        if gamepad != nil {
            SDL_CloseGamepad(gamepad)
            gamepad = nil
        }
        
        // Find first available gamepad
        // SDL3: API changed - check for correct function name
        var count: Int32 = 0
        let joysticks = SDL_GetJoysticks(&count)
        if joysticks != nil {
            for i in 0..<Int(count) {
                if SDL_IsGamepad(joysticks![Int(i)]) {
                    gamepad = SDL_OpenGamepad(joysticks![Int(i)])
                    if gamepad != nil {
                        let name = SDL_GetGamepadName(gamepad)
                        if name != nil {
                            let nameString = String(cString: name!)
                            print("Gamepad connected: \(nameString)")
                        }
                        break
                    }
                }
            }
        }
    }
    
    private func handleKeyPress(_ keyEvent: UnsafePointer<SDL_KeyboardEvent>) {
        // SDL3: Use scancode field (SDL_Scancode enum) instead of raw
        let scancode = keyEvent.pointee.scancode
        switch scancode {
        case SDL_SCANCODE_A, SDL_SCANCODE_LEFT:
            engine.moveLeft()
        case SDL_SCANCODE_D, SDL_SCANCODE_RIGHT:
            engine.moveRight()
        case SDL_SCANCODE_S, SDL_SCANCODE_DOWN:
            let couldMove = engine.moveDown()
            // If piece locked (couldn't move), reset the automatic drop timer
            if !couldMove {
                lastDropTime = Date()
            }
        case SDL_SCANCODE_W, SDL_SCANCODE_UP:
            engine.rotate()
        case SDL_SCANCODE_SPACE:
            engine.hardDrop()
        case SDL_SCANCODE_P:
            engine.pause()
        case SDL_SCANCODE_R:
            if engine.gameState == .gameOver {
                engine.reset()
            }
        case SDL_SCANCODE_F11:
            toggleFullscreen()
        case SDL_SCANCODE_ESCAPE:
            if isFullscreen {
                toggleFullscreen()
            }
        case SDL_SCANCODE_M:
            toggleMusic()
        default:
            break
        }
    }
    
    private func toggleMusic() {
        musicEnabled.toggle()
        if musicEnabled {
            music?.start()
        } else {
            music?.stop()
        }
    }
    
    private func toggleFullscreen() {
        guard let window = window, let renderer = renderer else { return }
        isFullscreen.toggle()
        // SDL3: Use SDL_SetWindowFullscreen to toggle fullscreen state
        _ = SDL_SetWindowFullscreen(window, isFullscreen)
        
        // Set logical presentation to scale content when fullscreen
        if isFullscreen {
            // Use letterbox mode to maintain aspect ratio on all platforms
            _ = SDL_SetRenderLogicalPresentation(renderer, windowWidth, windowHeight, SDL_LOGICAL_PRESENTATION_LETTERBOX)
        } else {
            // Disable logical presentation in windowed mode - use native size
            _ = SDL_SetRenderLogicalPresentation(renderer, windowWidth, windowHeight, SDL_LOGICAL_PRESENTATION_DISABLED)
        }
    }
    
    private func handleGamepadButtonDown(_ button: UInt32) {
        // SDL_GamepadButton enum values in SDL3
        // A=0, B=1, X=2, Y=3, BACK=4, START=6
        // DPAD_UP=11, DPAD_DOWN=12, DPAD_LEFT=13, DPAD_RIGHT=14
        switch button {
        case 11: // SDL_GAMEPAD_BUTTON_DPAD_UP
            engine.rotate()
        case 13: // SDL_GAMEPAD_BUTTON_DPAD_LEFT
            engine.moveLeft()
        case 14: // SDL_GAMEPAD_BUTTON_DPAD_RIGHT
            engine.moveRight()
        case 12: // SDL_GAMEPAD_BUTTON_DPAD_DOWN
            dPadDownHeld = true
            dPadDownRepeatTimer = Date()
            let couldMove = engine.moveDown() // Immediate action
            // If piece locked (couldn't move), reset the automatic drop timer
            if !couldMove {
                lastDropTime = Date()
            }
        case 0: // SDL_GAMEPAD_BUTTON_A (X button on DualSense)
            engine.rotate()
        case 6: // SDL_GAMEPAD_BUTTON_START (Options button on DualSense)
            engine.pause()
        case 1: // SDL_GAMEPAD_BUTTON_B (Circle button on DualSense) - restart on game over
            if engine.gameState == .gameOver {
                engine.reset()
            }
        default:
            break
        }
    }
    
    private func handleGamepadButtonUp(_ button: UInt32) {
        switch button {
        case 12: // SDL_GAMEPAD_BUTTON_DPAD_DOWN
            dPadDownHeld = false
        default:
            break
        }
    }
    
    private func handleDPadDownRepeat() {
        guard dPadDownHeld else { return }
        
        let now = Date()
        let timeSinceLastAction = now.timeIntervalSince(dPadDownRepeatTimer)
        
        if timeSinceLastAction >= dPadDownRepeatInterval {
            let couldMove = engine.moveDown()
            dPadDownRepeatTimer = Date()
            // If piece locked (couldn't move), reset the automatic drop timer
            // so the next piece doesn't inherit the soft drop momentum
            if !couldMove {
                lastDropTime = Date()
            }
        }
    }
    
    private func render() {
        // Clear screen with dark background
        SDL_SetRenderDrawColor(renderer, 20, 20, 30, 255)
        SDL_RenderClear(renderer)
        
        // Draw board background
        let boardX: Int32 = 20
        let boardY: Int32 = 20
        let boardPixelWidth = Int32(boardWidth) * cellSize
        let boardPixelHeight = Int32(boardHeight) * cellSize
        
        // Board border
        SDL_SetRenderDrawColor(renderer, 100, 100, 120, 255)
        var borderRect = SDL_FRect(x: Float(boardX - 2), y: Float(boardY - 2), w: Float(boardPixelWidth + 4), h: Float(boardPixelHeight + 4))
        SDL_RenderFillRect(renderer, &borderRect)
        
        // Board background
        SDL_SetRenderDrawColor(renderer, 30, 30, 40, 255)
        var boardRect = SDL_FRect(x: Float(boardX), y: Float(boardY), w: Float(boardPixelWidth), h: Float(boardPixelHeight))
        SDL_RenderFillRect(renderer, &boardRect)
        
        // Draw placed blocks
        let cells = engine.board.getAllCells()
        let linesToClear = engine.linesToClear
        let flashProgress: Double
        
        if let startTime = engine.lineClearStartTime, !linesToClear.isEmpty {
            let elapsed = Date().timeIntervalSince(startTime)
            flashProgress = min(elapsed / engine.lineClearFlashDuration, 1.0)
        } else {
            flashProgress = 0.0
        }
        
        // Calculate flash alpha (oscillates between 0 and 255)
        let flashAlpha: UInt8
        if flashProgress > 0 && flashProgress <= 1.0 {
            // Flash effect: oscillate with decreasing intensity
            let oscillation = sin(flashProgress * Double.pi * 8) // Fast flash (8 cycles)
            let intensity = 1.0 - flashProgress // Fade out
            flashAlpha = UInt8(max(0, min(255, (oscillation * 0.5 + 0.5) * intensity * 255)))
        } else {
            flashAlpha = 255
        }
        
        for y in 0..<boardHeight {
            let isFlashing = linesToClear.contains(y)
            for x in 0..<boardWidth {
                if let type = cells[y][x] {
                    if isFlashing && flashProgress > 0 {
                        // Draw flashing white overlay
                        let pixelX = boardX + Int32(x) * cellSize
                        let pixelY = boardY + Int32(y) * cellSize
                        var flashRect = SDL_FRect(x: Float(pixelX), y: Float(pixelY), w: Float(cellSize - 2), h: Float(cellSize - 2))
                        SDL_SetRenderDrawColor(renderer, 255, 255, 255, flashAlpha)
                        SDL_RenderFillRect(renderer, &flashRect)
                    } else {
                        // Normal block drawing
                        drawBlock(x: x, y: y, type: type, boardX: boardX, boardY: boardY)
                    }
                }
            }
        }
        
        // Draw ghost piece (where current piece would land)
        if let ghostPiece = engine.getGhostPiece(), let currentPiece = engine.currentPiece {
            // Only draw ghost if it's different from current position
            if ghostPiece.position.y != currentPiece.position.y {
                let ghostBlocks = ghostPiece.getAbsoluteBlocks()
                for block in ghostBlocks {
                    drawGhostBlock(x: block.x, y: block.y, type: ghostPiece.type, boardX: boardX, boardY: boardY)
                }
            }
        }
        
        // Draw current piece
        if let piece = engine.currentPiece {
            let blocks = piece.getAbsoluteBlocks()
            for block in blocks {
                drawBlock(x: block.x, y: block.y, type: piece.type, boardX: boardX, boardY: boardY)
            }
        }
        
        // Draw side panel
        let panelX = boardX + boardPixelWidth + 20
        let panelY = boardY
        
        // Score and info
        drawText(x: panelX, y: panelY, text: "Score: \(engine.score)", r: 255, g: 255, b: 255)
        drawText(x: panelX, y: panelY + 30, text: "Lines: \(engine.linesCleared)", r: 255, g: 255, b: 255)
        drawText(x: panelX, y: panelY + 60, text: "Level: \(engine.level)", r: 255, g: 255, b: 255)
        
        // Next piece
        drawText(x: panelX, y: panelY + 120, text: "Next:", r: 255, g: 255, b: 255)
        
        let nextBlocks = engine.nextPiece.getBlocks()
        let minX = nextBlocks.map { $0.x }.min() ?? 0
        let minY = nextBlocks.map { $0.y }.min() ?? 0
        let nextStartX = panelX
        let nextStartY = panelY + 150
        
        for block in nextBlocks {
            let x = block.x - minX
            let y = block.y - minY
            let blockX = nextStartX + Int32(x) * cellSize
            let blockY = nextStartY + Int32(y) * cellSize
            var rect = SDL_FRect(x: Float(blockX), y: Float(blockY), w: Float(cellSize - 2), h: Float(cellSize - 2))
            let color = getColor(engine.nextPiece.type.color)
            SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, 255)
            SDL_RenderFillRect(renderer, &rect)
            
            // Border
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, 100)
            // SDL3: RenderDrawRect might have different name - using RenderRect for now
            SDL_RenderRect(renderer, &rect)
        }
        
        // Next next piece (smaller)
        let smallCellSize = Int32(Double(cellSize) * 0.6) // 60% of normal size
        let nextNextBlocks = engine.nextNextPiece.getBlocks()
        let nextNextMinX = nextNextBlocks.map { $0.x }.min() ?? 0
        let nextNextMinY = nextNextBlocks.map { $0.y }.min() ?? 0
        let nextNextStartX = panelX
        let nextNextStartY = panelY + 240 // Position below the next piece
        
        // Draw label for next next piece (smaller text would be better, but using same size)
        drawText(x: panelX, y: panelY + 210, text: "After:", r: 200, g: 200, b: 200)
        
        for block in nextNextBlocks {
            let x = block.x - nextNextMinX
            let y = block.y - nextNextMinY
            let blockX = nextNextStartX + Int32(x) * smallCellSize
            let blockY = nextNextStartY + Int32(y) * smallCellSize
            var rect = SDL_FRect(x: Float(blockX), y: Float(blockY), w: Float(smallCellSize - 1), h: Float(smallCellSize - 1))
            let color = getColor(engine.nextNextPiece.type.color)
            SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, 255)
            SDL_RenderFillRect(renderer, &rect)
            
            // Border (thinner for smaller piece)
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, 80)
            SDL_RenderRect(renderer, &rect)
        }
        
        // Game state
        if engine.gameState == .paused {
            drawText(x: panelX, y: panelY + 300, text: "PAUSED", r: 255, g: 255, b: 0)
            drawText(x: panelX, y: panelY + 330, text: "Press P", r: 200, g: 200, b: 200)
        }
        
        if engine.gameState == .gameOver {
            drawText(x: boardX + boardPixelWidth / 2 - 80, y: boardY + boardPixelHeight / 2 - 40, text: "GAME OVER", r: 255, g: 0, b: 0)
            drawText(x: boardX + boardPixelWidth / 2 - 60, y: boardY + boardPixelHeight / 2, text: "Press R", r: 200, g: 200, b: 200)
        }
        
        // Controls hint - switch between keyboard and controller
        // Position controls text in the side panel, aligned with board bottom
        let controlsStartY = boardY + boardPixelHeight - 110 // Position controls in side panel
        drawText(x: panelX, y: controlsStartY, text: "Controls:", r: 150, g: 150, b: 150)
        if usingController && gamepad != nil {
            // Controller controls (D-pad and buttons only, no joystick)
            drawText(x: panelX, y: controlsStartY + 20, text: "D-Pad: Move", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 40, text: "D-Pad Dn: Drop", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 60, text: "Up/X: Rotate", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 80, text: "Opt: Pause", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 100, text: "M: Music", r: 130, g: 130, b: 130)
        } else {
            // Keyboard controls
            drawText(x: panelX, y: controlsStartY + 20, text: "WASD/Arrows", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 40, text: "Space: Drop", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 60, text: "P: Pause", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 80, text: "F11: Fullscreen", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 100, text: "M: Music", r: 130, g: 130, b: 130)
        }
        
        SDL_RenderPresent(renderer)
    }
    
    private func drawBlock(x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32) {
        let pixelX = boardX + Int32(x) * cellSize
        let pixelY = boardY + Int32(y) * cellSize
        var rect = SDL_FRect(x: Float(pixelX), y: Float(pixelY), w: Float(cellSize - 2), h: Float(cellSize - 2))
        
        let color = getColor(type.color)
        SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, 255)
        SDL_RenderFillRect(renderer, &rect)
        
        // Highlight border
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 100)
        SDL_RenderRect(renderer, &rect)
    }
    
    private func drawGhostBlock(x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32) {
        let pixelX = boardX + Int32(x) * cellSize
        let pixelY = boardY + Int32(y) * cellSize
        var rect = SDL_FRect(x: Float(pixelX), y: Float(pixelY), w: Float(cellSize - 2), h: Float(cellSize - 2))
        
        // Draw ghost piece as outline only (no fill, just border)
        let color = getColor(type.color)
        // Use a semi-transparent border color
        SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, 80)
        SDL_RenderRect(renderer, &rect)
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
    
    private func drawText(x: Int32, y: Int32, text: String, r: UInt8, g: UInt8, b: UInt8) {
        guard font != nil else {
            return
        }
        
        let color = SDL_Color(r: r, g: g, b: b, a: 255)
        // SDL3: TTF_RenderText_Solid now requires length parameter
        text.withCString { cString in
            let length = strlen(cString)
            let surface = TTF_RenderText_Solid(font, cString, length, color)
            guard surface != nil else {
                return
            }
            
            let texture = SDL_CreateTextureFromSurface(renderer, surface)
            SDL_DestroySurface(surface)
            
            guard texture != nil else {
                return
            }
            
            var destRect = SDL_FRect()
            // SDL3: Use SDL_GetTextureSize instead of SDL_QueryTexture
            SDL_GetTextureSize(texture, &destRect.w, &destRect.h)
            destRect.x = Float(x)
            destRect.y = Float(y)
            
            SDL_RenderTexture(renderer, texture, nil, &destRect)
            SDL_DestroyTexture(texture)
        }
    }
}
