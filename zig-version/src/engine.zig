const std = @import("std");
const tetromino = @import("tetromino.zig");
const board = @import("board.zig");

const Position = tetromino.Position;
const Tetromino = tetromino.Tetromino;
const TetrominoType = tetromino.TetrominoType;
const GameBoard = board.GameBoard;
const BOARD_WIDTH = board.BOARD_WIDTH;
const BOARD_HEIGHT = board.BOARD_HEIGHT;

pub const GameState = enum {
    playing,
    paused,
    game_over,
};

pub const TetrisEngine = struct {
    game_board: GameBoard,
    current_piece: ?Tetromino,
    next_piece: TetrominoType,
    next_next_piece: TetrominoType,
    state: GameState,
    score: u32,
    high_score: u32,
    lines_cleared: u32,
    level: u32,
    drop_timer: f64,
    drop_interval: f64,
    rng: std.Random,
    pending_lines: u32, // Lines waiting to be scored after animation

    const SPAWN_X: i32 = 4;
    const SPAWN_Y: i32 = 0;
    const BASE_DROP_INTERVAL: f64 = 1.0;
    const MIN_DROP_INTERVAL: f64 = 0.1;

    pub fn init(seed: u64) TetrisEngine {
        var prng = std.Random.DefaultPrng.init(seed);
        var rng = prng.random();

        var engine = TetrisEngine{
            .game_board = GameBoard.init(),
            .current_piece = null,
            .next_piece = TetrominoType.random(&rng),
            .next_next_piece = TetrominoType.random(&rng),
            .state = .playing,
            .score = 0,
            .high_score = 0,
            .lines_cleared = 0,
            .level = 1,
            .drop_timer = 0,
            .drop_interval = BASE_DROP_INTERVAL,
            .rng = rng,
            .pending_lines = 0,
        };

        engine.spawnNewPiece();
        return engine;
    }

    pub fn reset(self: *TetrisEngine) void {
        self.game_board.reset();
        self.current_piece = null;
        self.next_piece = TetrominoType.random(&self.rng);
        self.next_next_piece = TetrominoType.random(&self.rng);
        self.state = .playing;
        self.score = 0;
        self.lines_cleared = 0;
        self.level = 1;
        self.drop_timer = 0;
        self.drop_interval = BASE_DROP_INTERVAL;
        self.pending_lines = 0;
        self.spawnNewPiece();
    }

    pub fn update(self: *TetrisEngine, delta_time: f64) void {
        if (self.state != .playing) {
            return;
        }

        // Update line clearing animation
        if (self.game_board.is_clearing) {
            const animation_complete = self.game_board.updateAnimation(delta_time);
            if (animation_complete) {
                // Apply pending score
                self.applyLineScore(self.pending_lines);
                self.pending_lines = 0;
                self.spawnNewPiece();
            }
            return;
        }

        // Update drop timer
        self.drop_timer += delta_time;
        if (self.drop_timer >= self.drop_interval) {
            self.drop_timer = 0;
            if (!self.moveDown()) {
                self.lockPiece();
            }
        }
    }

    fn spawnNewPiece(self: *TetrisEngine) void {
        const new_piece = Tetromino.init(self.next_piece, SPAWN_X, SPAWN_Y);

        if (!self.game_board.canPlace(new_piece)) {
            self.state = .game_over;
            self.current_piece = null;
            return;
        }

        self.current_piece = new_piece;
        self.next_piece = self.next_next_piece;
        self.next_next_piece = TetrominoType.random(&self.rng);
    }

    fn lockPiece(self: *TetrisEngine) void {
        if (self.current_piece) |piece| {
            self.game_board.placePiece(piece);
            self.current_piece = null;

            // Check for lines to clear
            const lines = self.game_board.checkLines();
            if (lines > 0) {
                self.pending_lines = lines;
                // Don't spawn new piece yet, wait for animation
            } else {
                self.spawnNewPiece();
            }
        }
    }

    fn applyLineScore(self: *TetrisEngine, lines: u32) void {
        self.lines_cleared += lines;

        // Calculate score based on lines cleared
        const points: u32 = switch (lines) {
            1 => 100 * self.level,
            2 => 300 * self.level,
            3 => 500 * self.level,
            4 => 800 * self.level,
            else => 0,
        };
        self.score += points;

        // Update high score
        if (self.score > self.high_score) {
            self.high_score = self.score;
        }

        // Update level
        self.level = (self.lines_cleared / 10) + 1;
        self.updateDropInterval();
    }

    fn updateDropInterval(self: *TetrisEngine) void {
        const level_factor = @min(self.level, 10);
        const factor: f64 = @as(f64, @floatFromInt(level_factor)) * 0.09;
        self.drop_interval = @max(MIN_DROP_INTERVAL, BASE_DROP_INTERVAL - factor);
    }

    // Movement functions
    pub fn moveLeft(self: *TetrisEngine) bool {
        if (self.state != .playing or self.game_board.is_clearing) return false;
        if (self.current_piece) |piece| {
            const new_piece = piece.moved(-1, 0);
            if (self.game_board.canPlace(new_piece)) {
                self.current_piece = new_piece;
                return true;
            }
        }
        return false;
    }

    pub fn moveRight(self: *TetrisEngine) bool {
        if (self.state != .playing or self.game_board.is_clearing) return false;
        if (self.current_piece) |piece| {
            const new_piece = piece.moved(1, 0);
            if (self.game_board.canPlace(new_piece)) {
                self.current_piece = new_piece;
                return true;
            }
        }
        return false;
    }

    pub fn moveDown(self: *TetrisEngine) bool {
        if (self.state != .playing or self.game_board.is_clearing) return false;
        if (self.current_piece) |piece| {
            const new_piece = piece.moved(0, 1);
            if (self.game_board.canPlace(new_piece)) {
                self.current_piece = new_piece;
                return true;
            }
        }
        return false;
    }

    pub fn rotate(self: *TetrisEngine) bool {
        if (self.state != .playing or self.game_board.is_clearing) return false;
        if (self.current_piece) |piece| {
            var new_piece = piece.rotated();

            // Try direct rotation
            if (self.game_board.canPlace(new_piece)) {
                self.current_piece = new_piece;
                return true;
            }

            // Wall kick offsets to try
            const wall_kicks = [_]i32{ -1, 1, -2, 2 };
            for (wall_kicks) |offset| {
                const kicked = new_piece.moved(offset, 0);
                if (self.game_board.canPlace(kicked)) {
                    self.current_piece = kicked;
                    return true;
                }
            }
        }
        return false;
    }

    pub fn hardDrop(self: *TetrisEngine) u32 {
        if (self.state != .playing or self.game_board.is_clearing) return 0;
        if (self.current_piece) |piece| {
            var cells_dropped: u32 = 0;
            var new_piece = piece;
            while (self.game_board.canPlace(new_piece.moved(0, 1))) {
                new_piece = new_piece.moved(0, 1);
                cells_dropped += 1;
            }
            self.current_piece = new_piece;

            // Add hard drop bonus
            self.score += cells_dropped * 2;
            if (self.score > self.high_score) {
                self.high_score = self.score;
            }

            self.lockPiece();
            self.drop_timer = 0;
            return cells_dropped;
        }
        return 0;
    }

    pub fn softDrop(self: *TetrisEngine) bool {
        if (self.moveDown()) {
            self.drop_timer = 0;
            return true;
        }
        return false;
    }

    pub fn pause(self: *TetrisEngine) void {
        if (self.state == .playing) {
            self.state = .paused;
        }
    }

    pub fn resume_game(self: *TetrisEngine) void {
        if (self.state == .paused) {
            self.state = .playing;
        }
    }

    pub fn togglePause(self: *TetrisEngine) void {
        if (self.state == .playing) {
            self.pause();
        } else if (self.state == .paused) {
            self.resume_game();
        }
    }

    pub fn getGhostPiece(self: *const TetrisEngine) ?Tetromino {
        if (self.current_piece) |piece| {
            return self.game_board.getGhostPosition(piece);
        }
        return null;
    }

    pub fn setHighScore(self: *TetrisEngine, score: u32) void {
        self.high_score = score;
    }
};
