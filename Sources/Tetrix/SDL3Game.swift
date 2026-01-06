import Foundation
#if os(Linux)
import Glibc
#endif
import CSDL3

// High-performance timing for game loop
#if os(Linux)
private func getCurrentTime() -> TimeInterval {
    var ts = timespec()
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return TimeInterval(ts.tv_sec) + TimeInterval(ts.tv_nsec) / 1_000_000_000.0
}
#elseif os(macOS)
private func getCurrentTime() -> TimeInterval {
    return CFAbsoluteTimeGetCurrent()
}
#else
private func getCurrentTime() -> TimeInterval {
    return Date().timeIntervalSince1970
}
#endif

class SDL3Game {
    // Use SDL3 for rendering on all platforms
    private var window: OpaquePointer?  // SDL3 window
    private var renderer: RendererProtocol?     // SDL3 renderer wrapper
    // Font removed - using Swift-native text renderer
    private let engine: TetrisEngine
    private var threadSafeState: ThreadSafeGameState?
    private var running = true
    private let threadPool = ThreadPoolManager.shared
    
    private var gamepad: Gamepad?
    private var usingController = false
    private var isFullscreen = false
    private var textRenderer: SwiftTextRenderer?  // Swift-native text renderer (replaces TTF)
    private var dPadDownHeld = false
    private var dPadDownRepeatTimer: TimeInterval = 0
    private let dPadDownRepeatInterval: TimeInterval = 0.05 // Repeat interval for soft drop
    private var dPadLeftHeld = false
    private var dPadLeftRepeatTimer: TimeInterval = 0
    private var dPadRightHeld = false
    private var dPadRightRepeatTimer: TimeInterval = 0
    private let dPadHorizontalRepeatInterval: TimeInterval = 0.03 // Repeat interval for left/right movement
    private let dPadHorizontalInitialDelay: TimeInterval = 0.15 // Initial delay before first repeat (prevents double-input)
    private var downKeyHeld = false
    private var downKeyRepeatTimer: TimeInterval = 0
    private let downKeyRepeatInterval: TimeInterval = 0.03 // Faster repeat interval for keyboard soft drop
    private var lastDropTime: TimeInterval = 0 // Track automatic drop timing, reset when piece locks
    private var music: TetrisMusic?
    private var musicEnabled = true
    private var highScore: Int = 0
    private let settingsManager = SettingsManager.shared
    private var windowShown = false  // Track if window has been shown
    
    private let cellSize: Int32 = 30
    private let boardWidth = GameBoard.width
    private let boardHeight = GameBoard.height
    private let windowWidth: Int32
    private let windowHeight: Int32
    private let logicalWidth: Int32  // Logical presentation width (for rendering coordinates)
    private let logicalHeight: Int32  // Logical presentation height (for rendering coordinates)
    
