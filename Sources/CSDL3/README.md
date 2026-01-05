# SDL3 Headers Setup

To build this project, you need to copy the SDL3 header files to this location:

**Copy the `SDL3` folder from your SDL3 development package to:**
```
Sources/CSDL3/include/SDL3/
```

The structure should be:
```
Sources/CSDL3/include/SDL3/
  ├── SDL.h
  ├── (SDL_ttf.h removed - using Swift-native text rendering)
  ├── SDL_audio.h
  └── ... (other SDL3 headers)
```

If you downloaded SDL3 for Windows, the headers are typically in:
- The `include` folder of the SDL3 development package
- Or in a `SDL3` subfolder within the include directory

You also need:
- `SDL3.dll` - should be in the project root (already present)
- `SDL3.lib` - import library for linking (SDL3_ttf removed - using Swift-native text rendering)
