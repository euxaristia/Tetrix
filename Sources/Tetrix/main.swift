import Foundation
import SwiftSDL

// Calculate logical window size for Tetris board
let cellSize: Int32 = 30
let boardWidth = GameBoard.width
let boardHeight = GameBoard.height
let boardPixelWidth = Int32(boardWidth) * cellSize
let boardPixelHeight = Int32(boardHeight) * cellSize
let sidePanelWidth: Int32 = 200
let logicalWidth = boardPixelWidth + sidePanelWidth + 40 // 40 for padding (20 on each side)
let logicalHeight = boardPixelHeight + 40 // 40 for padding (20 on top and bottom)

// Create Tetris game components
let tetrisEngine = TetrisEngine()
let gameEngine = TetrisGameEngine(engine: tetrisEngine)
let gameRenderer = TetrisGameRenderer(engine: tetrisEngine, logicalWidth: logicalWidth, logicalHeight: logicalHeight)
let music = TetrisMusic()

// Create input handler with callbacks
let inputHandler = TetrisInputHandler(
    engine: tetrisEngine,
    music: music,
    onMusicStart: { music.start() },
    onMusicStop: { music.stop() },
    onToggleFullscreen: { /* Will be set on game */ },
    onToggleMusic: { /* Will be set on game */ }
)

// Create game configuration
let config = GameConfig(
    title: "Tetrix",
    logicalWidth: logicalWidth,
    logicalHeight: logicalHeight,
    resolutionScale: 2,
    targetFPS: 180.0
)

// Create and run the game
let game = SDL3Game(
    config: config,
    engine: gameEngine,
    renderer: gameRenderer,
    inputHandler: inputHandler
)

// Set up music callbacks
game.onMusicStart = { music.start() }
game.onMusicStop = { music.stop() }
game.onMusicUpdate = { music.update() }

// Set up input handler callbacks (need access to game instance)
// We need to update the input handler after game is created
// For now, we'll use closures in the handler

// Load settings for initial state
let settingsManager = SettingsManager.shared
let settings = settingsManager.loadSettings()

if settings.musicEnabled {
    game.onMusicStart?()
}

if settings.isFullscreen {
    game.toggleFullscreen()
}

// Hook up toggle callbacks after game is created
inputHandler.setToggleFullscreen { game.toggleFullscreen() }
inputHandler.setToggleMusic { game.toggleMusic() }

// Start the game loop
game.run()