    init() {
        engine = TetrisEngine()
        threadSafeState = ThreadSafeGameState()
        
        // Load settings
        let settings = settingsManager.loadSettings()
        highScore = settings.highScore
        musicEnabled = settings.musicEnabled
        isFullscreen = settings.isFullscreen
        
        // No need to set video driver - SDL3 will auto-detect on Windows
        
        // Calculate window size: board + side panel for next piece and score
        // Resolution scale factor (2x = double resolution, items stay same size)
        let resolutionScale: Int32 = 2
        
        // Base size calculation
        let boardPixelWidth = Int32(boardWidth) * cellSize
        let boardPixelHeight = Int32(boardHeight) * cellSize
        let sidePanelWidth: Int32 = 200
        
        // Logical size (for rendering coordinates - keeps items same visual size)
        logicalWidth = boardPixelWidth + sidePanelWidth + 40 // 40 for padding (20 on each side)
        logicalHeight = boardPixelHeight + 40 // 40 for padding (20 on top and bottom)
        
        // Physical window size (higher resolution - maintains same aspect ratio)
        windowWidth = logicalWidth * resolutionScale
        windowHeight = logicalHeight * resolutionScale
        
        // Initialize platform-specific subsystems
        #if os(Linux)
        // Linux: Use SDL3 (handles X11/Wayland automatically)
        // Note: libdecor-gtk warnings are harmless - SDL will fall back to other backends
        
        // Check what's already initialized
        let videoFlag: UInt32 = 0x00000020  // SDL_INIT_VIDEO
        let gamepadFlag: UInt32 = 0x00002000  // SDL_INIT_GAMEPAD
        let audioFlag: UInt32 = 0x00000010  // SDL_INIT_AUDIO
        let eventsFlag: UInt32 = 0x00004000  // SDL_INIT_EVENTS
        let allFlags: UInt32 = videoFlag | gamepadFlag | audioFlag
        
        let wasInit = SDL_WasInit(allFlags)
        if wasInit != 0 {
            print("Note: Some SDL subsystems already initialized (flags: 0x\(String(wasInit, radix: 16)))")
        }
        
        // Let SDL3 auto-detect the video driver (don't force X11 or Wayland)
        // The crash might be related to forcing a specific driver
        let currentDriver = ProcessInfo.processInfo.environment["SDL_VIDEODRIVER"]
        if currentDriver != nil {
            print("Using SDL_VIDEODRIVER=\(currentDriver!)")
        } else {
            print("SDL_VIDEODRIVER not set, SDL3 will auto-detect")
        }
        
        // Clear any previous errors
        SDL_ClearError()
        
        // Try initializing all subsystems at once (SDL3's preferred method)
        let initResult = SDL_Init(allFlags)
        
        if initResult == 0 {
            print("SDL subsystems initialized successfully")
        } else {
            // If that fails, try subsystems separately
            print("SDL_Init failed with code \(initResult), trying subsystems separately...")
            SDL_ClearError()
            
            // Events MUST be initialized first in SDL3 (video depends on it)
            let eventsResult = SDL_InitSubSystem(eventsFlag)
            if eventsResult == 0 {
                print("SDL events subsystem initialized")
            } else {
                let errorMsg = String.sdlError() ?? "unknown error"
                print("Warning: SDL events subsystem failed: \(errorMsg) (code: \(eventsResult))")
            }
            
            // Try video (required) - but only if events succeeded
            SDL_ClearError()
            let videoResult: Int32
            if eventsResult == 0 {
                videoResult = SDL_InitSubSystem(videoFlag)
            } else {
                print("Skipping video init - events subsystem failed")
                videoResult = -1
            }
            if videoResult == 0 {
                print("SDL video subsystem initialized")
                
                // Try gamepad (optional)
                SDL_ClearError()
                if SDL_InitSubSystem(gamepadFlag) == 0 {
                    print("SDL gamepad subsystem initialized")
                } else {
                    let errorMsg = String.sdlError() ?? "unknown error"
                    print("Warning: SDL gamepad subsystem failed: \(errorMsg)")
                }
                
                // Try audio (optional)
                SDL_ClearError()
                if SDL_InitSubSystem(audioFlag) == 0 {
                    print("SDL audio subsystem initialized")
                } else {
                    let errorMsg = String.sdlError() ?? "unknown error"
                    print("Warning: SDL audio subsystem failed: \(errorMsg)")
                }
            } else {
                // Video subsystem is required
                let errorMsg = String.sdlError() ?? "unknown error"
                
                // Check what subsystems ARE actually initialized (sometimes InitSubSystem fails but WasInit shows success)
                let wasInitVideo = SDL_WasInit(videoFlag)
                let wasInitEvents = SDL_WasInit(eventsFlag)
                let wasInitGamepad = SDL_WasInit(gamepadFlag)
                let wasInitAudio = SDL_WasInit(audioFlag)
                
                print("Error: SDL video subsystem init returned error (code: \(videoResult))")
                print("Currently initialized subsystems (from SDL_WasInit):")
                print("  - Video: \(wasInitVideo != 0 ? "YES (0x\(String(wasInitVideo, radix: 16)))" : "NO")")
                print("  - Events: \(wasInitEvents != 0 ? "YES (0x\(String(wasInitEvents, radix: 16)))" : "NO")")
                print("  - Gamepad: \(wasInitGamepad != 0 ? "YES (0x\(String(wasInitGamepad, radix: 16)))" : "NO")")
                print("  - Audio: \(wasInitAudio != 0 ? "YES (0x\(String(wasInitAudio, radix: 16)))" : "NO")")
                
                if !errorMsg.isEmpty && errorMsg != "unknown error" {
                    print("Error message: \(errorMsg)")
                }
                print("Note: libdecor-gtk warnings are harmless - SDL should fall back automatically")
                
                // Provide troubleshooting info
                if errorMsg == "unknown error" || errorMsg.isEmpty {
                    print("\nSDL_GetError() returned NULL/empty - troubleshooting:")
                    let display = ProcessInfo.processInfo.environment["DISPLAY"] ?? "not set"
                    let waylandDisplay = ProcessInfo.processInfo.environment["WAYLAND_DISPLAY"] ?? "not set"
                    let sdlDriver = ProcessInfo.processInfo.environment["SDL_VIDEODRIVER"] ?? "not set"
                    print("  - DISPLAY: \(display)")
                    print("  - WAYLAND_DISPLAY: \(waylandDisplay)")
                    print("  - SDL_VIDEODRIVER: \(sdlDriver)")
                    print("  - System issue detected: libX11 has undefined symbols (see LD_DEBUG output)")
                    print("  - Video driver is already forced to wayland, but SDL may still probe X11")
                    print("  - Try reinstalling X11 libraries:")
                    print("    pacman -S libx11 libxext libxfixes")
                    print("  - Or try updating all packages: sudo pacman -Syu")
                    print("  - Note: Since you're on Wayland, X11 issues shouldn't affect SDL_Wayland")
                }
                
                // Don't return if video subsystem is actually initialized despite error code
                // Sometimes SDL reports error but subsystem is usable
                if wasInitVideo == 0 {
                    print("\nFatal: Video subsystem not initialized (SDL_WasInit confirms), cannot continue")
                    return
                } else {
                    print("\nWarning: Video init reported failure but SDL_WasInit shows it's initialized")
                    print("Attempting to continue (SDL may have initialized despite error code)...")
                }
            }
        }
        
        // Initialize Swift-native text renderer (replaces SDL3_ttf)
        // Note: Text renderer needs renderer to be set after SDL3 renderer is created
        
        // Create SDL3 window on Linux
        let title = "Tetrix"
        // Create window hidden - we'll show it in the run loop after SDL is fully ready
        let windowFlags = WindowFlag.combine(.hidden, .resizable)
        
        // Clear any SDL errors before creating window
        SDL_ClearError()
        
        window = SDLHelper.createWindow(title: title, width: windowWidth, height: windowHeight, flags: windowFlags)
        if window == nil {
            let errorMsg = SDLHelper.errorMessage()
            print("Failed to create window: \(errorMsg)")
            return
        }
        
        print("Window created successfully (hidden)")
        
        // Create SDL3 renderer on Linux
        if let sdlRenderer = SDLRenderHelper.create(window: window) {
            renderer = Renderer(sdlRenderer: sdlRenderer)
            
            // Initialize text renderer and set renderer
            if let textRenderer = SwiftTextRenderer() {
                textRenderer.setRenderer(renderer!)
                self.textRenderer = textRenderer
            }
        } else {
            print("Failed to create renderer")
            return
        }
        #else
        // Windows/macOS: Use SDL3 for all rendering (same as Linux for consistency)
        // Check what's already initialized
        let videoFlag: UInt32 = 0x00000020  // SDL_INIT_VIDEO
        let gamepadFlag: UInt32 = 0x00002000  // SDL_INIT_GAMEPAD
        let audioFlag: UInt32 = 0x00000010  // SDL_INIT_AUDIO
        let eventsFlag: UInt32 = 0x00004000  // SDL_INIT_EVENTS
        let allFlags: UInt32 = videoFlag | gamepadFlag | audioFlag | eventsFlag
        
        // Clear any previous errors
        SDL_ClearError()
        
        // Initialize SDL subsystems
        let initResult = SDL_Init(allFlags)
        
        if initResult != 0 {
            let errorMsg = String.sdlError() ?? "unknown error"
            print("Warning: SDL_Init failed: \(errorMsg), trying subsystems separately...")
            SDL_ClearError()
            
            // Events MUST be initialized first in SDL3
            SDL_ClearError()
            let eventsResult = SDL_InitSubSystem(eventsFlag)
            if eventsResult != 0 {
                let errorMsg = String.sdlError() ?? "unknown error"
                print("Error: SDL events subsystem failed (code: \(eventsResult)): \(errorMsg)")
                // Check if it's actually initialized despite error code
                let wasInit = SDL_WasInit(eventsFlag)
                if wasInit != 0 {
                    print("  Note: SDL_WasInit shows events subsystem IS initialized (0x\(String(wasInit, radix: 16)))")
                }
            } else {
                print("SDL events subsystem initialized successfully")
            }
            
            // Video (required)
            SDL_ClearError()
            let videoResult = SDL_InitSubSystem(videoFlag)
            if videoResult != 0 {
                let errorMsg = String.sdlError() ?? "unknown error"
                print("Error: SDL video subsystem failed (code: \(videoResult)): \(errorMsg)")
                // Check if it's actually initialized despite error code
                let wasInit = SDL_WasInit(videoFlag)
                if wasInit != 0 {
                    print("  Note: SDL_WasInit shows video subsystem IS initialized (0x\(String(wasInit, radix: 16)))")
                    print("  Continuing despite error code...")
                } else {
                    print("  SDL_WasInit confirms video subsystem NOT initialized - cannot continue")
                    return
                }
            } else {
                print("SDL video subsystem initialized successfully")
            }
            
            // Gamepad and audio (optional)
            SDL_ClearError()
            let gamepadResult = SDL_InitSubSystem(gamepadFlag)
            if gamepadResult != 0 {
                let errorMsg = String.sdlError() ?? "unknown error"
                print("Warning: SDL gamepad subsystem failed (code: \(gamepadResult)): \(errorMsg)")
            } else {
                print("SDL gamepad subsystem initialized successfully")
            }
            
            SDL_ClearError()
            let audioResult = SDL_InitSubSystem(audioFlag)
            if audioResult != 0 {
                let errorMsg = String.sdlError() ?? "unknown error"
                print("Warning: SDL audio subsystem failed (code: \(audioResult)): \(errorMsg)")
            } else {
                print("SDL audio subsystem initialized successfully")
            }
        }
        
        // Create SDL3 window
        let title = "Tetrix"
        let windowFlags = WindowFlag.combine(.hidden, .resizable)
        
        SDL_ClearError()
        window = SDLHelper.createWindow(title: title, width: windowWidth, height: windowHeight, flags: windowFlags)
        if window == nil {
            let errorMsg = SDLHelper.errorMessage()
            print("Failed to create window: \(errorMsg)")
            return
        }
        
        print("Window created successfully (hidden)")
        
        // Create SDL3 renderer
        if let sdlRenderer = SDLRenderHelper.create(window: window) {
            renderer = Renderer(sdlRenderer: sdlRenderer)
            
            // Initialize text renderer and set renderer (works on all platforms with SDL3)
            if let textRenderer = SwiftTextRenderer() {
                textRenderer.setRenderer(renderer!)
                self.textRenderer = textRenderer
            }
        } else {
            print("Failed to create renderer")
            return
        }
        #endif
        
        // Initialize music (uses SDL audio on all platforms for now)
        music = TetrisMusic()
        
        // Initialize game controller subsystem and detect controllers
        detectGamepad()
        
        // Font loading removed - using Swift-native text renderer
        // Text renderer is initialized above
        
        // Render initial frame while window is hidden
        render()
        
        // Apply fullscreen state if it was saved (applies to all platforms)
        if isFullscreen {
            if let sdlWindow = window {
                _ = SDL_SetWindowFullscreen(sdlWindow, true)
                if let sdlRenderer = renderer?.sdlHandle {
                    _ = SDL_SetRenderLogicalPresentation(sdlRenderer, logicalWidth, logicalHeight, SDL_LOGICAL_PRESENTATION_LETTERBOX)
                }
            }
        }
        
        // Start playing the classic Tetris theme if music is enabled
        if musicEnabled {
            music?.start()
        }
    }
    
