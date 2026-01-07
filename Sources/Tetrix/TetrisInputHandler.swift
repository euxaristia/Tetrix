import Foundation
import SwiftSDL

/// Tetris-specific input handler implementation
class TetrisInputHandler: GameInputHandler {
    private weak var engine: TetrisEngine?
    private weak var music: TetrisMusic?
    private var onMusicStart: (() -> Void)?
    private var onMusicStop: (() -> Void)?
    private var onToggleFullscreen: (() -> Void)?
    private var onToggleMusic: (() -> Void)?
    
    // Allow updating callbacks after initialization
    func setToggleFullscreen(_ closure: @escaping () -> Void) {
        onToggleFullscreen = closure
    }
    
    func setToggleMusic(_ closure: @escaping () -> Void) {
        onToggleMusic = closure
    }
    
    // Key/gamepad repeat state
    private var dPadDownHeld = false
    private var dPadDownRepeatTimer: TimeInterval = 0
    private let dPadDownRepeatInterval: TimeInterval = 0.025
    private let dPadDownInitialDelay: TimeInterval = 0.12
    private var dPadLeftHeld = false
    private var dPadLeftRepeatTimer: TimeInterval = 0
    private var dPadRightHeld = false
    private var dPadRightRepeatTimer: TimeInterval = 0
    private let dPadHorizontalRepeatInterval: TimeInterval = 0.03
    private let dPadHorizontalInitialDelay: TimeInterval = 0.15
    private var downKeyHeld = false
    private var downKeyRepeatTimer: TimeInterval = 0
    private let downKeyRepeatInterval: TimeInterval = 0.02
    private let downKeyInitialDelay: TimeInterval = 0.12
    private var lastDropTime: TimeInterval = 0
    private var musicEnabled = true
    
    init(engine: TetrisEngine, music: TetrisMusic?,
         onMusicStart: @escaping () -> Void,
         onMusicStop: @escaping () -> Void,
         onToggleFullscreen: @escaping () -> Void,
         onToggleMusic: @escaping () -> Void) {
        self.engine = engine
        self.music = music
        self.onMusicStart = onMusicStart
        self.onMusicStop = onMusicStop
        self.onToggleFullscreen = onToggleFullscreen
        self.onToggleMusic = onToggleMusic
        self.lastDropTime = getCurrentTime()
        
        // Load music enabled setting
        let settingsManager = SettingsManager.shared
        let settings = settingsManager.loadSettings()
        musicEnabled = settings.musicEnabled
    }
    
    private func getCurrentTime() -> TimeInterval {
        #if os(Linux)
        var ts = timespec()
        clock_gettime(CLOCK_MONOTONIC, &ts)
        return TimeInterval(ts.tv_sec) + TimeInterval(ts.tv_nsec) / 1_000_000_000.0
        #elseif os(macOS)
        return CFAbsoluteTimeGetCurrent()
        #else
        return Date().timeIntervalSince1970
        #endif
    }
    
    private func getDropInterval() -> TimeInterval {
        guard let engine = engine else { return 1.0 }
        let baseInterval: TimeInterval = 1.0
        let minInterval: TimeInterval = 0.1
        let levelFactor = Double(min(engine.level, 10))
        return max(minInterval, baseInterval - (levelFactor * 0.09))
    }
    
    func handleKeyPress(_ keyCode: KeyCode, isRepeat: Bool) {
        guard let engine = engine else { return }
        
        switch keyCode {
        case .a, .left:
            engine.moveLeft()
        case .d, .right:
            engine.moveRight()
        case .s, .down:
            if !downKeyHeld {
                downKeyHeld = true
                let now = getCurrentTime()
                downKeyRepeatTimer = now + downKeyInitialDelay
                let couldMove = engine.moveDown()
                if !couldMove {
                    downKeyRepeatTimer = now + downKeyInitialDelay + 0.08
                    let dropInterval = getDropInterval()
                    lastDropTime = now - dropInterval * 0.5
                }
            }
        case .w, .up:
            engine.rotate()
        case .space:
            engine.hardDrop()
        case .escape:
            if !isRepeat {
                engine.pause()
                if engine.gameState == .playing && musicEnabled {
                    onMusicStart?()
                } else if engine.gameState == .paused {
                    onMusicStop?()
                }
            }
        case .r:
            if engine.gameState == .gameOver {
                engine.reset()
            }
        case .f11:
            if !isRepeat {
                onToggleFullscreen?()
            }
        case .m:
            if !isRepeat {
                // Toggle music via game (which handles the musicEnabled flag and callbacks)
                onToggleMusic?()
                // Update our local flag and save settings
                musicEnabled.toggle()
                let settingsManager = SettingsManager.shared
                var settings = settingsManager.loadSettings()
                settings.musicEnabled = musicEnabled
                settingsManager.saveSettings(settings)
            }
        default:
            break
        }
    }
    
