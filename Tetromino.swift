import Foundation

enum TetrominoType: CaseIterable {
    case I, O, T, S, Z, J, L
    
    var color: String {
        switch self {
        case .I: return "cyan"
        case .O: return "yellow"
        case .T: return "purple"
        case .S: return "green"
        case .Z: return "red"
        case .J: return "blue"
        case .L: return "orange"
        }
    }
}

struct Tetromino {
    let type: TetrominoType
    var position: Position
    var rotation: Int // 0, 1, 2, 3 for 0°, 90°, 180°, 270°
    
    init(type: TetrominoType, position: Position = Position(x: 0, y: 0), rotation: Int = 0) {
        self.type = type
        self.position = position
        self.rotation = rotation
    }
    
    // Returns the block positions relative to the piece's center
    func getBlocks() -> [Position] {
        let blocks: [[Position]]
        
        switch type {
        case .I:
            blocks = [
                [Position(x: -1, y: 0), Position(x: 0, y: 0), Position(x: 1, y: 0), Position(x: 2, y: 0)],
                [Position(x: 1, y: -1), Position(x: 1, y: 0), Position(x: 1, y: 1), Position(x: 1, y: 2)],
                [Position(x: -1, y: 1), Position(x: 0, y: 1), Position(x: 1, y: 1), Position(x: 2, y: 1)],
                [Position(x: 0, y: -1), Position(x: 0, y: 0), Position(x: 0, y: 1), Position(x: 0, y: 2)]
            ]
        case .O:
            blocks = [
                [Position(x: 0, y: 0), Position(x: 1, y: 0), Position(x: 0, y: 1), Position(x: 1, y: 1)]
            ] // O piece doesn't rotate
        case .T:
            blocks = [
                [Position(x: 0, y: 0), Position(x: -1, y: 0), Position(x: 1, y: 0), Position(x: 0, y: -1)],
                [Position(x: 0, y: 0), Position(x: 0, y: -1), Position(x: 0, y: 1), Position(x: 1, y: 0)],
                [Position(x: 0, y: 0), Position(x: -1, y: 0), Position(x: 1, y: 0), Position(x: 0, y: 1)],
                [Position(x: 0, y: 0), Position(x: 0, y: -1), Position(x: 0, y: 1), Position(x: -1, y: 0)]
            ]
        case .S:
            blocks = [
                [Position(x: 0, y: 0), Position(x: 1, y: 0), Position(x: 0, y: 1), Position(x: -1, y: 1)],
                [Position(x: 0, y: 0), Position(x: 0, y: -1), Position(x: 1, y: 0), Position(x: 1, y: 1)],
                [Position(x: 0, y: 0), Position(x: 1, y: 0), Position(x: 0, y: 1), Position(x: -1, y: 1)],
                [Position(x: 0, y: 0), Position(x: 0, y: -1), Position(x: 1, y: 0), Position(x: 1, y: 1)]
            ]
        case .Z:
            blocks = [
                [Position(x: 0, y: 0), Position(x: -1, y: 0), Position(x: 0, y: 1), Position(x: 1, y: 1)],
                [Position(x: 0, y: 0), Position(x: 1, y: -1), Position(x: 1, y: 0), Position(x: 0, y: 1)],
                [Position(x: 0, y: 0), Position(x: -1, y: 0), Position(x: 0, y: 1), Position(x: 1, y: 1)],
                [Position(x: 0, y: 0), Position(x: 1, y: -1), Position(x: 1, y: 0), Position(x: 0, y: 1)]
            ]
        case .J:
            blocks = [
                [Position(x: 0, y: 0), Position(x: -1, y: 0), Position(x: 1, y: 0), Position(x: -1, y: -1)],
                [Position(x: 0, y: 0), Position(x: 0, y: -1), Position(x: 0, y: 1), Position(x: 1, y: -1)],
                [Position(x: 0, y: 0), Position(x: -1, y: 0), Position(x: 1, y: 0), Position(x: 1, y: 1)],
                [Position(x: 0, y: 0), Position(x: 0, y: -1), Position(x: 0, y: 1), Position(x: -1, y: 1)]
            ]
        case .L:
            blocks = [
                [Position(x: 0, y: 0), Position(x: -1, y: 0), Position(x: 1, y: 0), Position(x: 1, y: -1)],
                [Position(x: 0, y: 0), Position(x: 0, y: -1), Position(x: 0, y: 1), Position(x: 1, y: 1)],
                [Position(x: 0, y: 0), Position(x: -1, y: 0), Position(x: 1, y: 0), Position(x: -1, y: 1)],
                [Position(x: 0, y: 0), Position(x: 0, y: -1), Position(x: 0, y: 1), Position(x: -1, y: -1)]
            ]
        }
        
        let rotationIndex = type == .O ? 0 : rotation % blocks.count
        return blocks[rotationIndex]
    }
    
    // Returns absolute positions of blocks on the board
    func getAbsoluteBlocks() -> [Position] {
        return getBlocks().map { block in
            Position(x: position.x + block.x, y: position.y + block.y)
        }
    }
    
    func rotated(clockwise: Bool = true) -> Tetromino {
        if type == .O {
            return self // O piece doesn't rotate
        }
        let newRotation = clockwise ? (rotation + 1) % 4 : (rotation + 3) % 4
        return Tetromino(type: type, position: position, rotation: newRotation)
    }
    
    func moved(dx: Int, dy: Int) -> Tetromino {
        return Tetromino(type: type, position: position.translated(by: dx, dy: dy), rotation: rotation)
    }
}
