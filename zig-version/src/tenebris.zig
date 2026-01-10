const std = @import("std");

/// Tenebris - Compile-time obfuscation utilities
/// This module provides obfuscation helpers that make reverse engineering harder
pub const Tenebris = struct {
    pub const DEFAULT_KEY: u8 = 0x42; // Same default key as Swift version

    /// Obfuscated string decoder - strings are XOR encoded at compile time
    /// Equivalent to Swift's Tenebris.decode()
    pub fn decode(comptime bytes: []const u8, comptime key: u8) []const u8 {
        var decoded: [bytes.len]u8 = undefined;
        inline for (bytes, 0..) |byte, i| {
            decoded[i] = byte ^ key;
        }
        return &decoded;
    }

    /// Obfuscated integer decoder - reconstructs integer from split parts
    /// Equivalent to Swift's Tenebris.decodeInt()
    pub fn decodeInt(parts: struct { u16, u16 }) u32 {
        return @as(u32, parts[0]) | (@as(u32, parts[1]) << 16);
    }

    /// Obfuscated boolean decoder
    /// Equivalent to Swift's Tenebris.decodeBool()
    pub fn decodeBool(value: u32) bool {
        return value != 0;
    }
};

/// Internal obfuscation helper for compile-time constant hiding
/// Equivalent to Swift's ObfuscatedString
/// 
/// Usage:
///   const obf_str = ObfuscatedString.init("Hello", 0x42);
///   var buf: [256]u8 = undefined;
///   const decoded = obf_str.value(&buf);
pub const ObfuscatedString = struct {
    bytes: []const u8,
    key: u8,

    /// Create an obfuscated string at compile time
    /// The string is XOR-encoded at compile time, so it doesn't appear in plaintext in the binary
    /// Usage: const str = ObfuscatedString.init("Hello", 0x42);
    pub fn init(comptime str: []const u8, comptime key: u8) ObfuscatedString {
        // Create obfuscated bytes array at comptime and return as a comptime-known array
        const obfuscated = comptime blk: {
            var result: [str.len]u8 = undefined;
            for (str, 0..) |byte, i| {
                result[i] = byte ^ key;
            }
            break :blk result;
        };
        return .{
            .bytes = &obfuscated,
            .key = key,
        };
    }

    /// Decode the obfuscated string at runtime into a provided buffer
    /// Returns a slice of the buffer containing the decoded string
    /// Equivalent to Swift's ObfuscatedString.value property
    pub fn value(self: ObfuscatedString, buf: []u8) []u8 {
        const len = @min(self.bytes.len, buf.len);
        for (0..len) |i| {
            buf[i] = self.bytes[i] ^ self.key;
        }
        return buf[0..len];
    }
};

/// Internal helper for obfuscated integers
/// Equivalent to Swift's ObfuscatedInt
pub const ObfuscatedInt = struct {
    parts: struct { u16, u16 },

    /// Create an obfuscated integer from split parts
    /// Usage: const num = ObfuscatedInt.init(.{ 0x1234, 0x5678 });
    pub fn init(parts: struct { u16, u16 }) ObfuscatedInt {
        return .{ .parts = parts };
    }

    /// Decode the obfuscated integer at runtime
    pub fn value(self: ObfuscatedInt) u32 {
        return Tenebris.decodeInt(self.parts);
    }
};

// Test the obfuscation functions
test "Tenebris string obfuscation" {
    const original = "Hello, World!";
    const obfuscated = Tenebris.decode(original, Tenebris.DEFAULT_KEY);
    
    // Verify deobfuscation
    var decoded: [original.len]u8 = undefined;
    for (obfuscated, 0..) |byte, i| {
        decoded[i] = byte ^ Tenebris.DEFAULT_KEY;
    }
    
    try std.testing.expectEqualStrings(original, &decoded);
}

test "Tenebris integer obfuscation" {
    const original: u32 = 0x12345678;
    const parts = .{ @as(u16, @truncate(original & 0xFFFF)), @as(u16, @truncate((original >> 16) & 0xFFFF)) };
    const decoded = Tenebris.decodeInt(parts);
    
    try std.testing.expectEqual(original, decoded);
}

test "Tenebris boolean obfuscation" {
    try std.testing.expect(Tenebris.decodeBool(1));
    try std.testing.expect(!Tenebris.decodeBool(0));
}

test "ObfuscatedString" {
    const original = "Test String";
    const obf_str = ObfuscatedString.init(original, Tenebris.DEFAULT_KEY);
    var buf: [256]u8 = undefined;
    const decoded = obf_str.value(&buf);
    
    try std.testing.expectEqualStrings(original, decoded);
}

test "ObfuscatedInt" {
    const original: u32 = 0xABCD1234;
    const parts = .{ @as(u16, @truncate(original & 0xFFFF)), @as(u16, @truncate((original >> 16) & 0xFFFF)) };
    const obf_int = ObfuscatedInt.init(parts);
    const decoded = obf_int.value();
    
    try std.testing.expectEqual(original, decoded);
}
