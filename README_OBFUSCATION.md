# Compile-Time Obfuscation

This project includes native Swift obfuscation that works at compile time through:

## 1. Obfuscation Module (`Sources/Tenebris`)

Tenebris - A Swift module that provides compile-time obfuscation utilities:
- String obfuscation through XOR encoding
- Integer obfuscation by splitting into parts
- All obfuscation is resolved at compile time with aggressive optimizations

## 2. Compiler Flags

The build uses aggressive optimization flags in release mode:
- `-O` - Maximum optimization
- `-whole-module-optimization` - Whole module optimization for better inlining
- `-cross-module-optimization` - Cross-module optimization
- Disabled lexical lifetimes for better optimization

## 3. Linker Flags

Symbol stripping and code size reduction:
- `/OPT:REF` - Remove unreferenced functions and data
- `/OPT:ICF` - Fold identical functions together (COMDAT folding)
- `/DEBUG:NONE` - Strip all debug information
- `/INCREMENTAL:NO` - Disable incremental linking
- `/LTCG` - Link-time code generation for maximum optimization
- `/MERGE:_RDATA=.rdata` - Merge read-only data sections

## Usage

Simply build in release mode:
```bash
swift build -c release
```

The obfuscation is automatically applied during compilation. The compiler will:
1. Inline all obfuscation helper functions
2. Optimize away the obfuscation logic
3. Strip symbols and debug information
4. Apply link-time optimizations

## How It Works

The obfuscation module uses Swift's `@inlinable` attribute to ensure that obfuscation helpers are inlined at compile time. With `-O` optimization and WMO, the Swift compiler:

1. Resolves all obfuscated strings/values at compile time
2. Inlines the decoder functions
3. Eliminates the obfuscation overhead completely
4. Produces optimized machine code with obfuscated values baked in

This means no runtime overhead while still making reverse engineering more difficult.