    func handleKeyRelease(_ keyCode: KeyCode) {
        switch keyCode {
        case .s, .down:
            downKeyHeld = false
        default:
            break
        }
    }
    
    func handleGamepadButtonDown(_ button: UInt32) {
        guard let engine = engine else { return }
        let now = getCurrentTime()
        
        switch button {
        case 11: // SDL_GAMEPAD_BUTTON_DPAD_UP
            engine.rotate()
        case 13: // SDL_GAMEPAD_BUTTON_DPAD_LEFT
            dPadLeftHeld = true
            dPadLeftRepeatTimer = now + dPadHorizontalInitialDelay
            engine.moveLeft()
        case 14: // SDL_GAMEPAD_BUTTON_DPAD_RIGHT
            dPadRightHeld = true
            dPadRightRepeatTimer = now + dPadHorizontalInitialDelay
            engine.moveRight()
        case 12: // SDL_GAMEPAD_BUTTON_DPAD_DOWN
            dPadDownHeld = true
            dPadDownRepeatTimer = now + dPadDownInitialDelay
            let couldMove = engine.moveDown()
            if !couldMove {
                dPadDownRepeatTimer = now + dPadDownInitialDelay + 0.08
                let dropInterval = getDropInterval()
                lastDropTime = now - dropInterval * 0.5
            }
        case 0: // SDL_GAMEPAD_BUTTON_A
            engine.rotate()
        case 6: // SDL_GAMEPAD_BUTTON_START
            engine.pause()
            if engine.gameState == .playing && musicEnabled {
                onMusicStart?()
            } else if engine.gameState == .paused {
                onMusicStop?()
            }
        case 4: // SDL_GAMEPAD_BUTTON_BACK
            if engine.gameState == .gameOver {
                engine.reset()
            }
        default:
            break
        }
    }
    
    func handleGamepadButtonUp(_ button: UInt32) {
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
    
    func handleDPadDownRepeat(now: TimeInterval) {
        guard dPadDownHeld, let engine = engine else { return }
        let timeSinceLastAction = now - dPadDownRepeatTimer
        
        if timeSinceLastAction >= 0 {
            if timeSinceLastAction >= dPadDownRepeatInterval {
                let couldMove = engine.moveDown()
                dPadDownRepeatTimer = now
                if !couldMove {
                    dPadDownRepeatTimer = now + dPadDownInitialDelay + 0.08
                    let dropInterval = getDropInterval()
                    lastDropTime = now - dropInterval * 0.5
                }
            }
        }
    }
    
    func handleDPadHorizontalRepeat(now: TimeInterval) {
        guard let engine = engine else { return }
        
        if dPadLeftHeld {
            let timeSinceLastAction = now - dPadLeftRepeatTimer
            if timeSinceLastAction >= dPadHorizontalRepeatInterval {
                engine.moveLeft()
                dPadLeftRepeatTimer = now
            }
        }
        
        if dPadRightHeld {
            let timeSinceLastAction = now - dPadRightRepeatTimer
            if timeSinceLastAction >= dPadHorizontalRepeatInterval {
                engine.moveRight()
                dPadRightRepeatTimer = now
            }
        }
    }
    
    func handleDownKeyRepeat(now: TimeInterval) {
        guard downKeyHeld, let engine = engine else { return }
        let timeSinceLastAction = now - downKeyRepeatTimer
        
        if timeSinceLastAction >= 0 {
            if timeSinceLastAction >= downKeyRepeatInterval {
                let couldMove = engine.moveDown()
                downKeyRepeatTimer = now
                if !couldMove {
                    downKeyRepeatTimer = now + downKeyInitialDelay + 0.08
                    let dropInterval = getDropInterval()
                    lastDropTime = now - dropInterval * 0.5
                }
            }
        }
    }
}

#if os(Linux)
import Glibc
#endif
