# Tetrix - A Swift Tetris Implementation

![CI](https://github.com/euxaristia/Tetrix/actions/workflows/ci.yml/badge.svg)

A complete Tetris game implementation written from scratch in Swift using SDL2. Works on Linux and macOS.

## Features

- All 7 classic Tetromino pieces (I, O, T, S, Z, J, L)
- Smooth piece movement and rotation
- Line clearing with scoring
- Level progression (speed increases every 10 lines)
- Hard drop functionality
- Next piece preview
- Pause/Resume functionality
- Game over detection
- Beautiful windowed interface with SDL2

## Game Controls

- **A / Left Arrow (←)**: Move piece left
- **D / Right Arrow (→)**: Move piece right
- **S / Down Arrow (↓)**: Soft drop (move down faster)
- **W / Up Arrow (↑)**: Rotate piece clockwise
- **Space**: Hard drop (instantly drop to bottom)
- **P**: Pause/Resume the game
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

### Linux (Arch/CachyOS)

Install SDL2 development libraries:
```bash
sudo pacman -S sdl2 sdl2_ttf
```

### Linux (Ubuntu/Debian)

```bash
sudo apt-get install libsdl2-dev libsdl2-ttf-dev
```

### macOS

```bash
brew install sdl2 sdl2_ttf
```

## Running the Game

```bash
swift run
```

Or build and run:
```bash
swift build
./.build/debug/Tetrix
```

## Requirements

- Swift 5.9+
- SDL2 development libraries
- SDL2_ttf (optional, for text rendering - game works without it)

## Project Structure

- `main.swift`: Application entry point
- `SDL2Game.swift`: SDL2 game loop, rendering, and input handling
- `Position.swift`: Coordinate system for board positions
- `Tetromino.swift`: Tetromino piece definitions and rotations
- `GameBoard.swift`: Game board logic and line clearing
- `TetrisEngine.swift`: Main game engine and state management
- `Sources/CSDL2/`: SDL2 C module wrapper

## Notes

- The game uses SDL2 for cross-platform windowed graphics
- Text rendering requires SDL2_ttf, but the game will run without it (text just won't display)
- The game runs at 60 FPS with VSync enabled

## License

This is a personal project implementation of Tetris.
