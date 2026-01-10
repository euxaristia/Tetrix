const std = @import("std");

pub const Settings = struct {
    high_score: u32 = 0,
    music_enabled: bool = true,
    is_fullscreen: bool = false,

    const config_path = ".config/tetrix.json";

    pub fn load(allocator: std.mem.Allocator) Settings {
        var settings = Settings{};

        // Get home directory
        const home = std.posix.getenv("HOME") orelse return settings;

        // Build full path
        const path = std.fmt.allocPrint(allocator, "{s}/{s}", .{ home, config_path }) catch return settings;
        defer allocator.free(path);

        // Read file
        const file = std.fs.openFileAbsolute(path, .{}) catch return settings;
        defer file.close();

        const content = file.readToEndAlloc(allocator, 4096) catch return settings;
        defer allocator.free(content);

        // Parse JSON manually (simple format)
        settings.parseJson(content);

        return settings;
    }

    fn parseJson(self: *Settings, content: []const u8) void {
        // Simple JSON parser for our known format
        // {"highScore": 12000, "musicEnabled": true, "isFullscreen": false}

        // Find highScore
        if (std.mem.indexOf(u8, content, "\"highScore\":")) |idx| {
            const start = idx + 12;
            var end = start;
            while (end < content.len and (content[end] >= '0' and content[end] <= '9')) {
                end += 1;
            }
            if (end > start) {
                self.high_score = std.fmt.parseInt(u32, content[start..end], 10) catch 0;
            }
        }

        // Find musicEnabled
        if (std.mem.indexOf(u8, content, "\"musicEnabled\":")) |idx| {
            const start = idx + 15;
            if (start + 4 <= content.len) {
                if (std.mem.startsWith(u8, content[start..], "true")) {
                    self.music_enabled = true;
                } else if (std.mem.startsWith(u8, content[start..], "false")) {
                    self.music_enabled = false;
                }
            }
        }

        // Find isFullscreen
        if (std.mem.indexOf(u8, content, "\"isFullscreen\":")) |idx| {
            const start = idx + 15;
            if (start + 4 <= content.len) {
                if (std.mem.startsWith(u8, content[start..], "true")) {
                    self.is_fullscreen = true;
                } else if (std.mem.startsWith(u8, content[start..], "false")) {
                    self.is_fullscreen = false;
                }
            }
        }
    }

    pub fn save(self: *const Settings, allocator: std.mem.Allocator) void {
        // Get home directory
        const home = std.posix.getenv("HOME") orelse return;

        // Ensure .config directory exists
        const config_dir = std.fmt.allocPrint(allocator, "{s}/.config", .{home}) catch return;
        defer allocator.free(config_dir);

        std.fs.makeDirAbsolute(config_dir) catch {};

        // Build full path
        const path = std.fmt.allocPrint(allocator, "{s}/{s}", .{ home, config_path }) catch return;
        defer allocator.free(path);

        // Create JSON content
        const json = std.fmt.allocPrint(allocator, "{{\"highScore\":{d},\"musicEnabled\":{},\"isFullscreen\":{}}}", .{
            self.high_score,
            self.music_enabled,
            self.is_fullscreen,
        }) catch return;
        defer allocator.free(json);

        // Write file
        const file = std.fs.createFileAbsolute(path, .{}) catch return;
        defer file.close();

        file.writeAll(json) catch {};
    }
};
