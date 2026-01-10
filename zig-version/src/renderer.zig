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

        // Score (matching Swift: "Score: {value}" on same line)
        self.setColor(TEXT_COLOR);
        self.drawTextWithNumber("Score: ", game.score, panel_x, y);
        y += 30;

        // High Score
        self.drawTextWithNumber("High: ", game.high_score, panel_x, y);
        y += 30;

        // Lines
        self.drawTextWithNumber("Lines: ", game.lines_cleared, panel_x, y);
        y += 30;

        // Level
        self.drawTextWithNumber("Level: ", game.level, panel_x, y);
        y += 30;

        // FPS
        const fps_color = if (self.fps >= 170.0) Color{ .r = 100, .g = 255, .b = 100 } else Color{ .r = 255, .g = 200, .b = 100 };
        self.setColor(fps_color);
        var fps_buf: [32]u8 = undefined;
        const fps_str = std.fmt.bufPrint(&fps_buf, "FPS: {d:.1}", .{self.fps}) catch "FPS: --";
        self.drawText(fps_str, panel_x, y);
        y += 20;

        // Renderer
        self.setColor(Color{ .r = 160, .g = 200, .b = 255 });
        self.drawText("Renderer: OpenGL", panel_x, y);
        y += 30;

        // Next piece
        self.setColor(TEXT_COLOR);
        self.drawText("Next:", panel_x, y);
        y += 30;
        self.drawPreviewPiece(game.next_piece, panel_x, y, 1.0);
        y += 70;

        // Next next piece
        self.setColor(Color{ .r = 200, .g = 200, .b = 200 });
        self.drawText("After:", panel_x, y);
        y += 30;
        self.drawPreviewPiece(game.next_next_piece, panel_x, y, 0.6);

        // Controls (positioned from bottom)
        self.drawControls(panel_x, WINDOW_HEIGHT - 140);
    }

    fn drawTextWithNumber(self: *Renderer, label: []const u8, num: u32, x: i32, y: i32) void {
        var buf: [32]u8 = undefined;
        const str = std.fmt.bufPrint(&buf, "{s}{d}", .{ label, num }) catch return;
        self.drawText(str, x, y);
    }

    fn drawPreviewPiece(self: *Renderer, piece_type: TetrominoType, x: i32, y: i32, scale: f32) void {
        const offsets = tetromino.getPreviewOffsets(piece_type);
        const color = piece_type.getColor();
        const size: i32 = @intFromFloat(@as(f32, @floatFromInt(CELL_SIZE)) * scale);

        // Calculate bounding box to center the piece
        var min_x: i32 = offsets[0].x;
        var max_x: i32 = offsets[0].x;
        var min_y: i32 = offsets[0].y;
        var max_y: i32 = offsets[0].y;
        
        for (offsets[1..]) |offset| {
            min_x = @min(min_x, offset.x);
            max_x = @max(max_x, offset.x);
            min_y = @min(min_y, offset.y);
            max_y = @max(max_y, offset.y);
        }
        
        // Calculate the width and height of the piece in blocks
        const width_blocks = max_x - min_x + 1;
        const height_blocks = max_y - min_y + 1;
        
        // Center horizontally: x is the left edge of preview area
        // We want to center the piece within a 4-block-wide area (max tetromino width)
        const preview_width_blocks: i32 = 4;
        const preview_width_px = preview_width_blocks * size;
        const piece_width_px = width_blocks * size;
        const center_x_offset = @divTrunc(preview_width_px - piece_width_px, 2);
        
        // Center vertically: y is the top of preview area
        // Start from top and center vertically within preview area
        const preview_height_blocks: i32 = 2;
        const preview_height_px = preview_height_blocks * size;
        const piece_height_px = height_blocks * size;
        const center_y_offset = @divTrunc(preview_height_px - piece_height_px, 2);

        self.setColor(color);
        for (offsets) |offset| {
            // Calculate position relative to top-left of bounding box, then center
            const block_x_in_piece = offset.x - min_x;
            const block_y_in_piece = offset.y - min_y;
            const px = x + center_x_offset + block_x_in_piece * size;
            const py = y + center_y_offset + block_y_in_piece * size;
            self.drawRect(px, py, size - 2, size - 2);
        }
    }

    fn drawControls(self: *Renderer, x: i32, start_y: i32) void {
        var y = start_y;
        self.setColor(Color{ .r = 150, .g = 150, .b = 150 });
        self.drawText("Controls:", x, y);
        y += 20;

        if (self.use_controller) {
            self.setColor(Color{ .r = 130, .g = 130, .b = 130 });
            self.drawText("D-Pad: Move", x, y);
            y += 20;
            self.drawText("D-Pad Dn: Drop", x, y);
            y += 20;
            self.drawText("Up/X: Rotate", x, y);
            y += 20;
            self.drawText("Opt: Pause", x, y);
            y += 20;
            self.drawText("Share: Restart", x, y);
            y += 20;
        } else {
            self.setColor(Color{ .r = 130, .g = 130, .b = 130 });
            self.drawText("WASD/Arrows", x, y);
            y += 20;
            self.drawText("Space: Drop", x, y);
            y += 20;
            self.drawText("ESC: Pause", x, y);
            y += 20;
            self.drawText("F11: Fullscreen", x, y);
            y += 20;
        }

        self.setColor(Color{ .r = 130, .g = 130, .b = 130 });
        self.drawText("M: Music", x, y);
        if (self.music_enabled) {
            self.setColor(Color{ .r = 100, .g = 255, .b = 100 });
            self.drawText("(ON)", x + 90, y);
        } else {
            self.setColor(Color{ .r = 255, .g = 100, .b = 100 });
            self.drawText("(OFF)", x + 90, y);
        }
    }

    fn drawPauseOverlay(self: *Renderer) void {
        // Semi-transparent background
        self.setColor(Color{ .r = 0, .g = 0, .b = 0, .a = 150 });
        self.drawRect(PADDING, PADDING, BOARD_PIXEL_WIDTH, BOARD_PIXEL_HEIGHT);

        // PAUSED text (centered) - 6 chars * 15 pixels / 2 = 45
        self.setColor(Color{ .r = 255, .g = 255, .b = 0 });
        const text = "PAUSED";
        const text_x = PADDING + BOARD_PIXEL_WIDTH / 2 - 45;
        const text_y = PADDING + BOARD_PIXEL_HEIGHT / 2 - 20;
        self.drawTextLarge(text, text_x, text_y);

        // Resume instruction
        self.setColor(Color{ .r = 200, .g = 200, .b = 200 });
        const instruction = if (self.use_controller) "Press Options" else "Press ESC";
        const inst_len: i32 = @intCast(instruction.len);
        const inst_x = PADDING + BOARD_PIXEL_WIDTH / 2 - @divTrunc(inst_len * 10, 2);
        self.drawText(instruction, inst_x, text_y + 40);
    }

    fn drawGameOverOverlay(self: *Renderer) void {
        // Semi-transparent background with border
        const box_width: i32 = 200;
        const box_height: i32 = 80;
        const box_x = PADDING + @divTrunc(BOARD_PIXEL_WIDTH, 2) - @divTrunc(box_width, 2);
        const box_y = PADDING + @divTrunc(BOARD_PIXEL_HEIGHT, 2) - @divTrunc(box_height, 2) - 10;

        self.setColor(Color{ .r = 0, .g = 0, .b = 0, .a = 200 });
        self.drawRect(box_x - 4, box_y - 4, box_width + 8, box_height + 8);

        self.setColor(Color{ .r = 30, .g = 30, .b = 40, .a = 240 });
        self.drawRect(box_x, box_y, box_width, box_height);

        // GAME OVER text - 9 chars * 15 pixels / 2 = 67
        self.setColor(Color{ .r = 255, .g = 0, .b = 0 });
        const text = "GAME OVER";
        const text_x = PADDING + BOARD_PIXEL_WIDTH / 2 - 67;
        const text_y = box_y + 15;
        self.drawTextLarge(text, text_x, text_y);

        // Restart instruction
        self.setColor(Color{ .r = 200, .g = 200, .b = 200 });
        const instruction = if (self.use_controller) "Press Share" else "Press R";
        const inst_len: i32 = @intCast(instruction.len);
        const inst_x = PADDING + BOARD_PIXEL_WIDTH / 2 - @divTrunc(inst_len * 10, 2);
        self.drawText(instruction, inst_x, box_y + 50);
    }

    // Simple bitmap font rendering using thick lines (filled quads)
    fn drawChar(_: *Renderer, char: u8, x: i32, y: i32, scale: f32) void {
        const segments = getCharSegments(char);
        const s = scale;
        const thickness: f32 = scale * 0.8; // Line thickness

        for (segments) |seg| {
            if (seg[0] == 0 and seg[1] == 0 and seg[2] == 0 and seg[3] == 0) break;

            const x1 = @as(f32, @floatFromInt(x)) + @as(f32, @floatFromInt(seg[0])) * s;
            const y1 = @as(f32, @floatFromInt(y)) + @as(f32, @floatFromInt(seg[1])) * s;
            const x2 = @as(f32, @floatFromInt(x)) + @as(f32, @floatFromInt(seg[2])) * s;
            const y2 = @as(f32, @floatFromInt(y)) + @as(f32, @floatFromInt(seg[3])) * s;

            // Draw thick line as a quad
            const dx = x2 - x1;
            const dy = y2 - y1;
            const len = @sqrt(dx * dx + dy * dy);

            if (len < 0.01) {
                // Draw a point as a small square
                c.glBegin(c.GL_QUADS);
                c.glVertex2f(x1 - thickness / 2, y1 - thickness / 2);
                c.glVertex2f(x1 + thickness / 2, y1 - thickness / 2);
                c.glVertex2f(x1 + thickness / 2, y1 + thickness / 2);
                c.glVertex2f(x1 - thickness / 2, y1 + thickness / 2);
                c.glEnd();
            } else {
                // Perpendicular vector for thickness
                const px = -dy / len * thickness / 2;
                const py = dx / len * thickness / 2;

                c.glBegin(c.GL_QUADS);
                c.glVertex2f(x1 + px, y1 + py);
                c.glVertex2f(x1 - px, y1 - py);
                c.glVertex2f(x2 - px, y2 - py);
                c.glVertex2f(x2 + px, y2 + py);
                c.glEnd();
            }
        }
    }

    fn drawText(self: *Renderer, text: []const u8, x: i32, y: i32) void {
        var offset: i32 = 0;
        for (text) |char| {
            self.drawChar(char, x + offset, y, 2.0);
            offset += 10;
        }
    }

    fn drawTextLarge(self: *Renderer, text: []const u8, x: i32, y: i32) void {
        var offset: i32 = 0;
        for (text) |char| {
            self.drawChar(char, x + offset, y, 3.0);
            offset += 15;
        }
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
