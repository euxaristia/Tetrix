# Tetrix

![Zig](https://img.shields.io/badge/language-Zig-orange?logo=zig)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)
[![License](https://img.shields.io/badge/license-BSD%203--Clause-blue)](LICENSE)

A complete Tetris game implementation written from scratch in Zig using GLFW and OpenGL. Cross-platform support for Windows, Linux, and macOS.

## Features

- 🎮 All 7 classic Tetromino pieces (I, O, T, S, Z, J, L)
- ⚡ Smooth piece movement and rotation with wall kicks
- 🎯 Line clearing with scoring and level progression
- 🎵 Background music (Korobeiniki theme)
- 👻 Ghost piece preview
- 📊 High score tracking with obfuscation
- 🎨 Beautiful OpenGL rendering
- 🎮 Gamepad/controller support
- 🔒 Compile-time string obfuscation (Tenebris)

## Game Controls

- **A / Left Arrow (←)**: Move piece left
- **D / Right Arrow (→)**: Move piece right
- **S / Down Arrow (↓)**: Soft drop (move down faster)
- **W / Up Arrow (↑)**: Rotate piece clockwise
- **Space**: Hard drop (instantly drop to bottom)
- **ESC**: Pause/Resume the game
- **M**: Toggle music
- **F**: Toggle fullscreen
- **Q**: Quit
- **R**: Restart (when game over)

## Scoring System

- Single line: 100 × level
- Double lines: 300 × level
- Triple lines: 500 × level
- Tetris (4 lines): 800 × level
- Hard drop: 2 points per cell dropped

## Level System

- Starting level: 1
- Level increases every 10 lines cleared
- Game speed increases with each level

## Installation

### Linux

Install dependencies:
```bash
# Arch/CachyOS
sudo pacman -S glfw alsa-lib

# Ubuntu/Debian
sudo apt-get install libglfw3-dev libasound2-dev
```

Build and run:
```bash
cd zig-version
zig build run
```

### Windows

Cross-compile from Linux:
```bash
./scripts/obfuscated_build.sh
```

The binary will be at `zig-version/zig-out/bin/tetrix.exe`

### macOS

```bash
brew install glfw
cd zig-version
zig build run
```

## Building

### Debug Build
```bash
cd zig-version
zig build run
```

### Release Build (Optimized)
```bash
cd zig-version
zig build -Doptimize=ReleaseFast
```

### Obfuscated Windows Build
```bash
./scripts/obfuscated_build.sh
```

## Requirements

- Zig 0.15.2+
- GLFW 3.4+ (system library on Linux/macOS, compiled from source for Windows)
- OpenGL
- ALSA (Linux only, for audio)

## Project Structure

```
zig-version/
├── src/
│   ├── main.zig          # Application entry point
│   ├── engine.zig        # Game engine and logic
│   ├── board.zig         # Game board and line clearing
│   ├── tetromino.zig     # Tetromino definitions
│   ├── renderer.zig      # OpenGL rendering
│   ├── input.zig         # Input handling
│   ├── audio.zig         # ALSA audio playback
│   ├── settings.zig      # Settings and high score management
│   └── tenebris.zig     # Compile-time obfuscation utilities
├── build.zig             # Build configuration
└── build.zig.zon        # Package dependencies
```

## High Score Storage

High scores are stored in `~/.config/tetrix.json` with obfuscation to prevent casual tampering. The file format:

```json
{
  "highScore": "HS2654435869",
  "musicEnabled": true,
  "isFullscreen": false
}
```

## Notes

- The game uses GLFW for cross-platform windowing and input
- OpenGL for rendering (hardware-accelerated)
- ALSA for audio on Linux (DirectSound/WASAPI on Windows, CoreAudio on macOS)
- Compile-time string obfuscation via Tenebris module
- Windows builds include GLFW compiled from source
- Supports gamepad/controller input via GLFW joystick API

## License

This is a personal project implementation of Tetris.