    deinit {
        gamepad?.close()
        gamepad = nil
        textRenderer = nil
        renderer = nil
        SDLHelper.destroyWindow(window)
        SDLHelper.quit()
    }
    
    func run() {
        let startTime = getCurrentTime()
        lastDropTime = startTime // Initialize drop timer
        var lastFrameTime = startTime
        let targetFPS = 60.0
        let frameTime = 1.0 / targetFPS
        
        // Simple, fast game loop - direct access, no threading overhead
        while running {
            let now = getCurrentTime()
            
            // Window is created hidden - show it on first frame after SDL is ready
            // This works on all platforms now (Linux and Windows both use SDL3)
            if !windowShown {
                if let sdlWindow = window {
                    // Pump events first to ensure SDL is ready
                    SDLEventHelper.pumpEvents()
                    // Try to show the window - wrap in error handling
                    SDL_ClearError()
                    SDLWindowHelper.show(window: sdlWindow)
                    if let error = String.sdlError(), !error.isEmpty {
                        print("Warning: Error showing window: \(error)")
                    } else {
                        print("Window shown successfully")
                    }
                    // Pump events again to let window manager process the show
                    SDLEventHelper.pumpEvents()
                    
                    // Set logical presentation after window is shown to ensure correct aspect ratio
                    // Use integer scale mode to maintain aspect ratio perfectly (2x scale, no letterbox bars)
                    if let sdlRenderer = renderer?.sdlHandle {
                        _ = SDLWindowHelper.setLogicalPresentation(renderer: sdlRenderer, width: logicalWidth, height: logicalHeight, mode: .integerScale)
                    }
                    
                    windowShown = true
                }
            }
            
            // Always pump events every frame for responsive input
            // Flush analog events when controller is active to prevent queue buildup
            handleEvents()
            
            // Handle held D-pad down for soft drop
            handleDPadDownRepeat(now: now)
            
            // Handle held D-pad left/right for continuous movement
            handleDPadHorizontalRepeat(now: now)
            
            // Handle held down key for soft drop
            handleDownKeyRepeat(now: now)
            
            // Show cursor when paused, even if controller is in use
            if engine.gameState == .paused {
                SDLCursorHelper.show()
            }
            
            // Update music (only if enabled)
            if musicEnabled {
                music?.update()
            }
            
            // Update line clearing animation
            engine.updateLineClearing()
            
            // Update game (drop piece based on level)
            let dropInterval = getDropInterval()
            if now - lastDropTime >= dropInterval {
                engine.update()
                lastDropTime = now
            }
            
            // Render at target FPS
            if now - lastFrameTime >= frameTime {
                render()
                lastFrameTime = now
            }
            // Don't process events again here - already processed at start of loop
            // This avoids double-processing and controller event flooding
        }
    }
    
