# Tetrix (Godot 4.6)

Tetrix is a fast, classic-style falling-block puzzle game built in Godot 4.6. It ships as a self-contained project with deterministic core rules, responsive controls, and web-friendly rendering.

## What Tetrix Is

- A complete Tetris-like game loop with score, level progression, lock delay, and game over flow
- A clean Godot-first codebase with gameplay logic separated from rendering/input/audio systems
- A desktop-and-web target project using Godot's Compatibility renderer
- A compact project intended to be easy to run, modify, and extend

## Requirements

- Godot `4.6` (stable)
- GPLv3 license (see `LICENSE`)

## Run

```bash
godot --path .
```

## Project Layout

- `project.godot` - engine/project configuration (Compatibility renderer, fixed 540x640 logical viewport)
- `scenes/main.tscn` - root scene
- `scripts/main.gd` - app glue, lifecycle, input events, save sync
- `scripts/engine.gd` - core Tetris rules, scoring, level/drop timing, lock delay
- `scripts/board.gd` - grid state, collision, line clear animation, ghost drop
- `scripts/tetromino.gd` - piece definitions, rotations, colors
- `scripts/input_handler.gd` - keyboard/controller repeat logic and conflict handling
- `scripts/audio_player.gd` - procedural melody playback (Korobeiniki + rare Jingle Bells variant)
- `scripts/game_renderer.gd` - complete 2D renderer/UI overlays
- `scripts/settings.gd` - persistent settings and high-score obfuscation

## Gameplay Features

- 7 tetromino types with rotation handling and collision checks
- Ghost piece and hard drop/soft drop behavior
- Line clearing and score progression tied to level speed
- Keyboard and controller support with repeat/conflict handling
- Optional procedural music playback
- Persistent settings and high score storage

## Controls

- Move: `A/D` or `Left/Right`
- Soft drop: `S` or `Down`
- Rotate: `W` or `Up`
- Hard drop: `Space`
- Pause: `Esc`
- Restart (game over): `R`
- Toggle music: `M`
- Fullscreen: `F11` (desktop)

Controller mappings mirror the original behavior (D-pad movement/drop, A/X rotate, Start pause, Back restart, Y music toggle).

## Save Data

Settings are stored in `user://tetrix.json`:

- `highScore` (obfuscated with `HS` prefix + constant offset)
- `musicEnabled`
- `isFullscreen`

## Web Export

The project is configured for web-friendly rendering through the Compatibility backend. Export templates and browser packaging follow the standard Godot web export workflow.
