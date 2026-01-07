import Foundation
import SwiftSDL

/// Tetris-specific game engine implementation
class TetrisGameEngine: GameEngine {
    private let tetrisEngine: TetrisEngine
    
    init(engine: TetrisEngine? = nil) {
        tetrisEngine = engine ?? TetrisEngine()
    }
    
    func update() {
        tetrisEngine.update()
        tetrisEngine.updateLineClearing()
    }
    
    var gameState: SwiftSDL.GameState {
        // Map Tetris GameState to SwiftSDL GameState
        switch tetrisEngine.gameState {
        case .playing:
            return .playing
        case .paused:
            return .paused
        case .gameOver:
            return .gameOver
        }
    }
    
    // Expose TetrisEngine properties and methods needed by renderer/input handler
    var engine: TetrisEngine {
        return tetrisEngine
    }
}
