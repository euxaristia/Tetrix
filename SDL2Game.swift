import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif
import CSDL2

class SDL2Game {
    private var window: OpaquePointer?
    private var renderer: OpaquePointer?
    private var font: OpaquePointer?
    private let engine: TetrisEngine
    private var running = true
    
    private var controller: OpaquePointer? = nil
    private var usingController = false
    private var isFullscreen = false
    private var dPadDownHeld = false
    private var dPadDownRepeatTimer: Date = Date()
    private let dPadDownRepeatInterval: TimeInterval = 0.05 // Repeat interval for soft drop
    private var music: TetrisMusic?
    
    private let cellSize: Int32 = 30
    private let boardWidth = GameBoard.width
    private let boardHeight = GameBoard.height
    private let windowWidth: Int32
    private let windowHeight: Int32
    
    init() {
        engine = TetrisEngine()
        
        // Suppress GTK/libdecor warnings (harmless, just about window decorations)
        setenv("SDL_VIDEODRIVER", "x11", 0)
        
        // Calculate window size: board + side panel for next piece and score
        let boardPixelWidth = Int32(boardWidth) * cellSize
        let boardPixelHeight = Int32(boardHeight) * cellSize
        let sidePanelWidth: Int32 = 200
        windowWidth = boardPixelWidth + sidePanelWidth + 40 // 40 for padding (20 on each side)
        windowHeight = boardPixelHeight + 40 // 40 for padding (20 on top and bottom)
        
        let result = SDL_Init(UInt32(SDL_INIT_VIDEO) | UInt32(SDL_INIT_GAMECONTROLLER) | UInt32(SDL_INIT_AUDIO))
        if result != 0 {
            print("SDL_Init failed: \(result)")
        }
        
        // Initialize music (after SDL audio subsystem is initialized)
        music = TetrisMusic()
        
        // Initialize game controller subsystem and detect controllers
        detectController()
        
        // Try to initialize TTF, but continue if it fails (text rendering will be skipped)
        if TTF_Init() != 0 {
            print("Warning: TTF_Init failed, text rendering disabled")
        }
        
        let title = "Tetrix"
        // Create window hidden to prevent ghost window
        title.withCString { cString in
            window = SDL_CreateWindow(cString, Int32(0x2FFF0000), Int32(0x2FFF0000), windowWidth, windowHeight, SDL_WINDOW_HIDDEN.rawValue)
        }
        if window == nil {
            print("Failed to create window")
        }
        
        renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED.rawValue)
        if renderer == nil {
            print("Failed to create renderer")
        }
        
        // Try to load a default font, fallback to built-in if not available
        font = TTF_OpenFont("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf", 20)
        if font == nil {
            font = TTF_OpenFont("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 20)
        }
        if font == nil {
            font = TTF_OpenFont("/usr/share/fonts/TTF/liberation/LiberationSans-Bold.ttf", 20)
        }
        // If no font found, we'll render without text (just colors)
        
        // Render initial frame while window is hidden
        render()
        
        // Now show the window after first frame is rendered
        SDL_ShowWindow(window)
        
        // Start playing the classic Tetris theme
        music?.start()
    }
    
