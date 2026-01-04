# Debugging Tetrix on Linux

## Known Issue
CodeLLDB extension in VSCode has compatibility issues with Swift's LLDB on Linux, showing errors about `liblldb.so.backup`.

## Solutions

### Option 1: Run Without Debugger (Recommended)
The game works perfectly without a debugger:
```bash
swift run
# or
./.build/debug/Tetrix
```

### Option 2: Command-Line Debugging
If you need to debug, use command-line LLDB:

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

### Option 3: Print Debugging
For simple debugging, use `print()` statements in your Swift code. They work great for terminal applications.

### Option 4: VSCode Launch Configuration (If CodeLLDB Works)
If CodeLLDB starts working on your system, the existing `.vscode/launch.json` should work. The configuration is already set up correctly.

## Notes
- The CodeLLDB error doesn't affect the game's functionality
- Swift debugging on Linux is generally better via command-line tools
- For a terminal game like Tetrix, print statements are often sufficient for debugging
