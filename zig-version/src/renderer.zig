const std = @import("std");
const c = @import("c.zig");
const tetromino = @import("tetromino.zig");
const board = @import("board.zig");
const engine = @import("engine.zig");

const Position = tetromino.Position;
const Color = tetromino.Color;
const Tetromino = tetromino.Tetromino;
const TetrominoType = tetromino.TetrominoType;
const GameBoard = board.GameBoard;
const TetrisEngine = engine.TetrisEngine;
const GameState = engine.GameState;
const BOARD_WIDTH = board.BOARD_WIDTH;
const BOARD_HEIGHT = board.BOARD_HEIGHT;

// Layout constants (matching Swift version)
pub const CELL_SIZE: i32 = 30;
pub const BOARD_PIXEL_WIDTH: i32 = BOARD_WIDTH * CELL_SIZE; // 300
pub const BOARD_PIXEL_HEIGHT: i32 = BOARD_HEIGHT * CELL_SIZE; // 600
pub const SIDE_PANEL_WIDTH: i32 = 200;
pub const PADDING: i32 = 20;
pub const WINDOW_WIDTH: i32 = BOARD_PIXEL_WIDTH + SIDE_PANEL_WIDTH + PADDING * 2; // 540
pub const WINDOW_HEIGHT: i32 = BOARD_PIXEL_HEIGHT + PADDING * 2; // 640

// Colors
const BG_COLOR = Color{ .r = 20, .g = 20, .b = 30 };
const BOARD_BG_COLOR = Color{ .r = 30, .g = 30, .b = 40 };
const BOARD_BORDER_COLOR = Color{ .r = 100, .g = 100, .b = 120 };
const TEXT_COLOR = Color{ .r = 255, .g = 255, .b = 255 };
const FLASH_COLOR = Color{ .r = 255, .g = 255, .b = 200 };

