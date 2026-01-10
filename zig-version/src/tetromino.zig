const std = @import("std");

pub const Position = struct {
    x: i32,
    y: i32,

    pub fn add(self: Position, other: Position) Position {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn eql(self: Position, other: Position) bool {
        return self.x == other.x and self.y == other.y;
    }
};

pub const TetrominoType = enum(u8) {
    I = 0,
    O = 1,
    T = 2,
    S = 3,
    Z = 4,
    J = 5,
    L = 6,

    pub fn getColor(self: TetrominoType) Color {
        return switch (self) {
            .I => .{ .r = 0, .g = 255, .b = 255 }, // Cyan
            .O => .{ .r = 255, .g = 255, .b = 0 }, // Yellow
            .T => .{ .r = 200, .g = 0, .b = 255 }, // Purple
            .S => .{ .r = 0, .g = 255, .b = 0 }, // Green
            .Z => .{ .r = 255, .g = 0, .b = 0 }, // Red
            .J => .{ .r = 0, .g = 100, .b = 255 }, // Blue
            .L => .{ .r = 255, .g = 165, .b = 0 }, // Orange
        };
    }

    pub fn random(rng: *std.Random) TetrominoType {
        const val = rng.intRangeAtMost(u8, 0, 6);
        return @enumFromInt(val);
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    pub fn withAlpha(self: Color, alpha: u8) Color {
        return .{ .r = self.r, .g = self.g, .b = self.b, .a = alpha };
    }
};

pub const Tetromino = struct {
    piece_type: TetrominoType,
    position: Position,
    rotation: u8, // 0-3

    pub fn init(piece_type: TetrominoType, x: i32, y: i32) Tetromino {
        return .{
            .piece_type = piece_type,
            .position = .{ .x = x, .y = y },
            .rotation = 0,
        };
    }

    pub fn getBlocks(self: Tetromino) [4]Position {
        const offsets = getBlockOffsets(self.piece_type, self.rotation);
        var blocks: [4]Position = undefined;
        for (offsets, 0..) |offset, i| {
            blocks[i] = self.position.add(offset);
        }
        return blocks;
    }

    pub fn getColor(self: Tetromino) Color {
        return self.piece_type.getColor();
    }

    pub fn moved(self: Tetromino, dx: i32, dy: i32) Tetromino {
        return .{
            .piece_type = self.piece_type,
            .position = .{ .x = self.position.x + dx, .y = self.position.y + dy },
            .rotation = self.rotation,
        };
    }

    pub fn rotated(self: Tetromino) Tetromino {
        const max_rotations: u8 = if (self.piece_type == .O) 1 else 4;
        return .{
            .piece_type = self.piece_type,
            .position = self.position,
            .rotation = (self.rotation + 1) % max_rotations,
        };
    }
};

// Block offsets relative to piece center for each rotation state
fn getBlockOffsets(piece_type: TetrominoType, rotation: u8) [4]Position {
    return switch (piece_type) {
        .I => switch (rotation % 4) {
            0 => .{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 2, .y = 0 } },
            1 => .{ .{ .x = 1, .y = -1 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 }, .{ .x = 1, .y = 2 } },
            2 => .{ .{ .x = -1, .y = 1 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 }, .{ .x = 2, .y = 1 } },
            3 => .{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 0, .y = 2 } },
            else => unreachable,
        },
        .O => .{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } },
        .T => switch (rotation % 4) {
            0 => .{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = -1 } },
            1 => .{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 0 } },
            2 => .{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 } },
            3 => .{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 1 }, .{ .x = -1, .y = 0 } },
            else => unreachable,
        },
        .S => switch (rotation % 4) {
            0, 2 => .{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = -1, .y = 1 } },
            1, 3 => .{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 } },
            else => unreachable,
        },
        .Z => switch (rotation % 4) {
            0, 2 => .{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } },
            1, 3 => .{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = -1 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 } },
            else => unreachable,
        },
        .J => switch (rotation % 4) {
            0 => .{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = -1, .y = -1 } },
            1 => .{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = -1 } },
            2 => .{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 } },
            3 => .{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 1 }, .{ .x = -1, .y = 1 } },
            else => unreachable,
        },
        .L => switch (rotation % 4) {
            0 => .{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = -1 } },
            1 => .{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } },
            2 => .{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = -1, .y = 1 } },
            3 => .{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 1 }, .{ .x = -1, .y = -1 } },
            else => unreachable,
        },
    };
}

// Get block offsets at rotation 0 for preview rendering
pub fn getPreviewOffsets(piece_type: TetrominoType) [4]Position {
    return getBlockOffsets(piece_type, 0);
}
