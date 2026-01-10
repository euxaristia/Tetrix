const std = @import("std");

pub const Settings = struct {
    high_score: u32 = 0,
    music_enabled: bool = true,
    is_fullscreen: bool = false,

    const config_path = ".config/tetrix.json";
    const obfuscation_constant: u32 = 0x9E3779B9; // Golden ratio constant (same as DaniSnek)

    pub fn load(allocator: std.mem.Allocator) Settings {
        var settings = Settings{};

        // Get home directory (cross-platform)
        const home = std.process.getEnvVarOwned(allocator, "HOME") catch return settings;
        defer allocator.free(home);

        // Build full path
        const path = std.fmt.allocPrint(allocator, "{s}/{s}", .{ home, config_path }) catch return settings;

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
        // or obfuscated: {"highScore": "HS2654435769", ...}

        // Find highScore
        if (std.mem.indexOf(u8, content, "\"highScore\":")) |idx| {
            const start = idx + 12;
            var end = start;
            
            // Skip whitespace
            while (end < content.len and (content[end] == ' ' or content[end] == '\t')) {
                end += 1;
            }
            
            // Check if it's a string (obfuscated) or number (plain)
            if (end < content.len and content[end] == '"') {
                // Obfuscated format: "HS1234567890"
                end += 1; // Skip opening quote
                const str_start = end;
                while (end < content.len and content[end] != '"') {
                    end += 1;
                }
                if (end > str_start) {
                    const score_str = content[str_start..end];
                    self.high_score = self.deobfuscateHighScore(score_str);
                }
            } else {
                // Plain number format (backwards compatibility)
                while (end < content.len and (content[end] >= '0' and content[end] <= '9')) {
                    end += 1;
                }
                if (end > start) {
                    self.high_score = std.fmt.parseInt(u32, content[start..end], 10) catch 0;
                }
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
        // Get home directory (cross-platform)
        const home = std.process.getEnvVarOwned(allocator, "HOME") catch return;
        defer allocator.free(home);

        // Ensure .config directory exists
        const config_dir = std.fmt.allocPrint(allocator, "{s}/.config", .{home}) catch return;
        defer allocator.free(config_dir);

        std.fs.makeDirAbsolute(config_dir) catch {};

        // Build full path
        const path = std.fmt.allocPrint(allocator, "{s}/{s}", .{ home, config_path }) catch return;
        defer allocator.free(path);

        // Obfuscate high score before saving
        var obfuscated_buf: [32]u8 = undefined;
        const obfuscated_score = self.obfuscateHighScore(self.high_score, &obfuscated_buf);
        
        // Create JSON content with obfuscated high score
        const json = std.fmt.allocPrint(allocator, "{{\"highScore\":\"{s}\",\"musicEnabled\":{},\"isFullscreen\":{}}}", .{
            obfuscated_score,
            self.music_enabled,
            self.is_fullscreen,
        }) catch return;
        defer allocator.free(json);

        // Write file
        const file = std.fs.createFileAbsolute(path, .{}) catch return;
        defer file.close();

        file.writeAll(json) catch {};
    }

    // Obfuscate high score to prevent casual tampering
    fn obfuscateHighScore(self: *const Settings, score: u32, buf: []u8) []const u8 {
        _ = self;
        const obfuscated = score +% obfuscation_constant; // Wrap on overflow
        const result = std.fmt.bufPrint(buf, "HS{d}", .{obfuscated}) catch "HS0";
        return result;
    }

    // Deobfuscate high score
    fn deobfuscateHighScore(self: *Settings, obfuscated: []const u8) u32 {
        _ = self;
        // Check for "HS" prefix
        if (std.mem.startsWith(u8, obfuscated, "HS")) {
            const score_str = obfuscated[2..];
            const obfuscated_int = std.fmt.parseInt(u32, score_str, 10) catch return 0;
            // Handle potential underflow with wrapping subtraction
            if (obfuscated_int >= obfuscation_constant) {
                return obfuscated_int -% obfuscation_constant;
            } else {
                // Handle wrap-around case
                return obfuscated_int -% obfuscation_constant;
            }
        } else {
            // Not obfuscated, try to parse as plain number (backwards compatibility)
            return std.fmt.parseInt(u32, obfuscated, 10) catch 0;
        }
    }
};
