const std = @import("std");
const tetromino = @import("tetromino.zig");
const Position = tetromino.Position;
const Tetromino = tetromino.Tetromino;
const TetrominoType = tetromino.TetrominoType;
const Color = tetromino.Color;

pub const BOARD_WIDTH: i32 = 10;
pub const BOARD_HEIGHT: i32 = 20;

pub const Cell = struct {
    filled: bool = false,
    color: Color = .{ .r = 0, .g = 0, .b = 0 },
};

pub const GameBoard = struct {
    cells: [BOARD_HEIGHT][BOARD_WIDTH]Cell,
    clearing_lines: [BOARD_HEIGHT]bool,
    clearing_animation_time: f64,
    is_clearing: bool,

    const FLASH_DURATION: f64 = 0.35;
    const FADE_DURATION: f64 = 0.25;
    const TOTAL_ANIMATION_DURATION: f64 = FLASH_DURATION + FADE_DURATION;

    pub fn init() GameBoard {
        return .{
            .cells = [_][BOARD_WIDTH]Cell{[_]Cell{.{}} ** BOARD_WIDTH} ** BOARD_HEIGHT,
            .clearing_lines = [_]bool{false} ** BOARD_HEIGHT,
            .clearing_animation_time = 0,
            .is_clearing = false,
        };
    }

    pub fn reset(self: *GameBoard) void {
        self.* = GameBoard.init();
    }

    pub fn canPlace(self: *const GameBoard, piece: Tetromino) bool {
        const blocks = piece.getBlocks();
        for (blocks) |block| {
            // Check horizontal bounds
            if (block.x < 0 or block.x >= BOARD_WIDTH) {
                return false;
            }
            // Check if below board
            if (block.y >= BOARD_HEIGHT) {
                return false;
            }
            // Allow blocks above board (for spawning)
            if (block.y < 0) {
                continue;
            }
            // Check if cell is occupied
            if (self.cells[@intCast(block.y)][@intCast(block.x)].filled) {
                return false;
            }
        }
        return true;
    }

    pub fn placePiece(self: *GameBoard, piece: Tetromino) void {
        const blocks = piece.getBlocks();
        const color = piece.getColor();
        for (blocks) |block| {
            if (block.y >= 0 and block.y < BOARD_HEIGHT and block.x >= 0 and block.x < BOARD_WIDTH) {
                self.cells[@intCast(block.y)][@intCast(block.x)] = .{
                    .filled = true,
                    .color = color,
                };
            }
        }
    }

    pub fn checkLines(self: *GameBoard) u32 {
        var lines_to_clear: u32 = 0;

        // Reset clearing lines
        self.clearing_lines = [_]bool{false} ** BOARD_HEIGHT;

        for (0..@intCast(BOARD_HEIGHT)) |y| {
            var full = true;
            for (0..@intCast(BOARD_WIDTH)) |x| {
                if (!self.cells[y][x].filled) {
                    full = false;
                    break;
                }
            }
            if (full) {
                self.clearing_lines[y] = true;
                lines_to_clear += 1;
            }
        }

        if (lines_to_clear > 0) {
            self.is_clearing = true;
            self.clearing_animation_time = 0;
        }

        return lines_to_clear;
    }

    pub fn updateAnimation(self: *GameBoard, delta_time: f64) bool {
        if (!self.is_clearing) {
            return false;
        }

        self.clearing_animation_time += delta_time;

        if (self.clearing_animation_time >= TOTAL_ANIMATION_DURATION) {
            self.clearLines();
            self.is_clearing = false;
            self.clearing_animation_time = 0;
            return true; // Animation complete
        }

        return false; // Animation still in progress
    }

    fn clearLines(self: *GameBoard) void {
        // Remove cleared lines and shift everything down
        var write_row: i32 = BOARD_HEIGHT - 1;
        var read_row: i32 = BOARD_HEIGHT - 1;

        while (read_row >= 0) : (read_row -= 1) {
            const r: usize = @intCast(read_row);
            if (!self.clearing_lines[r]) {
                if (write_row != read_row) {
                    self.cells[@intCast(write_row)] = self.cells[r];
                }
                write_row -= 1;
            }
        }

        // Fill remaining top rows with empty cells
        while (write_row >= 0) : (write_row -= 1) {
            self.cells[@intCast(write_row)] = [_]Cell{.{}} ** BOARD_WIDTH;
        }

        // Reset clearing state
        self.clearing_lines = [_]bool{false} ** BOARD_HEIGHT;
    }

    pub fn getAnimationProgress(self: *const GameBoard) struct { phase: enum { flash, fade }, progress: f64 } {
        if (self.clearing_animation_time < FLASH_DURATION) {
            return .{ .phase = .flash, .progress = self.clearing_animation_time / FLASH_DURATION };
        } else {
            return .{ .phase = .fade, .progress = (self.clearing_animation_time - FLASH_DURATION) / FADE_DURATION };
        }
    }

    pub fn getGhostPosition(self: *const GameBoard, piece: Tetromino) Tetromino {
        var ghost = piece;
        while (self.canPlace(ghost.moved(0, 1))) {
            ghost = ghost.moved(0, 1);
        }
        return ghost;
    }

    pub fn isClearingLine(self: *const GameBoard, y: usize) bool {
        return self.clearing_lines[y];
    }
};