    private func handleEvents() {
        // Pump events from OS into SDL's queue first - critical for input responsiveness
        // Always pump every frame to ensure no input is missed (works on all platforms with SDL3)
        SDLEventHelper.pumpEvents()
        // Flush analog events immediately after pumping when NOT using controller to prevent queue buildup
        // This ensures keyboard events aren't delayed by analog stick events from a connected gamepad
        if !usingController {
            SDLEventHelper.flushAnalogEvents()
        }
        handleEventsNoPump()
    }
    
    private func handleEventsNoPump() {
        // Poll for events using Swift-native event system
        // Process events efficiently - prioritize keyboard input responsiveness
        var eventsProcessed = 0
        // Increase max events for keyboard to ensure responsiveness even if analog events flood queue
        let maxEvents = usingController ? 10 : 100  // Higher limit for keyboard mode
        
        while true {
            // Always flush analog events first when not using controller to prevent queue buildup
            if !usingController {
                SDLEventHelper.flushAnalogEvents()
            }
            
            guard let event = EventPoller.poll() else {
                // No more events available
                break
            }
            
            eventsProcessed += 1
            
            // Process the event immediately
            switch event {
            case .quit:
                running = false
                return  // Exit immediately on quit
            case .keyDown(let keyCode, let isRepeat):
                if !usingController {
                    // Only show cursor when keyboard is first used
                    SDLCursorHelper.show()
                }
                usingController = false
                handleKeyPress(keyCode, isRepeat: isRepeat)
            case .keyUp(let keyCode):
                handleKeyRelease(keyCode)
            case .gamepadAdded:
                detectGamepad()
            case .gamepadRemoved:
                gamepad?.close()
                gamepad = nil
                usingController = false
                // Show cursor when gamepad is removed
                SDLCursorHelper.show()
            case .gamepadButtonDown(let button):
                if !usingController {
                    // Hide cursor when controller is first used (unless paused)
                    if engine.gameState != .paused {
                        SDLCursorHelper.hide()
                    }
                }
                usingController = true
                handleGamepadButtonDown(UInt32(button))
            case .gamepadButtonUp(let button):
                handleGamepadButtonUp(UInt32(button))
            case .windowFocusLost:
                // Auto-pause when window loses focus
                if engine.gameState == .playing {
                    engine.pause()
                }
                // Stop music when window loses focus
                music?.stop()
            case .windowFocusGained:
                // Window regained focus - game stays paused, user can press ESC to resume
                // Music will resume when user manually unpauses if music is enabled
                break
            }
            
            // Limit to prevent infinite loops
            if eventsProcessed >= maxEvents {
                // If we hit the limit, flush remaining analog events to prevent queue buildup
                if usingController {
                    SDLEventHelper.flushAnalogEvents()
                }
                break
            }
        }
    }
    