pub const Renderer = struct {
    fps: f64 = 0,
    frame_count: u32 = 0,
    fps_timer: f64 = 0,
    music_enabled: bool = true,
    use_controller: bool = false,

    pub fn init() Renderer {
        return .{};
    }

    pub fn render(self: *Renderer, game: *const TetrisEngine, delta_time: f64) void {
        // Update FPS counter
        self.frame_count += 1;
        self.fps_timer += delta_time;
        if (self.fps_timer >= 1.0) {
            self.fps = @as(f64, @floatFromInt(self.frame_count)) / self.fps_timer;
            self.frame_count = 0;
            self.fps_timer = 0;
        }

        // Clear screen
        self.setColor(BG_COLOR);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // Draw board background and border
        self.drawBoardBackground();

        // Draw placed blocks
        self.drawBoard(&game.game_board);

        // Draw ghost piece
        if (game.getGhostPiece()) |ghost| {
            self.drawGhostPiece(ghost);
        }

        // Draw current piece
        if (game.current_piece) |piece| {
            self.drawPiece(piece);
        }

        // Draw UI
        self.drawUI(game);

        // Draw overlays based on game state
        switch (game.state) {
            .paused => self.drawPauseOverlay(),
            .game_over => self.drawGameOverOverlay(),
            .playing => {},
        }
    }

    fn setColor(self: *Renderer, color: Color) void {
        _ = self;
        c.glColor4f(
            @as(f32, @floatFromInt(color.r)) / 255.0,
            @as(f32, @floatFromInt(color.g)) / 255.0,
            @as(f32, @floatFromInt(color.b)) / 255.0,
            @as(f32, @floatFromInt(color.a)) / 255.0,
        );
    }

    fn drawRect(self: *Renderer, x: i32, y: i32, w: i32, h: i32) void {
        _ = self;
        const fx = @as(f32, @floatFromInt(x));
        const fy = @as(f32, @floatFromInt(y));
        const fw = @as(f32, @floatFromInt(w));
        const fh = @as(f32, @floatFromInt(h));

        c.glBegin(c.GL_QUADS);
        c.glVertex2f(fx, fy);
        c.glVertex2f(fx + fw, fy);
        c.glVertex2f(fx + fw, fy + fh);
        c.glVertex2f(fx, fy + fh);
        c.glEnd();
    }

    fn drawRectOutline(self: *Renderer, x: i32, y: i32, w: i32, h: i32) void {
        _ = self;
        const fx = @as(f32, @floatFromInt(x));
        const fy = @as(f32, @floatFromInt(y));
        const fw = @as(f32, @floatFromInt(w));
        const fh = @as(f32, @floatFromInt(h));

        c.glBegin(c.GL_LINE_LOOP);
        c.glVertex2f(fx, fy);
        c.glVertex2f(fx + fw, fy);
        c.glVertex2f(fx + fw, fy + fh);
        c.glVertex2f(fx, fy + fh);
        c.glEnd();
    }

    fn drawBoardBackground(self: *Renderer) void {
        // Border
        self.setColor(BOARD_BORDER_COLOR);
        self.drawRect(PADDING - 4, PADDING - 4, BOARD_PIXEL_WIDTH + 8, BOARD_PIXEL_HEIGHT + 8);

        // Background
        self.setColor(BOARD_BG_COLOR);
        self.drawRect(PADDING, PADDING, BOARD_PIXEL_WIDTH, BOARD_PIXEL_HEIGHT);
    }

    fn drawBoard(self: *Renderer, game_board: *const GameBoard) void {
        for (0..@intCast(BOARD_HEIGHT)) |y| {
            for (0..@intCast(BOARD_WIDTH)) |x| {
                const cell = game_board.cells[y][x];
                if (cell.filled) {
                    const px = PADDING + @as(i32, @intCast(x)) * CELL_SIZE;
                    const py = PADDING + @as(i32, @intCast(y)) * CELL_SIZE;

                    if (game_board.isClearingLine(y)) {
                        self.drawClearingBlock(px, py, cell.color, game_board);
                    } else {
                        self.drawBlock(px, py, cell.color);
                    }
                }
            }
        }
    }

    fn drawBlock(self: *Renderer, x: i32, y: i32, color: Color) void {
        // Fill
        self.setColor(color);
        self.drawRect(x + 1, y + 1, CELL_SIZE - 2, CELL_SIZE - 2);

        // Outline
        self.setColor(Color{ .r = 255, .g = 255, .b = 255, .a = 100 });
        self.drawRectOutline(x + 1, y + 1, CELL_SIZE - 2, CELL_SIZE - 2);
    }

    fn drawClearingBlock(self: *Renderer, x: i32, y: i32, color: Color, game_board: *const GameBoard) void {
        const anim = game_board.getAnimationProgress();

        switch (anim.phase) {
            .flash => {
                // Draw base block
                self.drawBlock(x, y, color);

                // Flash effect with sine oscillation
                const flash_intensity = @sin(anim.progress * std.math.pi * 4.0) * 0.5 + 0.5;
                const alpha: u8 = @intFromFloat(flash_intensity * 200.0);

                // Glow layers
                self.setColor(FLASH_COLOR.withAlpha(alpha));
                self.drawRect(x - 2, y - 2, CELL_SIZE + 4, CELL_SIZE + 4);

                self.setColor(FLASH_COLOR.withAlpha(alpha / 2));
                self.drawRect(x - 4, y - 4, CELL_SIZE + 8, CELL_SIZE + 8);
            },
            .fade => {
                // Fade out
                const alpha: u8 = @intFromFloat((1.0 - anim.progress) * 255.0);
                self.setColor(color.withAlpha(alpha));
                self.drawRect(x + 1, y + 1, CELL_SIZE - 2, CELL_SIZE - 2);
            },
        }
    }

    fn drawGhostPiece(self: *Renderer, ghost: Tetromino) void {
        const blocks = ghost.getBlocks();
        const color = ghost.getColor().withAlpha(80);

        for (blocks) |block| {
            if (block.y >= 0) {
                const px = PADDING + block.x * CELL_SIZE;
                const py = PADDING + block.y * CELL_SIZE;

                self.setColor(color);
                self.drawRectOutline(px + 1, py + 1, CELL_SIZE - 2, CELL_SIZE - 2);
            }
        }
    }

    fn drawPiece(self: *Renderer, piece: Tetromino) void {
        const blocks = piece.getBlocks();
        const color = piece.getColor();

        for (blocks) |block| {
            if (block.y >= 0) {
                const px = PADDING + block.x * CELL_SIZE;
                const py = PADDING + block.y * CELL_SIZE;
                self.drawBlock(px, py, color);
            }
        }
    }

    fn drawUI(self: *Renderer, game: *const TetrisEngine) void {
        const panel_x = PADDING + BOARD_PIXEL_WIDTH + 20;
        var y: i32 = PADDING;

        // Score
        self.setColor(TEXT_COLOR);
        self.drawText("Score:", panel_x, y);
        y += 20;
        self.drawNumber(game.score, panel_x, y);
        y += 30;

        // High Score
        self.drawText("High:", panel_x, y);
        y += 20;
        self.drawNumber(game.high_score, panel_x, y);
        y += 30;

        // Lines
        self.drawText("Lines:", panel_x, y);
        y += 20;
        self.drawNumber(game.lines_cleared, panel_x, y);
        y += 30;

        // Level
        self.drawText("Level:", panel_x, y);
        y += 20;
        self.drawNumber(game.level, panel_x, y);
        y += 30;

        // FPS
        const fps_color = if (self.fps >= 170.0) Color{ .r = 0, .g = 255, .b = 0 } else Color{ .r = 255, .g = 165, .b = 0 };
        self.setColor(fps_color);
        self.drawText("FPS:", panel_x, y);
        y += 20;
        self.drawNumber(@intFromFloat(self.fps), panel_x, y);
        y += 30;

        // Renderer
        self.setColor(TEXT_COLOR);
        self.drawText("Renderer:", panel_x, y);
        y += 20;
        self.drawText("OpenGL", panel_x, y);
        y += 40;

        // Next piece
        self.drawText("Next:", panel_x, y);
        y += 25;
        self.drawPreviewPiece(game.next_piece, panel_x + 30, y, 1.0);
        y += 80;

        // Next next piece
        self.setColor(Color{ .r = 150, .g = 150, .b = 150 });
        self.drawText("After:", panel_x, y);
        y += 25;
        self.drawPreviewPiece(game.next_next_piece, panel_x + 30, y, 0.6);
        y += 60;

        // Controls
        self.drawControls(panel_x, WINDOW_HEIGHT - 180);
    }

    fn drawPreviewPiece(self: *Renderer, piece_type: TetrominoType, x: i32, y: i32, scale: f32) void {
        const offsets = tetromino.getPreviewOffsets(piece_type);
        const color = piece_type.getColor();
        const size: i32 = @intFromFloat(@as(f32, @floatFromInt(CELL_SIZE)) * scale);

        self.setColor(color);
        for (offsets) |offset| {
            const px = x + @as(i32, @intFromFloat(@as(f32, @floatFromInt(offset.x)) * @as(f32, @floatFromInt(size))));
            const py = y + @as(i32, @intFromFloat(@as(f32, @floatFromInt(offset.y)) * @as(f32, @floatFromInt(size))));
            self.drawRect(px, py, size - 2, size - 2);
        }
    }

    fn drawControls(self: *Renderer, x: i32, start_y: i32) void {
        var y = start_y;
        self.setColor(TEXT_COLOR);
        self.drawText("Controls:", x, y);
        y += 18;

        if (self.use_controller) {
            self.setColor(Color{ .r = 180, .g = 180, .b = 180 });
            self.drawText("D-Pad: Move", x, y);
            y += 15;
            self.drawText("D-Pad Dn: Drop", x, y);
            y += 15;
            self.drawText("Up/X: Rotate", x, y);
            y += 15;
            self.drawText("Opt: Pause", x, y);
            y += 15;
            self.drawText("Share: Restart", x, y);
        } else {
            self.setColor(Color{ .r = 180, .g = 180, .b = 180 });
            self.drawText("WASD/Arrows", x, y);
            y += 15;
            self.drawText("Space: Drop", x, y);
            y += 15;
            self.drawText("ESC: Pause", x, y);
            y += 15;
            self.drawText("F11: Fullscreen", x, y);
        }

        y += 15;
        self.drawText("M: Music", x, y);
        if (self.music_enabled) {
            self.setColor(Color{ .r = 0, .g = 255, .b = 0 });
            self.drawText("(ON)", x + 70, y);
        } else {
            self.setColor(Color{ .r = 255, .g = 0, .b = 0 });
            self.drawText("(OFF)", x + 70, y);
        }
    }

    fn drawPauseOverlay(self: *Renderer) void {
        // Semi-transparent background
        self.setColor(Color{ .r = 0, .g = 0, .b = 0, .a = 150 });
        self.drawRect(PADDING, PADDING, BOARD_PIXEL_WIDTH, BOARD_PIXEL_HEIGHT);

        // PAUSED text (centered)
        self.setColor(Color{ .r = 255, .g = 255, .b = 0 });
        const text = "PAUSED";
        const text_x = PADDING + BOARD_PIXEL_WIDTH / 2 - @as(i32, @intCast(text.len * 5));
        const text_y = PADDING + BOARD_PIXEL_HEIGHT / 2 - 20;
        self.drawTextLarge(text, text_x, text_y);

        // Resume instruction
        self.setColor(Color{ .r = 150, .g = 150, .b = 150 });
        const instruction = if (self.use_controller) "Press Options" else "Press ESC";
        const inst_x = PADDING + BOARD_PIXEL_WIDTH / 2 - @as(i32, @intCast(instruction.len * 3));
        self.drawText(instruction, inst_x, text_y + 30);
    }

    fn drawGameOverOverlay(self: *Renderer) void {
        // Semi-transparent background with border
        self.setColor(Color{ .r = 0, .g = 0, .b = 0, .a = 200 });
        self.drawRect(PADDING + 20, PADDING + BOARD_PIXEL_HEIGHT / 2 - 50, BOARD_PIXEL_WIDTH - 40, 100);

        self.setColor(BOARD_BORDER_COLOR);
        self.drawRectOutline(PADDING + 20, PADDING + BOARD_PIXEL_HEIGHT / 2 - 50, BOARD_PIXEL_WIDTH - 40, 100);

        // GAME OVER text
        self.setColor(Color{ .r = 255, .g = 0, .b = 0 });
        const text = "GAME OVER";
        const text_x = PADDING + BOARD_PIXEL_WIDTH / 2 - @as(i32, @intCast(text.len * 5));
        const text_y = PADDING + BOARD_PIXEL_HEIGHT / 2 - 20;
        self.drawTextLarge(text, text_x, text_y);

        // Restart instruction
        self.setColor(Color{ .r = 150, .g = 150, .b = 150 });
        const instruction = if (self.use_controller) "Press Share" else "Press R";
        const inst_x = PADDING + BOARD_PIXEL_WIDTH / 2 - @as(i32, @intCast(instruction.len * 3));
        self.drawText(instruction, inst_x, text_y + 30);
    }

    // Simple bitmap font rendering using OpenGL lines
    fn drawChar(_: *Renderer, char: u8, x: i32, y: i32, scale: f32) void {
        const segments = getCharSegments(char);
        const s: i32 = @intFromFloat(scale);

        for (segments) |seg| {
            if (seg[0] == 0 and seg[1] == 0 and seg[2] == 0 and seg[3] == 0) break;
            const x1 = x + seg[0] * s;
            const y1 = y + seg[1] * s;
            const x2 = x + seg[2] * s;
            const y2 = y + seg[3] * s;

            c.glBegin(c.GL_LINES);
            c.glVertex2f(@floatFromInt(x1), @floatFromInt(y1));
            c.glVertex2f(@floatFromInt(x2), @floatFromInt(y2));
            c.glEnd();
        }
    }

    fn drawText(self: *Renderer, text: []const u8, x: i32, y: i32) void {
        var offset: i32 = 0;
        for (text) |char| {
            self.drawChar(char, x + offset, y, 1.5);
            offset += 8;
        }
    }

    fn drawTextLarge(self: *Renderer, text: []const u8, x: i32, y: i32) void {
        var offset: i32 = 0;
        for (text) |char| {
            self.drawChar(char, x + offset, y, 2.5);
            offset += 12;
        }
    }

    fn drawNumber(self: *Renderer, num: u32, x: i32, y: i32) void {
        var buf: [16]u8 = undefined;
        const str = std.fmt.bufPrint(&buf, "{d}", .{num}) catch return;
        self.drawText(str, x, y);
    }
};

