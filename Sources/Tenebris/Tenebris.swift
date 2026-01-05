import Foundation

/// Tenebris - Compile-time obfuscation utilities
/// This module provides obfuscation helpers that make reverse engineering harder
@usableFromInline
internal enum Tenebris {
    /// Obfuscated string decoder - strings are XOR encoded at compile time
    @inlinable
    static func decode(_ bytes: [UInt8], key: UInt8 = 0x42) -> String {
        let decoded = bytes.map { $0 ^ key }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }
    
    /// Obfuscated integer array - splits integers into parts
    @inlinable
    static func decodeInt(_ parts: (UInt16, UInt16)) -> Int {
        return Int(parts.0) | (Int(parts.1) << 16)
    }
    
    /// Obfuscated boolean
    @inlinable
    static func decodeBool(_ value: Int) -> Bool {
        return value != 0
    }
}

/// Internal obfuscation helper for compile-time constant hiding
internal struct ObfuscatedString {
    private let bytes: [UInt8]
    private let key: UInt8
    
    @usableFromInline
    init(_ bytes: [UInt8], key: UInt8 = 0x42) {
        self.bytes = bytes
        self.key = key
    }
    
    @usableFromInline
    var value: String {
        Tenebris.decode(bytes, key: key)
    }
}

/// Internal helper for obfuscated integers
internal struct ObfuscatedInt {
    private let parts: (UInt16, UInt16)
    
    @usableFromInline
    init(_ parts: (UInt16, UInt16)) {
        self.parts = parts
    }
    
    @usableFromInline
    var value: Int {
        Tenebris.decodeInt(parts)
    }
}
