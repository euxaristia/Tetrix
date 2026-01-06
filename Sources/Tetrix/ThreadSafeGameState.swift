import Foundation

/// Thread-safe game state manager using locks for safe concurrent access
/// This allows multiple threads to read/write game state without data races
class ThreadSafeGameState {
    // Thread pool configuration - up to 20 cores
    static let maxConcurrency = min(20, ProcessInfo.processInfo.processorCount)
    
    // Thread safety
    private let stateLock = NSLock()
    
    // Game state (accessed safely via actor)
    private var engine: TetrisEngine
    private var currentInputs: Set<InputCommand> = []
    private var inputQueue: [InputCommand] = []
    
    // Thread-safe rendering state snapshots
    private var renderSnapshot: GameRenderSnapshot?
    
    init() {
        self.engine = TetrisEngine()
    }
    
    /// Process pending input commands atomically
    func processInputs() {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard !inputQueue.isEmpty else { return }
        
        // Process all queued inputs
        for command in inputQueue {
            processCommand(command)
        }
        
        // Clear queue after processing
        inputQueue.removeAll()
    }
    
    /// Queue an input command to be processed on the next game update
    func queueInput(_ command: InputCommand) {
        stateLock.lock()
        defer { stateLock.unlock() }
        inputQueue.append(command)
    }
    
    /// Get current render snapshot (safe for reading from render thread)
    func getRenderSnapshot() -> GameRenderSnapshot {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        // Update snapshot with current state
        renderSnapshot = GameRenderSnapshot(
            board: engine.board.getAllCells(),
            currentPiece: engine.currentPiece,
            nextPiece: engine.nextPiece,
            nextNextPiece: engine.nextNextPiece,
            score: engine.score,
            linesCleared: engine.linesCleared,
            level: engine.level,
            gameState: engine.gameState,
            linesToClear: engine.linesToClear,
            lineClearStartTime: engine.lineClearStartTime
        )
        return renderSnapshot!
    }
    
    /// Update game logic (called from game update thread)
    /// Processes inputs immediately for maximum responsiveness
    func updateGame(dropInterval: TimeInterval, currentTime: Date) {
        stateLock.lock()
        
        // Process queued inputs first (while holding lock)
        let commands = inputQueue
        inputQueue.removeAll()
        stateLock.unlock()
        
        // Process inputs immediately (outside lock to minimize lock time)
        for command in commands {
            stateLock.lock()
            processCommand(command)
            stateLock.unlock()
        }
        
        // Then update game logic
        stateLock.lock()
        engine.updateLineClearing()
        if engine.gameState == .playing && engine.linesToClear.isEmpty {
            engine.update()
        }
        stateLock.unlock()
    }
    
    /// Execute a command on the game engine (must be called with lock held)
    private func processCommand(_ command: InputCommand) {
        switch command {
        case .moveLeft:
            engine.moveLeft()
        case .moveRight:
            engine.moveRight()
        case .moveDown:
            _ = engine.moveDown()
        case .rotate:
            engine.rotate()
        case .hardDrop:
            engine.hardDrop()
        case .pause:
            engine.pause()
        case .reset:
            engine.reset()
        }
    }
    
    /// Direct access methods (safe via lock)
    func getEngine() -> TetrisEngine {
        stateLock.lock()
        defer { stateLock.unlock() }
        return engine
    }
    
    func setEngine(_ newEngine: TetrisEngine) {
        stateLock.lock()
        defer { stateLock.unlock() }
        engine = newEngine
    }
    
    func getGhostPiece() -> Tetromino? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return engine.getGhostPiece()
    }
    
    func getDropInterval() -> TimeInterval {
        stateLock.lock()
        defer { stateLock.unlock() }
        let baseInterval: TimeInterval = 1.0
        let minInterval: TimeInterval = 0.1
        let levelFactor = Double(min(engine.level, 10))
        return max(minInterval, baseInterval - (levelFactor * 0.09))
    }
    
    /// Thread-safe access to game state properties
    var score: Int {
        stateLock.lock()
        defer { stateLock.unlock() }
        return engine.score
    }
    
    var highScore: Int = 0 {
        didSet {
            stateLock.lock()
            defer { stateLock.unlock() }
            if engine.score > highScore {
                highScore = engine.score
            }
        }
    }
}

/// Input commands that can be queued from input thread
enum InputCommand {
    case moveLeft
    case moveRight
    case moveDown
    case rotate
    case hardDrop
    case pause
    case reset
}

/// Immutable snapshot of game state for rendering
struct GameRenderSnapshot {
    let board: [[TetrominoType?]]
    let currentPiece: Tetromino?
    let nextPiece: Tetromino
    let nextNextPiece: Tetromino
    let score: Int
    let linesCleared: Int
    let level: Int
    let gameState: GameState
    let linesToClear: [Int]
    let lineClearStartTime: Date?
}

/// Thread pool manager for parallel operations
class ThreadPoolManager {
    static let shared = ThreadPoolManager()
    
    // Concurrent queue for parallel rendering operations
    let renderQueue: DispatchQueue
    
    // Serial queue for game logic updates
    let gameLogicQueue: DispatchQueue
    
    // Serial queue for input processing
    let inputQueue: DispatchQueue
    
    private init() {
        let maxThreads = ThreadSafeGameState.maxConcurrency
        
        // Create concurrent queue for rendering (allows parallel block drawing)
        renderQueue = DispatchQueue(
            label: "com.tetrix.render",
            attributes: .concurrent
        )
        
        // Create serial queue for game logic (must be sequential)
        gameLogicQueue = DispatchQueue(
            label: "com.tetrix.gamelogic",
            qos: .userInteractive
        )
        
        // Create high-priority serial queue for input (critical for responsiveness)
        inputQueue = DispatchQueue(
            label: "com.tetrix.input",
            qos: .userInteractive,
            attributes: []
        )
        
        print("Thread pool initialized with \(maxThreads) max concurrent threads")
    }
    
    /// Thread-safe container for parallel operation results
    private final class ResultsContainer<T>: @unchecked Sendable {
        private let lock = NSLock()
        private var results: [T?]
        
        init(count: Int) {
            self.results = Array<T?>(repeating: nil, count: count)
        }
        
        func set(_ value: T, at index: Int) {
            lock.lock()
            defer { lock.unlock() }
            results[index] = value
        }
        
        func getAll() -> [T] {
            lock.lock()
            defer { lock.unlock() }
            return results.compactMap { $0 }
        }
    }
    
    /// Execute parallel rendering operations
    func parallelRender<T>(_ operations: [() -> T], completion: @escaping ([T]) -> Void) {
        let group = DispatchGroup()
        let resultsContainer = ResultsContainer<T>(count: operations.count)
        
        for (index, operation) in operations.enumerated() {
            renderQueue.async(group: group) {
                let result = operation()
                resultsContainer.set(result, at: index)
            }
        }
        
        group.notify(queue: .main) {
            let finalResults = resultsContainer.getAll()
            completion(finalResults)
        }
    }
}
