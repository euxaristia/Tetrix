import Foundation
import CSDL3

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
    private var dPadLeftHeld = false
    private var dPadLeftRepeatTimer: Date = Date()
    private var dPadRightHeld = false
    private var dPadRightRepeatTimer: Date = Date()
    private let dPadHorizontalRepeatInterval: TimeInterval = 0.1 // Repeat interval for left/right movement
    private var downKeyHeld = false
    private var downKeyRepeatTimer: Date = Date()
    private let downKeyRepeatInterval: TimeInterval = 0.03 // Faster repeat interval for keyboard soft drop
    private var lastDropTime: Date = Date() // Track automatic drop timing, reset when piece locks
    private var music: TetrisMusic?
    private var musicEnabled = true
    private var highScore: Int = 0
    private let settingsManager = SettingsManager.shared
    
    private let cellSize: Int32 = 30
    private let boardWidth = GameBoard.width
    private let boardHeight = GameBoard.height
    private let windowWidth: Int32
    private let windowHeight: Int32
    
    init() {
        engine = TetrisEngine()
        
        // Load settings
        let settings = settingsManager.loadSettings()
        highScore = settings.highScore
        musicEnabled = settings.musicEnabled
        isFullscreen = settings.isFullscreen
        
        // No need to set video driver - SDL3 will auto-detect on Windows
        
        // Calculate window size: board + side panel for next piece and score
        let boardPixelWidth = Int32(boardWidth) * cellSize
        let boardPixelHeight = Int32(boardHeight) * cellSize
        let sidePanelWidth: Int32 = 200
        windowWidth = boardPixelWidth + sidePanelWidth + 40 // 40 for padding (20 on each side)
        windowHeight = boardPixelHeight + 40 // 40 for padding (20 on top and bottom)
        
        // Initialize SDL subsystems
        let initFlags = UInt32(SDL_INIT_VIDEO) | UInt32(SDL_INIT_GAMEPAD) | UInt32(SDL_INIT_AUDIO)
        let sdlResult = SDLHelper.initialize(initFlags)
        if !sdlResult.isSuccess {
            print("SDL_Init failed: \(sdlResult.errorMessage ?? "Unknown error")")
            return
        }
        
        // Initialize music (after SDL audio subsystem is initialized)
        music = TetrisMusic()
        
        // Initialize game controller subsystem and detect controllers
        detectGamepad()
        
        // Initialize TTF for text rendering
        let ttfResult = SDLHelper.initializeTTF()
        if !ttfResult.isSuccess {
            print("Warning: TTF_Init failed: \(ttfResult.errorMessage ?? "Unknown error"), text rendering disabled")
        }
        
        // Create window
        let title = "Tetrix"
        window = SDLHelper.createWindow(title: title, width: windowWidth, height: windowHeight, flags: 0x28)  // SDL_WINDOW_HIDDEN | SDL_WINDOW_RESIZABLE (UInt64)
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
        font = TTFHelper.openFont(path: "C:\\Windows\\Fonts\\arial.ttf", pointSize: 20.0)
        if font == nil {
            font = TTFHelper.openFont(path: "C:\\Windows\\Fonts\\calibri.ttf", pointSize: 20.0)
        }
        if font == nil {
            font = TTFHelper.openFont(path: "C:\\Windows\\Fonts\\verdana.ttf", pointSize: 20.0)
        }
        #else
        // Try Linux font paths
        font = TTFHelper.openFont(path: "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf", pointSize: 20.0)
        if font == nil {
            font = TTFHelper.openFont(path: "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", pointSize: 20.0)
        }
        if font == nil {
            font = TTFHelper.openFont(path: "/usr/share/fonts/TTF/liberation/LiberationSans-Bold.ttf", pointSize: 20.0)
        }
        #endif
        // If no font found, we'll render without text (just colors)
        if font == nil {
            print("Warning: Could not load font, text rendering disabled")
        }
        
        // Render initial frame while window is hidden
        render()
        
        // Always use letterbox mode for sharp scaling in both windowed and fullscreen modes
        _ = SDLWindowHelper.setLogicalPresentation(renderer: renderer, width: windowWidth, height: windowHeight, mode: SDL_LOGICAL_PRESENTATION_LETTERBOX)
        
        // Apply fullscreen state if it was saved
        if isFullscreen {
            _ = SDLWindowHelper.setFullscreen(window: window, fullscreen: true)
        }
        
        // Now show the window after first frame is rendered
        SDLWindowHelper.show(window: window)
        
        // Always maximize the window on startup
        _ = SDLWindowHelper.maximize(window: window)
        
        // Start playing the classic Tetris theme if music is enabled
        if musicEnabled {
            music?.start()
        }
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
            
            // Handle held D-pad left/right for continuous movement
            handleDPadHorizontalRepeat()
            
            // Handle held down key for soft drop
            handleDownKeyRepeat()
            
            // Show cursor when paused, even if controller is in use
            if engine.gameState == .paused {
                _ = SDL_ShowCursor()
            }
            
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
                PlatformHelper.sleep(milliseconds: 1)
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
        // Poll for events using Swift helper
        while SDLEventHelper.pollEvent(&event) {
            switch event.type {
            case UInt32(SDL_EVENT_QUIT.rawValue):
                running = false
            case UInt32(SDL_EVENT_KEY_DOWN.rawValue):
                if !usingController {
                    // Only show cursor when keyboard is first used
                    SDLCursorHelper.show()
                }
                usingController = false
                handleKeyPress(&event.key)
            case UInt32(SDL_EVENT_KEY_UP.rawValue):
                handleKeyRelease(&event.key)
            case UInt32(SDL_EVENT_GAMEPAD_ADDED.rawValue):
                detectGamepad()
            case UInt32(SDL_EVENT_GAMEPAD_REMOVED.rawValue):
                if gamepad != nil {
                    SDL_CloseGamepad(gamepad)
                    gamepad = nil
                    usingController = false
                    // Show cursor when gamepad is removed
                    SDLCursorHelper.show()
                }
            case UInt32(SDL_EVENT_GAMEPAD_BUTTON_DOWN.rawValue):
                if !usingController {
                    // Hide cursor when controller is first used (unless paused)
                    if engine.gameState != .paused {
                        SDLCursorHelper.hide()
                    }
                }
                usingController = true
                handleGamepadButtonDown(UInt32(event.gbutton.button))
            case UInt32(SDL_EVENT_GAMEPAD_BUTTON_UP.rawValue):
                handleGamepadButtonUp(UInt32(event.gbutton.button))
            case UInt32(SDL_EVENT_WINDOW_FOCUS_LOST.rawValue):
                // Auto-pause when window loses focus
                if engine.gameState == .playing {
                    engine.pause()
                }
                // Stop music when window loses focus
                music?.stop()
            case UInt32(SDL_EVENT_WINDOW_FOCUS_GAINED.rawValue):
                // Window regained focus - game stays paused, user can press ESC to resume
                // Music will resume when user manually unpauses if music is enabled
                break
            default:
                break
            }
        }
    }
    
    private func detectGamepad() {
        // If we already have a gamepad, don't detect again (prevents duplicate messages)
        if gamepad != nil {
            return
        }
        
        // Find first available gamepad
        // Find and open first available gamepad
        let gamepadIDs = SDLGamepadHelper.getGamepadJoystickIDs()
        for id in gamepadIDs {
            gamepad = SDL_OpenGamepad(id)
            if gamepad != nil {
                if let name = SDLGamepadHelper.getName(gamepad: gamepad) {
                    print("Gamepad connected: \(name)")
                }
                break
            }
        }
    }
    
    private func handleKeyRelease(_ keyEvent: UnsafePointer<SDL_KeyboardEvent>) {
        let scancode = SDLEventHelper.getScancode(from: keyEvent)
        
        switch scancode {
        case SDL_SCANCODE_S, SDL_SCANCODE_DOWN:
            downKeyHeld = false
        default:
            break
        }
    }
    
    private func handleKeyPress(_ keyEvent: UnsafePointer<SDL_KeyboardEvent>) {
        // SDL3: Use scancode field (SDL_Scancode enum) instead of raw
        let scancode = keyEvent.pointee.scancode
        let isRepeat = keyEvent.pointee.repeat
        
        switch scancode {
        case SDL_SCANCODE_A, SDL_SCANCODE_LEFT:
            engine.moveLeft()
        case SDL_SCANCODE_D, SDL_SCANCODE_RIGHT:
            engine.moveRight()
        case SDL_SCANCODE_S, SDL_SCANCODE_DOWN:
            // Start holding down key for continuous movement
            if !downKeyHeld {
                downKeyHeld = true
                downKeyRepeatTimer = Date()
                // Immediate movement on first press
                let couldMove = engine.moveDown()
                if !couldMove {
                    // Reset repeat timer but keep key held so it continues working for next piece
                    downKeyRepeatTimer = Date()
                    let dropInterval = getDropInterval()
                    lastDropTime = Date().addingTimeInterval(-dropInterval * 0.5) // Wait 50% of normal interval
                }
            }
        case SDL_SCANCODE_W, SDL_SCANCODE_UP:
            engine.rotate()
        case SDL_SCANCODE_SPACE:
            engine.hardDrop()
        case SDL_SCANCODE_ESCAPE:
            // Ignore key repeat for pause toggle
            if !isRepeat {
                engine.pause()
                // Resume music if game was unpaused and music is enabled
                if engine.gameState == .playing && musicEnabled {
                    music?.start()
                } else if engine.gameState == .paused {
                    // Pause music when game is paused
                    music?.stop()
                }
            }
        case SDL_SCANCODE_R:
            if engine.gameState == .gameOver {
                engine.reset()
            }
        case SDL_SCANCODE_F11:
            // Ignore key repeat for fullscreen toggle
            if !isRepeat {
                toggleFullscreen()
            }
        case SDL_SCANCODE_ESCAPE:
            // Ignore key repeat for fullscreen toggle
            if !isRepeat && isFullscreen {
                toggleFullscreen()
            }
        case SDL_SCANCODE_M:
            // Ignore key repeat for music toggle - only toggle on initial press
            if !isRepeat {
                toggleMusic()
            }
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
        saveSettings()
    }
    
    private func saveSettings() {
        var settings = GameSettings()
        settings.highScore = highScore
        settings.musicEnabled = musicEnabled
        settings.isFullscreen = isFullscreen
        settingsManager.saveSettings(settings)
    }
    
    private func toggleFullscreen() {
        guard let window = window, let renderer = renderer else { return }
        isFullscreen.toggle()
        // Toggle fullscreen using Swift helper
        _ = SDLWindowHelper.setFullscreen(window: window, fullscreen: isFullscreen)
        
        // Always use letterbox mode for sharp scaling in both windowed and fullscreen modes
        // This ensures consistent scaling whether windowed, resized, snapped, or maximized
        _ = SDLWindowHelper.setLogicalPresentation(renderer: renderer, width: windowWidth, height: windowHeight, mode: SDL_LOGICAL_PRESENTATION_LETTERBOX)
        saveSettings()
    }
    
    private func handleGamepadButtonDown(_ button: UInt32) {
        // SDL_GamepadButton enum values in SDL3
        // A=0, B=1, X=2, Y=3, BACK=4, START=6
        // DPAD_UP=11, DPAD_DOWN=12, DPAD_LEFT=13, DPAD_RIGHT=14
        switch button {
        case 11: // SDL_GAMEPAD_BUTTON_DPAD_UP
            engine.rotate()
        case 13: // SDL_GAMEPAD_BUTTON_DPAD_LEFT
            dPadLeftHeld = true
            dPadLeftRepeatTimer = Date()
            engine.moveLeft() // Immediate action
        case 14: // SDL_GAMEPAD_BUTTON_DPAD_RIGHT
            dPadRightHeld = true
            dPadRightRepeatTimer = Date()
            engine.moveRight() // Immediate action
        case 12: // SDL_GAMEPAD_BUTTON_DPAD_DOWN
            dPadDownHeld = true
            dPadDownRepeatTimer = Date()
            let couldMove = engine.moveDown() // Immediate action
            // If piece locked (couldn't move), reset repeat timer to prevent momentum carryover
            // Keep key held but reset timer so next piece waits a bit before starting to drop
            if !couldMove {
                dPadDownRepeatTimer = Date() // Reset repeat timer, but keep key held
                let dropInterval = getDropInterval()
                lastDropTime = Date().addingTimeInterval(-dropInterval * 0.5) // Wait 50% of normal interval
            }
        case 0: // SDL_GAMEPAD_BUTTON_A (X button on DualSense)
            engine.rotate()
        case 6: // SDL_GAMEPAD_BUTTON_START (Options button on DualSense)
            engine.pause()
            // Resume music if game was unpaused and music is enabled
            if engine.gameState == .playing && musicEnabled {
                music?.start()
            } else if engine.gameState == .paused {
                // Pause music when game is paused
                music?.stop()
            }
        case 4: // SDL_GAMEPAD_BUTTON_BACK (Share button on DualSense) - restart on game over
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
        case 13: // SDL_GAMEPAD_BUTTON_DPAD_LEFT
            dPadLeftHeld = false
        case 14: // SDL_GAMEPAD_BUTTON_DPAD_RIGHT
            dPadRightHeld = false
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
            // If piece locked (couldn't move), reset repeat timer to prevent momentum carryover
            // Keep key held but reset timer so next piece waits a bit before starting to drop
            if !couldMove {
                dPadDownRepeatTimer = Date() // Reset repeat timer, but keep key held
                let dropInterval = getDropInterval()
                lastDropTime = Date().addingTimeInterval(-dropInterval * 0.5) // Wait 50% of normal interval
            }
        }
    }
    
    private func handleDPadHorizontalRepeat() {
        let now = Date()
        
        // Handle D-pad left repeat
        if dPadLeftHeld {
            let timeSinceLastAction = now.timeIntervalSince(dPadLeftRepeatTimer)
            if timeSinceLastAction >= dPadHorizontalRepeatInterval {
                engine.moveLeft()
                dPadLeftRepeatTimer = Date()
            }
        }
        
        // Handle D-pad right repeat
        if dPadRightHeld {
            let timeSinceLastAction = now.timeIntervalSince(dPadRightRepeatTimer)
            if timeSinceLastAction >= dPadHorizontalRepeatInterval {
                engine.moveRight()
                dPadRightRepeatTimer = Date()
            }
        }
    }
    
    private func handleDownKeyRepeat() {
        guard downKeyHeld else { return }
        
        let now = Date()
        let timeSinceLastAction = now.timeIntervalSince(downKeyRepeatTimer)
        
        if timeSinceLastAction >= downKeyRepeatInterval {
            let couldMove = engine.moveDown()
            downKeyRepeatTimer = Date()
            // If piece locked (couldn't move), reset repeat timer to prevent momentum carryover
            // Keep key held but reset timer so next piece waits a bit before starting to drop
            if !couldMove {
                downKeyRepeatTimer = Date() // Reset repeat timer, but keep key held
                let dropInterval = getDropInterval()
                lastDropTime = Date().addingTimeInterval(-dropInterval * 0.5) // Wait 50% of normal interval
            }
        }
    }
    
    private func render() {
        // Clear screen with dark background
        SDLRenderHelper.setDrawColor(renderer: renderer, r: 20, g: 20, b: 30, a: 255)
        SDLRenderHelper.clear(renderer: renderer)
        
        // Draw board background
        let boardX: Int32 = 20
        let boardY: Int32 = 20
        let boardPixelWidth = Int32(boardWidth) * cellSize
        let boardPixelHeight = Int32(boardHeight) * cellSize
        
        // Board border
        SDLRenderHelper.setDrawColor(renderer: renderer, r: 100, g: 100, b: 120, a: 255)
        var borderRect = SDL_FRect(x: Float(boardX - 2), y: Float(boardY - 2), w: Float(boardPixelWidth + 4), h: Float(boardPixelHeight + 4))
        SDLRenderHelper.fillRect(renderer: renderer, rect: &borderRect)
        
        // Board background
        SDLRenderHelper.setDrawColor(renderer: renderer, r: 30, g: 30, b: 40, a: 255)
        var boardRect = SDL_FRect(x: Float(boardX), y: Float(boardY), w: Float(boardPixelWidth), h: Float(boardPixelHeight))
        SDLRenderHelper.fillRect(renderer: renderer, rect: &boardRect)
        
        // Draw placed blocks
        let cells = engine.board.getAllCells()
        let linesToClear = engine.linesToClear
        var flashProgress: Double = 0.0
        var fadeProgress: Double = 0.0
        
        if let startTime = engine.lineClearStartTime, !linesToClear.isEmpty {
            let elapsed = Date().timeIntervalSince(startTime)
            // Flash phase (0 to lineClearFlashDuration)
            if elapsed <= engine.lineClearFlashDuration {
                flashProgress = min(elapsed / engine.lineClearFlashDuration, 1.0)
            } else {
                flashProgress = 1.0
                // Fade phase (after flash phase)
                let fadeStart = engine.lineClearFlashDuration
                let fadeElapsed = elapsed - fadeStart
                fadeProgress = min(fadeElapsed / engine.lineClearFadeDuration, 1.0)
            }
        }
        
        for y in 0..<boardHeight {
            let isClearing = linesToClear.contains(y)
            for x in 0..<boardWidth {
                if let type = cells[y][x] {
                    let pixelX = boardX + Int32(x) * cellSize
                    let pixelY = boardY + Int32(y) * cellSize
                    
                    if isClearing {
                        // Calculate block fade alpha (for gradual vanish)
                        let blockAlpha: UInt8
                        if fadeProgress > 0 {
                            // During fade phase: fade from 255 to 0
                            blockAlpha = UInt8(max(0, min(255, (1.0 - fadeProgress) * 255)))
                        } else {
                            blockAlpha = 255
                        }
                        
                        // Draw the block with fade alpha during fade phase
                        if fadeProgress > 0 {
                            drawBlockWithAlpha(x: x, y: y, type: type, boardX: boardX, boardY: boardY, alpha: blockAlpha)
                        } else {
                            // During flash phase: draw block normally
                            drawBlock(x: x, y: y, type: type, boardX: boardX, boardY: boardY)
                        }
                        
                        // Enhanced flash effect during flash phase
                        if flashProgress > 0 && fadeProgress == 0 {
                            // More dramatic flash: oscillating between bright yellow/white with increasing intensity
                            let oscillation = sin(flashProgress * Double.pi * 10) // Faster oscillation (10 cycles)
                            // Intensity increases then decreases for dramatic effect
                            let intensityCurve = sin(flashProgress * Double.pi * 0.5) // Smooth intensity curve
                            let baseIntensity = 0.7 + (intensityCurve * 0.3) // Oscillates between 0.7 and 1.0
                            let flashIntensity = (oscillation * 0.5 + 0.5) * baseIntensity
                            
                            // Bright yellow-white flash with high alpha
                            let flashAlpha = UInt8(max(0, min(255, flashIntensity * 255)))
                            var flashRect = SDL_FRect(x: Float(pixelX), y: Float(pixelY), w: Float(cellSize - 2), h: Float(cellSize - 2))
                            
                            // Draw glow effect (multiple layers for fantastic look)
                            // Outer glow (larger, more transparent)
                            var glowRect = SDL_FRect(
                                x: Float(pixelX) - 2,
                                y: Float(pixelY) - 2,
                                w: Float(cellSize + 2),
                                h: Float(cellSize + 2)
                            )
                            SDLRenderHelper.setDrawColor(renderer: renderer, r: 255, g: 255, b: 200, a: UInt8(flashAlpha / 3))
                            SDLRenderHelper.fillRect(renderer: renderer, rect: &glowRect)
                            
                            // Inner glow (medium)
                            glowRect = SDL_FRect(
                                x: Float(pixelX) - 1,
                                y: Float(pixelY) - 1,
                                w: Float(cellSize),
                                h: Float(cellSize)
                            )
                            SDLRenderHelper.setDrawColor(renderer: renderer, r: 255, g: 255, b: 150, a: UInt8(flashAlpha / 2))
                            SDLRenderHelper.fillRect(renderer: renderer, rect: &glowRect)
                            
                            // Core flash (bright yellow-white)
                            SDLRenderHelper.setDrawColor(renderer: renderer, r: 255, g: 255, b: 200, a: flashAlpha)
                            SDLRenderHelper.fillRect(renderer: renderer, rect: &flashRect)
                        }
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
        
        // Update high score if current score is higher
        if engine.score > highScore {
            highScore = engine.score
            saveSettings()
        }
        
        // Score and info
        drawText(x: panelX, y: panelY, text: "Score: \(engine.score)", r: 255, g: 255, b: 255)
        drawText(x: panelX, y: panelY + 30, text: "High: \(highScore)", r: 255, g: 255, b: 255)
        drawText(x: panelX, y: panelY + 60, text: "Lines: \(engine.linesCleared)", r: 255, g: 255, b: 255)
        drawText(x: panelX, y: panelY + 90, text: "Level: \(engine.level)", r: 255, g: 255, b: 255)
        
        // Next piece
        drawText(x: panelX, y: panelY + 130, text: "Next:", r: 255, g: 255, b: 255)
        
        let nextBlocks = engine.nextPiece.getBlocks()
        let minX = nextBlocks.map { $0.x }.min() ?? 0
        let minY = nextBlocks.map { $0.y }.min() ?? 0
        let nextStartX = panelX
        let nextStartY = panelY + 160
        
        for block in nextBlocks {
            let x = block.x - minX
            let y = block.y - minY
            let blockX = nextStartX + Int32(x) * cellSize
            let blockY = nextStartY + Int32(y) * cellSize
            var rect = SDL_FRect(x: Float(blockX), y: Float(blockY), w: Float(cellSize - 2), h: Float(cellSize - 2))
            let color = getColor(engine.nextPiece.type.color)
            SDLRenderHelper.setDrawColor(renderer: renderer, r: color.r, g: color.g, b: color.b, a: 255)
            SDLRenderHelper.fillRect(renderer: renderer, rect: &rect)
            
            // Border
            SDLRenderHelper.setDrawColor(renderer: renderer, r: 255, g: 255, b: 255, a: 100)
            // SDL3: RenderDrawRect might have different name - using RenderRect for now
            SDLRenderHelper.drawRect(renderer: renderer, rect: &rect)
        }
        
        // Next next piece (smaller)
        let smallCellSize = Int32(Double(cellSize) * 0.6) // 60% of normal size
        let nextNextBlocks = engine.nextNextPiece.getBlocks()
        let nextNextMinX = nextNextBlocks.map { $0.x }.min() ?? 0
        let nextNextMinY = nextNextBlocks.map { $0.y }.min() ?? 0
        let nextNextStartX = panelX
        let nextNextStartY = panelY + 250 // Position below the next piece
        
        // Draw label for next next piece (smaller text would be better, but using same size)
        drawText(x: panelX, y: panelY + 220, text: "After:", r: 200, g: 200, b: 200)
        
        for block in nextNextBlocks {
            let x = block.x - nextNextMinX
            let y = block.y - nextNextMinY
            let blockX = nextNextStartX + Int32(x) * smallCellSize
            let blockY = nextNextStartY + Int32(y) * smallCellSize
            var rect = SDL_FRect(x: Float(blockX), y: Float(blockY), w: Float(smallCellSize - 1), h: Float(smallCellSize - 1))
            let color = getColor(engine.nextNextPiece.type.color)
            SDLRenderHelper.setDrawColor(renderer: renderer, r: color.r, g: color.g, b: color.b, a: 255)
            SDLRenderHelper.fillRect(renderer: renderer, rect: &rect)
            
            // Border (thinner for smaller piece)
            SDLRenderHelper.setDrawColor(renderer: renderer, r: 255, g: 255, b: 255, a: 80)
            SDLRenderHelper.drawRect(renderer: renderer, rect: &rect)
        }
        
        // Game state
        if engine.gameState == .paused {
            drawText(x: panelX, y: panelY + 300, text: "PAUSED", r: 255, g: 255, b: 0)
            if usingController && gamepad != nil {
                drawText(x: panelX, y: panelY + 330, text: "Press Options", r: 200, g: 200, b: 200)
            } else {
                drawText(x: panelX, y: panelY + 330, text: "Press ESC", r: 200, g: 200, b: 200)
            }
        }
        
        if engine.gameState == .gameOver {
            // Calculate box dimensions (wide enough for "Press Share" which is longest)
            let boxWidth: Float = 200
            let boxHeight: Float = 80
            let boxX = Float(boardX + boardPixelWidth / 2) - boxWidth / 2
            let boxY = Float(boardY + boardPixelHeight / 2) - boxHeight / 2 - 10
            
            // Draw background box with border
            var boxRect = SDL_FRect(x: boxX - 4, y: boxY - 4, w: boxWidth + 8, h: boxHeight + 8)
            SDLRenderHelper.setDrawColor(renderer: renderer, r: 0, g: 0, b: 0, a: 200) // Dark border
            SDLRenderHelper.fillRect(renderer: renderer, rect: &boxRect)
            
            // Draw inner box
            boxRect = SDL_FRect(x: boxX, y: boxY, w: boxWidth, h: boxHeight)
            SDLRenderHelper.setDrawColor(renderer: renderer, r: 30, g: 30, b: 40, a: 240) // Dark background
            SDLRenderHelper.fillRect(renderer: renderer, rect: &boxRect)
            
            // Draw game over text
            drawText(x: Int32(boxX + boxWidth / 2 - 80), y: Int32(boxY + 15), text: "GAME OVER", r: 255, g: 0, b: 0)
            if usingController && gamepad != nil {
                drawText(x: Int32(boxX + boxWidth / 2 - 80), y: Int32(boxY + 50), text: "Press Share", r: 200, g: 200, b: 200)
            } else {
                drawText(x: Int32(boxX + boxWidth / 2 - 60), y: Int32(boxY + 50), text: "Press R", r: 200, g: 200, b: 200)
            }
        }
        
        // Controls hint - switch between keyboard and controller
        // Position controls text in the side panel, aligned with window bottom to ensure it fits
        // Controller has 6 lines (120px), keyboard has 5 lines (100px), plus 20px for "Controls:" label
        // Position from window bottom: windowHeight - (max lines * 20) - padding
        let maxControlsHeight: Int32 = 140 // 6 lines * 20px + 20px label = 140px
        let controlsStartY = windowHeight - maxControlsHeight - 10 // 10px padding from bottom
        drawText(x: panelX, y: controlsStartY, text: "Controls:", r: 150, g: 150, b: 150)
        if usingController && gamepad != nil {
            // Controller controls (D-pad and buttons only, no joystick)
            drawText(x: panelX, y: controlsStartY + 20, text: "D-Pad: Move", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 40, text: "D-Pad Dn: Drop", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 60, text: "Up/X: Rotate", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 80, text: "Opt: Pause", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 100, text: "Share: Restart", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 120, text: "M: Music", r: 130, g: 130, b: 130)
        } else {
            // Keyboard controls
            drawText(x: panelX, y: controlsStartY + 20, text: "WASD/Arrows", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 40, text: "Space: Drop", r: 130, g: 130, b: 130)
                drawText(x: panelX, y: controlsStartY + 60, text: "ESC: Pause", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 80, text: "F11: Fullscreen", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 100, text: "M: Music", r: 130, g: 130, b: 130)
        }
        
        SDL_RenderPresent(renderer)
    }
    
    private func drawBlock(x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32) {
        drawBlockWithAlpha(x: x, y: y, type: type, boardX: boardX, boardY: boardY, alpha: 255)
    }
    
    private func drawBlockWithAlpha(x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32, alpha: UInt8) {
        let pixelX = boardX + Int32(x) * cellSize
        let pixelY = boardY + Int32(y) * cellSize
        var rect = SDL_FRect(x: Float(pixelX), y: Float(pixelY), w: Float(cellSize - 2), h: Float(cellSize - 2))
        
        let color = getColor(type.color)
        SDLRenderHelper.setDrawColor(renderer: renderer, r: color.r, g: color.g, b: color.b, a: alpha)
        SDLRenderHelper.fillRect(renderer: renderer, rect: &rect)
        
        // Highlight border (also fade with alpha)
        SDLRenderHelper.setDrawColor(renderer: renderer, r: 255, g: 255, b: 255, a: UInt8((UInt16(alpha) * 100) / 255))
        SDL_RenderRect(renderer, &rect)
    }
    
    private func drawGhostBlock(x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32) {
        let pixelX = boardX + Int32(x) * cellSize
        let pixelY = boardY + Int32(y) * cellSize
        var rect = SDL_FRect(x: Float(pixelX), y: Float(pixelY), w: Float(cellSize - 2), h: Float(cellSize - 2))
        
        // Draw ghost piece as outline only (no fill, just border)
        let color = getColor(type.color)
        // Use a semi-transparent border color
        SDLRenderHelper.setDrawColor(renderer: renderer, r: color.r, g: color.g, b: color.b, a: 80)
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
        // Render text using Swift helper
        guard let surface = TTFHelper.renderText(font: font, text: text, color: color) else {
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