// Simple 5x7 pixel font segments (line drawing coordinates)
fn getCharSegments(char: u8) [8][4]i32 {
    return switch (char) {
        '0' => .{ .{ 0, 0, 4, 0 }, .{ 4, 0, 4, 6 }, .{ 4, 6, 0, 6 }, .{ 0, 6, 0, 0 }, .{ 0, 0, 4, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '1' => .{ .{ 2, 0, 2, 6 }, .{ 0, 6, 4, 6 }, .{ 1, 1, 2, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '2' => .{ .{ 0, 0, 4, 0 }, .{ 4, 0, 4, 3 }, .{ 4, 3, 0, 3 }, .{ 0, 3, 0, 6 }, .{ 0, 6, 4, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '3' => .{ .{ 0, 0, 4, 0 }, .{ 4, 0, 4, 6 }, .{ 4, 6, 0, 6 }, .{ 0, 3, 4, 3 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '4' => .{ .{ 0, 0, 0, 3 }, .{ 0, 3, 4, 3 }, .{ 4, 0, 4, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '5' => .{ .{ 4, 0, 0, 0 }, .{ 0, 0, 0, 3 }, .{ 0, 3, 4, 3 }, .{ 4, 3, 4, 6 }, .{ 4, 6, 0, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '6' => .{ .{ 4, 0, 0, 0 }, .{ 0, 0, 0, 6 }, .{ 0, 6, 4, 6 }, .{ 4, 6, 4, 3 }, .{ 4, 3, 0, 3 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '7' => .{ .{ 0, 0, 4, 0 }, .{ 4, 0, 4, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '8' => .{ .{ 0, 0, 4, 0 }, .{ 4, 0, 4, 6 }, .{ 4, 6, 0, 6 }, .{ 0, 6, 0, 0 }, .{ 0, 3, 4, 3 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '9' => .{ .{ 0, 0, 4, 0 }, .{ 4, 0, 4, 6 }, .{ 4, 6, 0, 6 }, .{ 0, 0, 0, 3 }, .{ 0, 3, 4, 3 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'A', 'a' => .{ .{ 0, 6, 0, 2 }, .{ 0, 2, 2, 0 }, .{ 2, 0, 4, 2 }, .{ 4, 2, 4, 6 }, .{ 0, 4, 4, 4 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'B', 'b' => .{ .{ 0, 0, 0, 6 }, .{ 0, 0, 3, 0 }, .{ 3, 0, 4, 1 }, .{ 4, 1, 3, 3 }, .{ 0, 3, 3, 3 }, .{ 3, 3, 4, 4 }, .{ 4, 4, 4, 5 }, .{ 4, 5, 0, 6 } },
        'C', 'c' => .{ .{ 4, 0, 0, 0 }, .{ 0, 0, 0, 6 }, .{ 0, 6, 4, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'D', 'd' => .{ .{ 0, 0, 0, 6 }, .{ 0, 0, 3, 0 }, .{ 3, 0, 4, 2 }, .{ 4, 2, 4, 4 }, .{ 4, 4, 3, 6 }, .{ 3, 6, 0, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'E', 'e' => .{ .{ 4, 0, 0, 0 }, .{ 0, 0, 0, 6 }, .{ 0, 6, 4, 6 }, .{ 0, 3, 3, 3 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'F', 'f' => .{ .{ 4, 0, 0, 0 }, .{ 0, 0, 0, 6 }, .{ 0, 3, 3, 3 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'G', 'g' => .{ .{ 4, 0, 0, 0 }, .{ 0, 0, 0, 6 }, .{ 0, 6, 4, 6 }, .{ 4, 6, 4, 3 }, .{ 4, 3, 2, 3 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'H', 'h' => .{ .{ 0, 0, 0, 6 }, .{ 4, 0, 4, 6 }, .{ 0, 3, 4, 3 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'I', 'i' => .{ .{ 1, 0, 3, 0 }, .{ 2, 0, 2, 6 }, .{ 1, 6, 3, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'J', 'j' => .{ .{ 4, 0, 4, 6 }, .{ 4, 6, 0, 6 }, .{ 0, 6, 0, 4 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'K', 'k' => .{ .{ 0, 0, 0, 6 }, .{ 4, 0, 0, 3 }, .{ 0, 3, 4, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'L', 'l' => .{ .{ 0, 0, 0, 6 }, .{ 0, 6, 4, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'M', 'm' => .{ .{ 0, 6, 0, 0 }, .{ 0, 0, 2, 3 }, .{ 2, 3, 4, 0 }, .{ 4, 0, 4, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'N', 'n' => .{ .{ 0, 6, 0, 0 }, .{ 0, 0, 4, 6 }, .{ 4, 6, 4, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'O', 'o' => .{ .{ 0, 0, 4, 0 }, .{ 4, 0, 4, 6 }, .{ 4, 6, 0, 6 }, .{ 0, 6, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'P', 'p' => .{ .{ 0, 6, 0, 0 }, .{ 0, 0, 4, 0 }, .{ 4, 0, 4, 3 }, .{ 4, 3, 0, 3 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'Q', 'q' => .{ .{ 0, 0, 4, 0 }, .{ 4, 0, 4, 6 }, .{ 4, 6, 0, 6 }, .{ 0, 6, 0, 0 }, .{ 2, 4, 4, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'R', 'r' => .{ .{ 0, 6, 0, 0 }, .{ 0, 0, 4, 0 }, .{ 4, 0, 4, 3 }, .{ 4, 3, 0, 3 }, .{ 2, 3, 4, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'S', 's' => .{ .{ 4, 0, 0, 0 }, .{ 0, 0, 0, 3 }, .{ 0, 3, 4, 3 }, .{ 4, 3, 4, 6 }, .{ 4, 6, 0, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'T', 't' => .{ .{ 0, 0, 4, 0 }, .{ 2, 0, 2, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'U', 'u' => .{ .{ 0, 0, 0, 6 }, .{ 0, 6, 4, 6 }, .{ 4, 6, 4, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'V', 'v' => .{ .{ 0, 0, 2, 6 }, .{ 2, 6, 4, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'W', 'w' => .{ .{ 0, 0, 0, 6 }, .{ 0, 6, 2, 4 }, .{ 2, 4, 4, 6 }, .{ 4, 6, 4, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'X', 'x' => .{ .{ 0, 0, 4, 6 }, .{ 4, 0, 0, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'Y', 'y' => .{ .{ 0, 0, 2, 3 }, .{ 4, 0, 2, 3 }, .{ 2, 3, 2, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        'Z', 'z' => .{ .{ 0, 0, 4, 0 }, .{ 4, 0, 0, 6 }, .{ 0, 6, 4, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        ':' => .{ .{ 2, 2, 2, 2 }, .{ 2, 5, 2, 5 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '/' => .{ .{ 4, 0, 0, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '(' => .{ .{ 2, 0, 0, 2 }, .{ 0, 2, 0, 4 }, .{ 0, 4, 2, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        ')' => .{ .{ 2, 0, 4, 2 }, .{ 4, 2, 4, 4 }, .{ 4, 4, 2, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        ' ' => .{ .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '.' => .{ .{ 2, 5, 2, 6 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        '-' => .{ .{ 1, 3, 3, 3 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
        else => .{ .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
    };
}