    private func handleKeyPress(_ keyCode: KeyCode, isRepeat: Bool) {
        switch keyCode {
        case .a, .left:
            engine.moveLeft()
        case .d, .right:
            engine.moveRight()
        case .s, .down:
            // Start holding down key for continuous movement
            if !downKeyHeld {
                downKeyHeld = true
                downKeyRepeatTimer = getCurrentTime()
                // Immediate movement on first press
                let couldMove = engine.moveDown()
                if !couldMove {
                    // Reset repeat timer but keep key held so it continues working for next piece
                    downKeyRepeatTimer = getCurrentTime()
                    let dropInterval = getDropInterval()
                    lastDropTime = getCurrentTime() - dropInterval * 0.5 // Wait 50% of normal interval
                }
            }
        case .w, .up:
            engine.rotate()
        case .space:
            engine.hardDrop()
        case .escape:
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
        case .r:
            if engine.gameState == .gameOver {
                engine.reset()
            }
        case .f11:
            // Ignore key repeat for fullscreen toggle
            if !isRepeat {
                toggleFullscreen()
            }
        case .m:
            // Ignore key repeat for music toggle - only toggle on initial press
            if !isRepeat {
                toggleMusic()
            }
        default:
            break
        }
    }
    
    private func handleGamepadButtonDown(_ button: UInt32) {
        // SDL_GamepadButton enum values in SDL3
        // A=0, B=1, X=2, Y=3, BACK=4, START=6
        // DPAD_UP=11, DPAD_DOWN=12, DPAD_LEFT=13, DPAD_RIGHT=14
        let now = getCurrentTime()
        switch button {
        case 11: // SDL_GAMEPAD_BUTTON_DPAD_UP
            engine.rotate()
        case 13: // SDL_GAMEPAD_BUTTON_DPAD_LEFT
            dPadLeftHeld = true
            // Set timer to now + initial delay to prevent immediate repeat
            dPadLeftRepeatTimer = now + dPadHorizontalInitialDelay
            engine.moveLeft() // Immediate action
        case 14: // SDL_GAMEPAD_BUTTON_DPAD_RIGHT
            dPadRightHeld = true
            // Set timer to now + initial delay to prevent immediate repeat
            dPadRightRepeatTimer = now + dPadHorizontalInitialDelay
            engine.moveRight() // Immediate action
        case 12: // SDL_GAMEPAD_BUTTON_DPAD_DOWN
            dPadDownHeld = true
            dPadDownRepeatTimer = now
            let couldMove = engine.moveDown() // Immediate action
            // If piece locked (couldn't move), reset repeat timer to prevent momentum carryover
            // Keep key held but reset timer so next piece waits a bit before starting to drop
            if !couldMove {
                dPadDownRepeatTimer = now // Reset repeat timer, but keep key held
                let dropInterval = getDropInterval()
                lastDropTime = now - dropInterval * 0.5 // Wait 50% of normal interval
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
    
    private func handleDPadDownRepeat(now: TimeInterval) {
        guard dPadDownHeld else { return }
        
        let timeSinceLastAction = now - dPadDownRepeatTimer
        
        if timeSinceLastAction >= dPadDownRepeatInterval {
            let couldMove = engine.moveDown()
            dPadDownRepeatTimer = now
            // If piece locked (couldn't move), reset repeat timer to prevent momentum carryover
            // Keep key held but reset timer so next piece waits a bit before starting to drop
            if !couldMove {
                dPadDownRepeatTimer = now // Reset repeat timer, but keep key held
                let dropInterval = getDropInterval()
                lastDropTime = now - dropInterval * 0.5 // Wait 50% of normal interval
            }
        }
    }
    
    private func handleDPadHorizontalRepeat(now: TimeInterval) {
        // Handle D-pad left repeat
        if dPadLeftHeld {
            let timeSinceLastAction = now - dPadLeftRepeatTimer
            if timeSinceLastAction >= dPadHorizontalRepeatInterval {
                engine.moveLeft()
                dPadLeftRepeatTimer = now
            }
        }
        
        // Handle D-pad right repeat
        if dPadRightHeld {
            let timeSinceLastAction = now - dPadRightRepeatTimer
            if timeSinceLastAction >= dPadHorizontalRepeatInterval {
                engine.moveRight()
                dPadRightRepeatTimer = now
            }
        }
    }
    
    private func handleDownKeyRepeat(now: TimeInterval) {
        guard downKeyHeld else { return }
        
        let timeSinceLastAction = now - downKeyRepeatTimer
        
        if timeSinceLastAction >= downKeyRepeatInterval {
            let couldMove = engine.moveDown()
            downKeyRepeatTimer = now
            // If piece locked (couldn't move), reset repeat timer to prevent momentum carryover
            // Keep key held but reset timer so next piece waits a bit before starting to drop
            if !couldMove {
                downKeyRepeatTimer = now // Reset repeat timer, but keep key held
                let dropInterval = getDropInterval()
                lastDropTime = now - dropInterval * 0.5 // Wait 50% of normal interval
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
    
    // handleEvents() removed - now handled by handleEventsMultithreaded() in input thread
    
    private func detectGamepad() {
        // If we already have a gamepad, don't detect again (prevents duplicate messages)
        if gamepad != nil {
            return
        }
        
        // Find first available gamepad using Swift-native wrapper
        // Only check first gamepad to avoid performance issues
        let gamepadIDs = SDLGamepadHelper.getGamepadJoystickIDs()
        guard !gamepadIDs.isEmpty else { return }
        
        // Only try the first gamepad to avoid delays
        let id = gamepadIDs[0]
        if let newGamepad = Gamepad(id: id) {
            gamepad = newGamepad
            if let name = newGamepad.name {
                print("Gamepad connected: \(name)")
            }
        }
    }
    
    private func handleKeyRelease(_ keyCode: KeyCode) {
        switch keyCode {
        case .s, .down:
            downKeyHeld = false
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
        isFullscreen.toggle()
        guard let sdlWindow = window, let renderer = renderer else { return }
        // Toggle fullscreen using SDL3 (works on all platforms)
        _ = SDLWindowHelper.setFullscreen(window: sdlWindow, fullscreen: isFullscreen)
        
        // Always use integer scale mode for sharp scaling in both windowed and fullscreen modes
        // This ensures consistent scaling and maintains aspect ratio perfectly
        if let sdlRenderer = renderer.sdlHandle {
            _ = SDLWindowHelper.setLogicalPresentation(renderer: sdlRenderer, width: logicalWidth, height: logicalHeight, mode: .integerScale)
        }
        saveSettings()
    }
    
    // Old handleGamepadButtonDown removed - now using handleGamepadButtonDownMultithreaded
    private func handleGamepadButtonDown_OLD(_ button: UInt32) {
        // SDL_GamepadButton enum values in SDL3
        // A=0, B=1, X=2, Y=3, BACK=4, START=6
        // DPAD_UP=11, DPAD_DOWN=12, DPAD_LEFT=13, DPAD_RIGHT=14
        let now = getCurrentTime()
        switch button {
        case 11: // SDL_GAMEPAD_BUTTON_DPAD_UP
            engine.rotate()
        case 13: // SDL_GAMEPAD_BUTTON_DPAD_LEFT
            dPadLeftHeld = true
            dPadLeftRepeatTimer = now
            engine.moveLeft() // Immediate action
        case 14: // SDL_GAMEPAD_BUTTON_DPAD_RIGHT
            dPadRightHeld = true
            dPadRightRepeatTimer = now
            engine.moveRight() // Immediate action
        case 12: // SDL_GAMEPAD_BUTTON_DPAD_DOWN
            dPadDownHeld = true
            dPadDownRepeatTimer = now
            let couldMove = engine.moveDown() // Immediate action
            // If piece locked (couldn't move), reset repeat timer to prevent momentum carryover
            // Keep key held but reset timer so next piece waits a bit before starting to drop
            if !couldMove {
                dPadDownRepeatTimer = now // Reset repeat timer, but keep key held
                let dropInterval = getDropInterval()
                lastDropTime = now - dropInterval * 0.5 // Wait 50% of normal interval
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
        guard let gamepadButton = GamepadButton(rawValue: UInt8(button)) else { return }
        
        switch gamepadButton {
        case .dpadDown:
            dPadDownHeld = false
        case .dpadLeft:
            dPadLeftHeld = false
        case .dpadRight:
            dPadRightHeld = false
        default:
            break
        }
    }
    
    // Old repeat handlers removed - now handled in handleInputRepeats() in input thread
    
    private func render() {
        guard let renderer = renderer else { return }
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
            // Use Date() for animation timing - not in critical input path
            let elapsed = Date().timeIntervalSince(startTime)
            // Flash phase (0 to lineClearFlashDuration)
            // Use constants from engine for animation timing
            let flashDuration: TimeInterval = 0.35
            let fadeDuration: TimeInterval = 0.25
            if elapsed <= flashDuration {
                flashProgress = min(elapsed / flashDuration, 1.0)
            } else {
                flashProgress = 1.0
                // Fade phase (after flash phase)
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
                            let flashRect = Rect(x: Float(pixelX), y: Float(pixelY), width: Float(cellSize - 2), height: Float(cellSize - 2))
                            
                            // Draw glow effect (multiple layers for fantastic look)
                            // Outer glow (larger, more transparent)
                            var glowRect = Rect(
                                x: Float(pixelX) - 2,
                                y: Float(pixelY) - 2,
                                width: Float(cellSize + 2),
                                height: Float(cellSize + 2)
                            )
                            renderer.setDrawColor(r: 255, g: 255, b: 200, a: UInt8(flashAlpha / 3))
                            renderer.fillRect(glowRect)
                            
                            // Inner glow (medium)
                            glowRect = Rect(
                                x: Float(pixelX) - 1,
                                y: Float(pixelY) - 1,
                                width: Float(cellSize),
                                height: Float(cellSize)
                            )
                            renderer.setDrawColor(r: 255, g: 255, b: 150, a: UInt8(flashAlpha / 2))
                            renderer.fillRect(glowRect)
                            
                            // Core flash (bright yellow-white) - reuse flashRect from above
                            renderer.setDrawColor(r: 255, g: 255, b: 200, a: flashAlpha)
                            renderer.fillRect(flashRect)
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
            let rect = Rect(x: Float(blockX), y: Float(blockY), width: Float(cellSize - 2), height: Float(cellSize - 2))
            let color = getColor(engine.nextPiece.type.color)
            renderer.setDrawColor(r: color.r, g: color.g, b: color.b, a: 255)
            renderer.fillRect(rect)
            
            // Border
            renderer.setDrawColor(r: 255, g: 255, b: 255, a: 100)
            renderer.drawRect(rect)
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
            let rect = Rect(x: Float(blockX), y: Float(blockY), width: Float(smallCellSize - 1), height: Float(smallCellSize - 1))
            let color = getColor(engine.nextNextPiece.type.color)
            renderer.setDrawColor(r: color.r, g: color.g, b: color.b, a: 255)
            renderer.fillRect(rect)
            
            // Border (thinner for smaller piece)
            renderer.setDrawColor(r: 255, g: 255, b: 255, a: 80)
            renderer.drawRect(rect)
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
            let borderRect = Rect(x: boxX - 4, y: boxY - 4, width: boxWidth + 8, height: boxHeight + 8)
            renderer.setDrawColor(r: 0, g: 0, b: 0, a: 200) // Dark border
            renderer.fillRect(borderRect)
            
            // Draw inner box
            let boxRect = Rect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)
            renderer.setDrawColor(r: 30, g: 30, b: 40, a: 240) // Dark background
            renderer.fillRect(boxRect)
            
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
        
        // Present the rendered frame
        self.renderer?.present()
    }
    
    private func drawBlock(x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32) {
        drawBlockWithAlpha(x: x, y: y, type: type, boardX: boardX, boardY: boardY, alpha: 255)
    }
    
    private func drawBlockWithAlpha(x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32, alpha: UInt8) {
        guard let renderer = renderer else { return }
        let pixelX = boardX + Int32(x) * cellSize
        let pixelY = boardY + Int32(y) * cellSize
        let rect = Rect(x: Float(pixelX), y: Float(pixelY), width: Float(cellSize - 2), height: Float(cellSize - 2))
        
        let color = getColor(type.color)
        renderer.setDrawColor(r: color.r, g: color.g, b: color.b, a: alpha)
        renderer.fillRect(rect)
        
        // Highlight border (also fade with alpha)
        renderer.setDrawColor(r: 255, g: 255, b: 255, a: UInt8((UInt16(alpha) * 100) / 255))
        renderer.drawRect(rect)
    }
    
    private func drawGhostBlock(x: Int, y: Int, type: TetrominoType, boardX: Int32, boardY: Int32) {
        guard let renderer = renderer else { return }
        let pixelX = boardX + Int32(x) * cellSize
        let pixelY = boardY + Int32(y) * cellSize
        let rect = Rect(x: Float(pixelX), y: Float(pixelY), width: Float(cellSize - 2), height: Float(cellSize - 2))
        
        // Draw ghost piece as outline only (no fill, just border)
        let color = getColor(type.color)
        // Use a semi-transparent border color
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
    
    private func drawText(x: Int32, y: Int32, text: String, r: UInt8, g: UInt8, b: UInt8) {
        guard let textRenderer = textRenderer else { return }
        textRenderer.drawText(text, at: x, y: y, color: (r: r, g: g, b: b))
    }
}
