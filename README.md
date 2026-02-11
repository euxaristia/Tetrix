# Tetrix (Godot 4.6)

Tetrix is now a pure Godot 4.6 implementation of the original project, targeting the **Compatibility renderer** so it can run on desktop and export cleanly to web.

## Requirements

- Godot `4.6` (stable)

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

The project is configured for web-friendly rendering via the Compatibility backend. Export templates and browser packaging follow standard Godot web export workflow.
