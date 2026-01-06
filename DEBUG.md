# Debugging Tetrix on Linux

## Known Issue
CodeLLDB extension in VSCode/Cursor may show warnings about "LLDB failed to provide a library path" for Swift debugging. This is usually harmless and debugging should still work.

## Solutions

### Option 1: Run Without Debugger (Recommended)
The game works perfectly without a debugger:
```bash
swift run
# or
./.build/debug/Tetrix
```

### Option 2: VSCode/Cursor Debugging with CodeLLDB
A `.vscode/launch.json` configuration is included with proper Swift runtime library paths:
1. Press `F5` or go to Run and Debug
2. Select "Debug Tetrix" configuration
3. The warning about library paths is usually harmless - debugging should still work

The configuration includes:
- Proper `LD_LIBRARY_PATH` for Swift runtime libraries (`/usr/lib/swift/lib/swift/linux`)
- Source mapping for debugging
- Pre-build task to compile before debugging

### Option 3: Command-Line Debugging
If you need more control, use command-line LLDB:

1. Build the project:
```bash
swift build
```

2. Start LLDB:
```bash
lldb ./.build/debug/Tetrix
```

3. Common LLDB commands:
   - `run` or `r` - Start the program
   - `breakpoint set --file main.swift --line <line>` - Set a breakpoint
   - `continue` or `c` - Continue execution
   - `step` or `s` - Step into
   - `next` or `n` - Step over
   - `print <variable>` or `p <variable>` - Print variable
   - `quit` or `q` - Exit

### Option 4: Print Debugging
For simple debugging, use `print()` statements in your Swift code. They work great for terminal applications.

## Fixing CodeLLDB Library Path Warning
If you get the "LLDB failed to provide a library path" error:

1. **Check Swift installation:**
   ```bash
   swift --version
   which swift
   ```

2. **Verify Swift runtime libraries exist:**
   ```bash
   ls -la /usr/lib/swift/lib/swift/linux/
   ```

3. **The `.vscode/settings.json` file** includes configuration to help CodeLLDB find the libraries. If the warning persists, it's usually safe to ignore - debugging should still function.

## Notes
- The CodeLLDB library path warning doesn't affect the game's functionality
- Swift debugging on Linux works best with native LLDB (command-line or CodeLLDB with proper configuration)
- The included `.vscode/launch.json` and `.vscode/settings.json` should resolve most configuration issues
