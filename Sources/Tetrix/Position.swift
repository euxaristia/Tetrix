import Foundation

struct Position: Equatable, Hashable {
    let x: Int
    let y: Int
    
    func translated(by dx: Int, dy: Int) -> Position {
        return Position(x: x + dx, y: y + dy)
    }
}
