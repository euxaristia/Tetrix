import SwiftUI

struct TetrisView: View {
    @StateObject private var engine = TetrisEngine()
    @State private var cellSize: CGFloat = 25
    
    var body: some View {
        VStack(spacing: 20) {
            // Score and info
            HStack {
                VStack(alignment: .leading) {
                    Text("Score: \(engine.score)")
                        .font(.headline)
                    Text("Lines: \(engine.linesCleared)")
                        .font(.subheadline)
                    Text("Level: \(engine.level)")
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Next:")
                        .font(.headline)
                    NextPieceView(piece: engine.nextPiece, cellSize: cellSize * 0.6)
                }
            }
            .padding(.horizontal)
            
            // Game board
            ZStack {
                // Board background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black)
                    .frame(width: CGFloat(GameBoard.width) * cellSize + 4,
                           height: CGFloat(GameBoard.height) * cellSize + 4)
                
                // Grid lines
                BoardGridView(width: GameBoard.width, height: GameBoard.height, cellSize: cellSize)
                
                // Placed blocks
                BoardView(board: engine.board, cellSize: cellSize)
                    .offset(x: 2, y: 2)
                
                // Current piece
                if let piece = engine.currentPiece {
                    PieceView(piece: piece, cellSize: cellSize)
                        .offset(x: 2, y: 2)
                }
            }
            
            // Controls
            VStack(spacing: 10) {
                // Rotate button
                Button(action: { engine.rotate() }) {
                    Text("Rotate")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Movement buttons
                HStack(spacing: 10) {
                    Button(action: { engine.moveLeft() }) {
                        Text("←")
                            .font(.title)
                            .frame(width: 60, height: 60)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { engine.moveDown() }) {
                        Text("↓")
                            .font(.title)
                            .frame(width: 60, height: 60)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { engine.moveRight() }) {
                        Text("→")
                            .font(.title)
                            .frame(width: 60, height: 60)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                // Hard drop button
                Button(action: { engine.hardDrop() }) {
                    Text("Hard Drop")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Pause/Resume button
                Button(action: { engine.pause() }) {
                    Text(engine.gameState == .paused ? "Resume" : "Pause")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(engine.gameState == .paused ? Color.green : Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
                
                // Reset button
                Button(action: { engine.reset() }) {
                    Text("New Game")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // Game Over overlay
            if engine.gameState == .gameOver {
                VStack {
                    Text("GAME OVER")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Final Score: \(engine.score)")
                        .font(.title2)
                        .padding(.top)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
            }
        }
        .padding()
        .onDisappear {
            engine.stopDropTimer()
        }
    }
}

struct BoardView: View {
    let board: GameBoard
    let cellSize: CGFloat
    
    var body: some View {
        let cells = board.getAllCells()
        ZStack {
            ForEach(0..<cells.count, id: \.self) { row in
                ForEach(0..<cells[row].count, id: \.self) { col in
                    if let type = cells[row][col] {
                        Rectangle()
                            .fill(Color(type.color))
                            .frame(width: cellSize - 2, height: cellSize - 2)
                            .position(x: CGFloat(col) * cellSize + cellSize / 2,
                                     y: CGFloat(row) * cellSize + cellSize / 2)
                    }
                }
            }
        }
    }
}

struct PieceView: View {
    let piece: Tetromino
    let cellSize: CGFloat
    
    var body: some View {
        let blocks = piece.getAbsoluteBlocks()
        let color = Color(piece.type.color)
        
        ZStack {
            ForEach(blocks.indices, id: \.self) { index in
                Rectangle()
                    .fill(color)
                    .frame(width: cellSize - 2, height: cellSize - 2)
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .position(x: CGFloat(blocks[index].x) * cellSize + cellSize / 2,
                             y: CGFloat(blocks[index].y) * cellSize + cellSize / 2)
            }
        }
    }
}

struct NextPieceView: View {
    let piece: Tetromino
    let cellSize: CGFloat
    
    var body: some View {
        let blocks = piece.getBlocks()
        let color = Color(piece.type.color)
        let minX = blocks.map { $0.x }.min() ?? 0
        let minY = blocks.map { $0.y }.min() ?? 0
        let maxX = blocks.map { $0.x }.max() ?? 0
        let maxY = blocks.map { $0.y }.max() ?? 0
        let width = maxX - minX + 1
        let height = maxY - minY + 1
        
        ZStack {
            ForEach(blocks.indices, id: \.self) { index in
                let block = blocks[index]
                Rectangle()
                    .fill(color)
                    .frame(width: cellSize - 1, height: cellSize - 1)
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .position(x: CGFloat(block.x - minX) * cellSize + cellSize / 2,
                             y: CGFloat(block.y - minY) * cellSize + cellSize / 2)
            }
        }
        .frame(width: CGFloat(width) * cellSize, height: CGFloat(height) * cellSize)
    }
}

struct BoardGridView: View {
    let width: Int
    let height: Int
    let cellSize: CGFloat
    
    var body: some View {
        ZStack {
            // Vertical lines
            ForEach(0...width, id: \.self) { col in
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)
                    .position(x: CGFloat(col) * cellSize + 2, y: CGFloat(height) * cellSize / 2 + 2)
            }
            
            // Horizontal lines
            ForEach(0...height, id: \.self) { row in
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .position(x: CGFloat(width) * cellSize / 2 + 2, y: CGFloat(row) * cellSize + 2)
            }
        }
    }
}

// Extension to convert color names to SwiftUI Color
extension Color {
    init(_ name: String) {
        switch name.lowercased() {
        case "cyan": self = .cyan
        case "yellow": self = .yellow
        case "purple": self = .purple
        case "green": self = .green
        case "red": self = .red
        case "blue": self = .blue
        case "orange": self = .orange
        default: self = .gray
        }
    }
}