    deinit {
        if controller != nil {
            SDL_GameControllerClose(controller)
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
        var lastDropTime = Date()
        var lastFrameTime = Date()
        let targetFPS = 60.0
        let frameTime = 1.0 / targetFPS
        
        while running {
            let now = Date()
            
            // Handle events
            handleEvents()
            
            // Handle held D-pad down for soft drop
            handleDPadDownRepeat()
            
            // Update music
            music?.update()
            
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
                usleep(1000) // 1ms
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
        while SDL_PollEvent(&event) != 0 {
            switch event.type {
            case SDL_QUIT.rawValue:
                running = false
            case SDL_KEYDOWN.rawValue:
                usingController = false
                handleKeyPress(&event.key.keysym)
            case SDL_CONTROLLERDEVICEADDED.rawValue:
                detectController()
            case SDL_CONTROLLERDEVICEREMOVED.rawValue:
                if controller != nil {
                    SDL_GameControllerClose(controller)
                    controller = nil
                    usingController = false
                }
            case SDL_CONTROLLERBUTTONDOWN.rawValue:
                usingController = true
                handleControllerButtonDown(event.cbutton.button)
            case SDL_CONTROLLERBUTTONUP.rawValue:
                handleControllerButtonUp(event.cbutton.button)
            default:
                break
            }
        }
    }
    
    private func detectController() {
        // Close existing controller if any
        if controller != nil {
            SDL_GameControllerClose(controller)
            controller = nil
        }
        
        // Find first available game controller
        let numJoysticks = SDL_NumJoysticks()
        for i in 0..<numJoysticks {
            if SDL_IsGameController(i) == SDL_TRUE {
                controller = SDL_GameControllerOpen(i)
                if controller != nil {
                    let name = SDL_GameControllerName(controller)
                    if name != nil {
                        let nameString = String(cString: name!)
                        print("Controller connected: \(nameString)")
                    }
                    break
                }
            }
        }
    }
    
    private func handleKeyPress(_ keysym: UnsafePointer<SDL_Keysym>) {
        let scancode = keysym.pointee.scancode
        switch scancode {
        case SDL_SCANCODE_A, SDL_SCANCODE_LEFT:
            engine.moveLeft()
        case SDL_SCANCODE_D, SDL_SCANCODE_RIGHT:
            engine.moveRight()
        case SDL_SCANCODE_S, SDL_SCANCODE_DOWN:
            _ = engine.moveDown()
        case SDL_SCANCODE_W, SDL_SCANCODE_UP:
            engine.rotate()
        case SDL_SCANCODE_SPACE:
            engine.hardDrop()
        case SDL_SCANCODE_P:
            engine.pause()
        case SDL_SCANCODE_Q:
            running = false
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
        default:
            break
        }
    }
    
    private func toggleFullscreen() {
        guard let window = window else { return }
        isFullscreen.toggle()
        if isFullscreen {
            SDL_SetWindowFullscreen(window, SDL_WINDOW_FULLSCREEN_DESKTOP.rawValue)
        } else {
            SDL_SetWindowFullscreen(window, 0)
        }
    }
    
    private func handleControllerButtonDown(_ button: UInt8) {
        // SDL_GameControllerButton enum values
        // A=0, B=1, X=2, Y=3, BACK=4, START=6
        // DPAD_UP=11, DPAD_DOWN=12, DPAD_LEFT=13, DPAD_RIGHT=14
        switch button {
        case 11: // SDL_CONTROLLER_BUTTON_DPAD_UP
            engine.rotate()
        case 13: // SDL_CONTROLLER_BUTTON_DPAD_LEFT
            engine.moveLeft()
        case 14: // SDL_CONTROLLER_BUTTON_DPAD_RIGHT
            engine.moveRight()
        case 12: // SDL_CONTROLLER_BUTTON_DPAD_DOWN
            dPadDownHeld = true
            dPadDownRepeatTimer = Date()
            _ = engine.moveDown() // Immediate action
        case 0: // SDL_CONTROLLER_BUTTON_A (X button on DualSense)
            engine.rotate()
        case 6: // SDL_CONTROLLER_BUTTON_START (Options button on DualSense)
            engine.pause()
        case 4: // SDL_CONTROLLER_BUTTON_BACK (Share button on DualSense)
            running = false
        case 1: // SDL_CONTROLLER_BUTTON_B (Circle button on DualSense) - restart on game over
            if engine.gameState == .gameOver {
                engine.reset()
            }
        default:
            break
        }
    }
    
    private func handleControllerButtonUp(_ button: UInt8) {
        switch button {
        case 12: // SDL_CONTROLLER_BUTTON_DPAD_DOWN
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
            _ = engine.moveDown()
            dPadDownRepeatTimer = Date()
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
        var borderRect = SDL_Rect(x: boardX - 2, y: boardY - 2, w: boardPixelWidth + 4, h: boardPixelHeight + 4)
        SDL_RenderFillRect(renderer, &borderRect)
        
        // Board background
        SDL_SetRenderDrawColor(renderer, 30, 30, 40, 255)
        var boardRect = SDL_Rect(x: boardX, y: boardY, w: boardPixelWidth, h: boardPixelHeight)
        SDL_RenderFillRect(renderer, &boardRect)
        
        // Draw placed blocks
        let cells = engine.board.getAllCells()
        for y in 0..<boardHeight {
            for x in 0..<boardWidth {
                if let type = cells[y][x] {
                    drawBlock(x: x, y: y, type: type, boardX: boardX, boardY: boardY)
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
            var rect = SDL_Rect(x: blockX, y: blockY, w: cellSize - 2, h: cellSize - 2)
            let color = getColor(engine.nextPiece.type.color)
            SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, 255)
            SDL_RenderFillRect(renderer, &rect)
            
            // Border
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, 100)
            SDL_RenderDrawRect(renderer, &rect)
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
        if usingController && controller != nil {
            // Controller controls (D-pad and buttons only, no joystick)
            drawText(x: panelX, y: controlsStartY + 20, text: "D-Pad: Move", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 40, text: "D-Pad Dn: Drop", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 60, text: "Up/X: Rotate", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 80, text: "Opt: Pause", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 100, text: "Share: Quit", r: 130, g: 130, b: 130)
        } else {
            // Keyboard controls
            drawText(x: panelX, y: controlsStartY + 20, text: "WASD/Arrows", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 40, text: "Space: Drop", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 60, text: "P: Pause", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 80, text: "Q: Quit", r: 130, g: 130, b: 130)
            drawText(x: panelX, y: controlsStartY + 100, text: "F11: Fullscreen", r: 130, g: 130, b: 130)
        }
        
        SDL_RenderPresent(renderer)
    }
    
    private func drawBlock(x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32) {
        let pixelX = boardX + Int32(x) * cellSize
        let pixelY = boardY + Int32(y) * cellSize
        var rect = SDL_Rect(x: pixelX, y: pixelY, w: cellSize - 2, h: cellSize - 2)
        
        let color = getColor(type.color)
        SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, 255)
        SDL_RenderFillRect(renderer, &rect)
        
        // Highlight border
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 100)
        SDL_RenderDrawRect(renderer, &rect)
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
            // No font available, skip text rendering
            return
        }
        
        let color = SDL_Color(r: r, g: g, b: b, a: 255)
        let surface = TTF_RenderText_Solid(font, text, color)
        guard surface != nil else {
            return
        }
        
        let texture = SDL_CreateTextureFromSurface(renderer, surface)
        SDL_FreeSurface(surface)
        
        guard texture != nil else {
            return
        }
        
        var destRect = SDL_Rect()
        SDL_QueryTexture(texture, nil, nil, &destRect.w, &destRect.h)
        destRect.x = x
        destRect.y = y
        
        SDL_RenderCopy(renderer, texture, nil, &destRect)
        SDL_DestroyTexture(texture)
    }
}
