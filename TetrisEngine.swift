import Foundation

enum GameState {
    case playing
    case gameOver
    case paused
}

class TetrisEngine {
    var board: GameBoard
    var currentPiece: Tetromino?
    var nextPiece: Tetromino
    var nextNextPiece: Tetromino
    var score: Int = 0
    var linesCleared: Int = 0
    var level: Int = 1
    var gameState: GameState = .playing
    
    // Line clearing animation state
    var linesToClear: [Int] = []
    var lineClearStartTime: Date?
    let lineClearFlashDuration: TimeInterval = 0.3 // Flash for 0.3 seconds
    let lineClearTotalDuration: TimeInterval = 0.5 // Total animation duration
    
    private var lastDropTime: Date = Date()
    private var dropInterval: TimeInterval {
        // Speed increases with level
        let baseInterval: TimeInterval = 1.0
        let minInterval: TimeInterval = 0.1
        let levelFactor = Double(min(level, 10))
        return max(minInterval, baseInterval - (levelFactor * 0.09))
    }
    
    init() {
        board = GameBoard()
        nextPiece = Tetromino(type: TetrominoType.allCases.randomElement()!, position: Position(x: GameBoard.width / 2 - 1, y: 0))
        nextNextPiece = Tetromino(type: TetrominoType.allCases.randomElement()!, position: Position(x: GameBoard.width / 2 - 1, y: 0))
        spawnNextPiece()
    }
    
    func spawnNextPiece() {
        currentPiece = nextPiece
        nextPiece = nextNextPiece
        let nextType = TetrominoType.allCases.randomElement()!
        nextNextPiece = Tetromino(type: nextType, position: Position(x: GameBoard.width / 2 - 1, y: 0))
        
        // Check if game is over
        if let piece = currentPiece, !board.canPlace(piece) {
            gameState = .gameOver
        }
    }
    
    func moveLeft() {
        guard let piece = currentPiece, gameState == .playing, linesToClear.isEmpty else { return }
        let moved = piece.moved(dx: -1, dy: 0)
        if board.canPlace(moved) {
            currentPiece = moved
        }
    }
    
    func moveRight() {
        guard let piece = currentPiece, gameState == .playing, linesToClear.isEmpty else { return }
        let moved = piece.moved(dx: 1, dy: 0)
        if board.canPlace(moved) {
            currentPiece = moved
        }
    }
    
    func moveDown() -> Bool {
        guard let piece = currentPiece, gameState == .playing, linesToClear.isEmpty else { return false }
        let moved = piece.moved(dx: 0, dy: 1)
        if board.canPlace(moved) {
            currentPiece = moved
            return true
        } else {
            // Piece can't move down, lock it in place
            lockPiece()
            return false
        }
    }
    
    func rotate() {
        guard let piece = currentPiece, gameState == .playing, linesToClear.isEmpty else { return }
        let rotated = piece.rotated(clockwise: true)
        if board.canPlace(rotated) {
            currentPiece = rotated
        } else {
            // Try wall kicks (shift left/right and try again)
            for dx in [-1, 1, -2, 2] {
                let kicked = Tetromino(type: rotated.type, position: rotated.position.translated(by: dx, dy: 0), rotation: rotated.rotation)
                if board.canPlace(kicked) {
                    currentPiece = kicked
                    return
                }
            }
        }
    }
    
    func getGhostPiece() -> Tetromino? {
        guard let piece = currentPiece, gameState == .playing, linesToClear.isEmpty else { return nil }
        var dropped = piece
        
        while board.canPlace(dropped.moved(dx: 0, dy: 1)) {
            dropped = dropped.moved(dx: 0, dy: 1)
        }
        
        return dropped
    }
    
    func hardDrop() {
        guard let piece = currentPiece, gameState == .playing, linesToClear.isEmpty else { return }
        var dropped = piece
        var dropDistance = 0
        
        while board.canPlace(dropped.moved(dx: 0, dy: 1)) {
            dropped = dropped.moved(dx: 0, dy: 1)
            dropDistance += 1
        }
        
        currentPiece = dropped
        lockPiece()
        
        // Bonus points for hard drop
        score += dropDistance * 2
    }
    
    private func lockPiece() {
        guard let piece = currentPiece else { return }
        board.place(piece)
        
        // Check for full lines and start animation
        linesToClear = board.getFullLines()
        if !linesToClear.isEmpty {
            lineClearStartTime = Date()
            // Don't clear immediately - wait for animation
            return
        }
        
        // No lines to clear, spawn next piece immediately
        spawnNextPiece()
        lastDropTime = Date()
    }
    
    func updateLineClearing() {
        guard let startTime = lineClearStartTime, !linesToClear.isEmpty else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        
        if elapsed >= lineClearTotalDuration {
            // Animation complete - actually clear the lines
            let cleared = linesToClear.count
            _ = board.clearLines() // Now actually clear them
            linesCleared += cleared
            let points = [0, 100, 300, 500, 800][min(cleared, 4)]
            score += points * level
            level = (linesCleared / 10) + 1
            
            // Reset animation state
            linesToClear = []
            lineClearStartTime = nil
            
            // Spawn next piece now that lines are cleared
            spawnNextPiece()
            lastDropTime = Date()
        }
    }
    
    func update() {
        guard gameState == .playing else { return }
        // Don't auto-drop pieces while lines are clearing
        guard linesToClear.isEmpty else { return }
        let now = Date()
        if now.timeIntervalSince(lastDropTime) >= dropInterval {
            _ = moveDown()
            lastDropTime = now
        }
    }
    
    func pause() {
        if gameState == .playing {
            gameState = .paused
        } else if gameState == .paused {
            gameState = .playing
            lastDropTime = Date()
        }
    }
    
    func reset() {
        board = GameBoard()
        score = 0
        linesCleared = 0
        level = 1
        gameState = .playing
        nextPiece = Tetromino(type: TetrominoType.allCases.randomElement()!, position: Position(x: GameBoard.width / 2 - 1, y: 0))
        nextNextPiece = Tetromino(type: TetrominoType.allCases.randomElement()!, position: Position(x: GameBoard.width / 2 - 1, y: 0))
        spawnNextPiece()
        lastDropTime = Date()
    }
}
