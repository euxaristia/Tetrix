#!/bin/bash
# Obfuscated cross-compilation script for Linux -> Windows
# Builds Tetrix with maximum obfuscation and optimization for Windows release

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "Building obfuscated Windows release..."

# Build with maximum optimization and obfuscation
# ReleaseSmall automatically strips symbols, so --strip flag is not needed
# Use -Dname=tetrix-tenebrated to set the output executable name
zig build \
    -Dtarget=x86_64-windows \
    -Doptimize=ReleaseSmall \
    -Dname=tetrix-tenebrated

echo ""
echo "✓ Build complete!"
echo "  Binary: $PROJECT_ROOT/zig-out/bin/tetrix-tenebrated.exe"
echo ""
echo "Obfuscation features enabled:"
echo "  - ReleaseSmall optimization (smallest binary size)"
echo "  - Strip symbols (removes debug info)"
echo "  - Tenebris string obfuscation (compile-time XOR encoding)"
echo ""
echo ""
echo "To verify obfuscation, run:"
echo "  strings $PROJECT_ROOT/zig-out/bin/tetrix-tenebrated.exe | grep -i 'tetrix\|paused\|game over'"
echo "  (Should return nothing if obfuscation is working)"
