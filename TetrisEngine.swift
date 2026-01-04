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
    var score: Int = 0
    var linesCleared: Int = 0
    var level: Int = 1
    var gameState: GameState = .playing
    
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
        spawnNextPiece()
    }
    
    func spawnNextPiece() {
        currentPiece = nextPiece
        let nextType = TetrominoType.allCases.randomElement()!
        nextPiece = Tetromino(type: nextType, position: Position(x: GameBoard.width / 2 - 1, y: 0))
        
        // Check if game is over
        if let piece = currentPiece, !board.canPlace(piece) {
            gameState = .gameOver
        }
    }
    
    func moveLeft() {
        guard let piece = currentPiece, gameState == .playing else { return }
        let moved = piece.moved(dx: -1, dy: 0)
        if board.canPlace(moved) {
            currentPiece = moved
        }
    }
    
    func moveRight() {
        guard let piece = currentPiece, gameState == .playing else { return }
        let moved = piece.moved(dx: 1, dy: 0)
        if board.canPlace(moved) {
            currentPiece = moved
        }
    }
    
    func moveDown() -> Bool {
        guard let piece = currentPiece, gameState == .playing else { return false }
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
        guard let piece = currentPiece, gameState == .playing else { return }
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
    
    func hardDrop() {
        guard let piece = currentPiece, gameState == .playing else { return }
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
        
        // Clear lines and update score
        let cleared = board.clearLines()
        if cleared > 0 {
            linesCleared += cleared
            let points = [0, 100, 300, 500, 800][min(cleared, 4)]
            score += points * level
            level = (linesCleared / 10) + 1
        }
        
        spawnNextPiece()
        lastDropTime = Date()
    }
    
    func update() {
        guard gameState == .playing else { return }
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
        spawnNextPiece()
        lastDropTime = Date()
    }
}
