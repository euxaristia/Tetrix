# Compile-Time Obfuscation

This project includes native Zig obfuscation that works at compile time through:

## 1. Obfuscation Module (`src/tenebris.zig`)

Tenebris - A Zig module that provides compile-time obfuscation utilities:
- String obfuscation through XOR encoding (using `comptime`)
- Integer obfuscation by splitting into parts
- Boolean obfuscation
- All obfuscation is resolved at compile time with aggressive optimizations

## 2. Zig Compiler Optimizations

The build uses Zig's `ReleaseSmall` optimization mode which:
- Strips symbols automatically
- Applies maximum size optimizations
- Enables link-time optimizations
- Removes debug information
- Optimizes for smallest binary size

## 3. Compile-Time Execution

Zig's `comptime` feature ensures that:
- Obfuscation encoding happens at compile time
- Decoder functions are inlined automatically
- Obfuscation overhead is eliminated completely
- Values are baked directly into the binary

## Usage

Build the obfuscated version using the build script:
```bash
./scripts/build_tenebrated.sh
```

Or manually:
```bash
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSmall -Dname=tetrix-tenebrated
```

The obfuscation is automatically applied during compilation. The Zig compiler will:
1. Execute all `comptime` obfuscation logic at compile time
2. Inline decoder functions automatically
3. Optimize away the obfuscation overhead
4. Strip symbols and debug information (ReleaseSmall)
5. Apply link-time optimizations

## How It Works

The obfuscation module uses Zig's `comptime` keyword to ensure that obfuscation helpers execute at compile time. With `ReleaseSmall` optimization, the Zig compiler:

1. Resolves all obfuscated strings/values at compile time
2. Inlines the decoder functions automatically
3. Eliminates the obfuscation overhead completely
4. Produces optimized machine code with obfuscated values baked in

This means no runtime overhead while still making reverse engineering more difficult.

## Example

```zig
const tenebris = @import("tenebris.zig");

// String obfuscation - encoded at compile time
const obf_str = tenebris.ObfuscatedString.init("Hello", 0x42);
var buf: [256]u8 = undefined;
const decoded = obf_str.value(&buf); // Decoded at runtime

// Integer obfuscation - split into parts
const obf_int = tenebris.ObfuscatedInt.init(.{ 0x1234, 0x5678 });
const value = obf_int.value(); // Reconstructed at runtime
```

## Verification

To verify obfuscation is working, check the binary for strings:
```bash
strings tetrix-tenebrated.exe | grep -i 'tetrix\|paused\|game over'
```

If obfuscation is working correctly, these strings should not appear in plaintext in the binary.
