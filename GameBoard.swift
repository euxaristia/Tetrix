import Foundation

struct GameBoard {
    static let width = 10
    static let height = 20
    
    private var grid: [[TetrominoType?]]
    
    init() {
        grid = Array(repeating: Array(repeating: nil, count: GameBoard.width), count: GameBoard.height)
    }
    
    func isPositionValid(_ position: Position) -> Bool {
        return position.x >= 0 && position.x < GameBoard.width &&
               position.y >= 0 && position.y < GameBoard.height
    }
    
    func isCellEmpty(_ position: Position) -> Bool {
        guard isPositionValid(position) else { return false }
        return grid[position.y][position.x] == nil
    }
    
    func canPlace(_ tetromino: Tetromino) -> Bool {
        let blocks = tetromino.getAbsoluteBlocks()
        // Allow blocks above the board (y < 0) - pieces can spawn partially above
        // Only check blocks that are within or below the board bounds
        return blocks.allSatisfy { block in
            if block.y < 0 {
                // Block is above the board - this is allowed for spawning
                return true
            } else {
                // Block is within board bounds - must be valid and empty
                return isPositionValid(block) && isCellEmpty(block)
            }
        }
    }
    
    mutating func place(_ tetromino: Tetromino) {
        let blocks = tetromino.getAbsoluteBlocks()
        for block in blocks {
            if isPositionValid(block) {
                grid[block.y][block.x] = tetromino.type
            }
        }
    }
    
    mutating func clearLines() -> Int {
        var linesCleared = 0
        var newGrid: [[TetrominoType?]] = []
        
        for row in grid.reversed() {
            if row.allSatisfy({ $0 != nil }) {
                linesCleared += 1
            } else {
                newGrid.append(row)
            }
        }
        
        // Add empty rows at the top
        while newGrid.count < GameBoard.height {
            newGrid.append(Array(repeating: nil, count: GameBoard.width))
        }
        
        grid = newGrid.reversed()
        return linesCleared
    }
    
    // Get which lines are full (for animation before clearing)
    func getFullLines() -> [Int] {
        var fullLines: [Int] = []
        for y in 0..<GameBoard.height {
            if grid[y].allSatisfy({ $0 != nil }) {
                fullLines.append(y)
            }
        }
        return fullLines
    }
    
    func getCell(at position: Position) -> TetrominoType? {
        guard isPositionValid(position) else { return nil }
        return grid[position.y][position.x]
    }
    
    func getAllCells() -> [[TetrominoType?]] {
        return grid
    }
}
