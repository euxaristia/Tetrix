/* Clean replacement for SDL_video.h - no copyright dependencies */

#ifndef SDL_video_h_
#define SDL_video_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_error.h>
#include <SDL3/SDL_pixels.h>
#include <SDL3/SDL_properties.h>
#include <SDL3/SDL_rect.h>
#include <SDL3/SDL_surface.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Display ID */
typedef Uint32 SDL_DisplayID;

/* Window ID */
typedef Uint32 SDL_WindowID;

/* System theme */
typedef enum SDL_SystemTheme {
    SDL_SYSTEM_THEME_UNKNOWN,
    SDL_SYSTEM_THEME_LIGHT,
    SDL_SYSTEM_THEME_DARK
} SDL_SystemTheme;

/* Display mode data (opaque) */
typedef struct SDL_DisplayModeData SDL_DisplayModeData;

/* Display mode */
typedef struct SDL_DisplayMode {
    SDL_DisplayID displayID;
    SDL_PixelFormat format;
    int w;
    int h;
    float pixel_density;
    float refresh_rate;
    int refresh_rate_numerator;
    int refresh_rate_denominator;
    SDL_DisplayModeData *internal;
} SDL_DisplayMode;

/* Display orientation */
typedef enum SDL_DisplayOrientation {
    SDL_ORIENTATION_UNKNOWN,
    SDL_ORIENTATION_LANDSCAPE,
    SDL_ORIENTATION_LANDSCAPE_FLIPPED,
    SDL_ORIENTATION_PORTRAIT,
    SDL_ORIENTATION_PORTRAIT_FLIPPED
} SDL_DisplayOrientation;

/* Window (opaque) */
typedef struct SDL_Window SDL_Window;

/* Window flags */
typedef Uint64 SDL_WindowFlags;

#define SDL_WINDOW_FULLSCREEN           SDL_UINT64_C(0x0000000000000001)
#define SDL_WINDOW_OPENGL               SDL_UINT64_C(0x0000000000000002)
#define SDL_WINDOW_OCCLUDED             SDL_UINT64_C(0x0000000000000004)
#define SDL_WINDOW_HIDDEN               SDL_UINT64_C(0x0000000000000008)
#define SDL_WINDOW_BORDERLESS           SDL_UINT64_C(0x0000000000000010)
#define SDL_WINDOW_RESIZABLE            SDL_UINT64_C(0x0000000000000020)
#define SDL_WINDOW_MINIMIZED            SDL_UINT64_C(0x0000000000000040)
#define SDL_WINDOW_MAXIMIZED            SDL_UINT64_C(0x0000000000000080)
#define SDL_WINDOW_MOUSE_GRABBED        SDL_UINT64_C(0x0000000000000100)
#define SDL_WINDOW_INPUT_FOCUS          SDL_UINT64_C(0x0000000000000200)
#define SDL_WINDOW_MOUSE_FOCUS          SDL_UINT64_C(0x0000000000000400)
#define SDL_WINDOW_EXTERNAL             SDL_UINT64_C(0x0000000000000800)
#define SDL_WINDOW_MODAL                SDL_UINT64_C(0x0000000000001000)
#define SDL_WINDOW_HIGH_PIXEL_DENSITY   SDL_UINT64_C(0x0000000000002000)
#define SDL_WINDOW_MOUSE_CAPTURE        SDL_UINT64_C(0x0000000000004000)
#define SDL_WINDOW_MOUSE_RELATIVE_MODE  SDL_UINT64_C(0x0000000000008000)
#define SDL_WINDOW_ALWAYS_ON_TOP        SDL_UINT64_C(0x0000000000010000)
#define SDL_WINDOW_UTILITY              SDL_UINT64_C(0x0000000000020000)
#define SDL_WINDOW_TOOLTIP              SDL_UINT64_C(0x0000000000040000)
#define SDL_WINDOW_POPUP_MENU           SDL_UINT64_C(0x0000000000080000)
#define SDL_WINDOW_KEYBOARD_GRABBED     SDL_UINT64_C(0x0000000000100000)
#define SDL_WINDOW_FILL_DOCUMENT        SDL_UINT64_C(0x0000000000200000)
#define SDL_WINDOW_VULKAN               SDL_UINT64_C(0x0000000010000000)
#define SDL_WINDOW_METAL                SDL_UINT64_C(0x0000000020000000)
#define SDL_WINDOW_TRANSPARENT          SDL_UINT64_C(0x0000000040000000)
#define SDL_WINDOW_NOT_FOCUSABLE        SDL_UINT64_C(0x0000000080000000)

/* Window position macros */
#define SDL_WINDOWPOS_UNDEFINED_MASK    0x1FFF0000u
#define SDL_WINDOWPOS_UNDEFINED_DISPLAY(X)  (SDL_WINDOWPOS_UNDEFINED_MASK|(X))
#define SDL_WINDOWPOS_UNDEFINED         SDL_WINDOWPOS_UNDEFINED_DISPLAY(0)
#define SDL_WINDOWPOS_ISUNDEFINED(X)    (((X)&0xFFFF0000) == SDL_WINDOWPOS_UNDEFINED_MASK)
#define SDL_WINDOWPOS_CENTERED_MASK    0x2FFF0000u
#define SDL_WINDOWPOS_CENTERED_DISPLAY(X)  (SDL_WINDOWPOS_CENTERED_MASK|(X))
#define SDL_WINDOWPOS_CENTERED         SDL_WINDOWPOS_CENTERED_DISPLAY(0)
#define SDL_WINDOWPOS_ISCENTERED(X)    (((X)&0xFFFF0000) == SDL_WINDOWPOS_CENTERED_MASK)

/* Global video properties */
#define SDL_PROP_GLOBAL_VIDEO_WAYLAND_WL_DISPLAY_POINTER "SDL.video.wayland.wl_display"

/* Display functions */
extern SDL_DECLSPEC SDL_DisplayID * SDLCALL SDL_GetDisplays(int *count);
extern SDL_DECLSPEC SDL_DisplayID SDLCALL SDL_GetPrimaryDisplay(void);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetDisplayName(SDL_DisplayID displayID);
extern SDL_DECLSPEC SDL_DisplayOrientation SDLCALL SDL_GetDisplayOrientation(SDL_DisplayID displayID);
extern SDL_DECLSPEC bool SDLCALL SDL_GetDisplayUsableBounds(SDL_DisplayID displayID, SDL_Rect *rect);
extern SDL_DECLSPEC bool SDLCALL SDL_GetDisplayBounds(SDL_DisplayID displayID, SDL_Rect *rect);
extern SDL_DECLSPEC float SDLCALL SDL_GetDisplayContentScale(SDL_DisplayID displayID);
extern SDL_DECLSPEC bool SDLCALL SDL_GetDesktopDisplayMode(SDL_DisplayID displayID, SDL_DisplayMode *mode);
extern SDL_DECLSPEC bool SDLCALL SDL_GetCurrentDisplayMode(SDL_DisplayID displayID, SDL_DisplayMode *mode);
extern SDL_DECLSPEC SDL_DisplayMode ** SDLCALL SDL_GetFullscreenDisplayModes(SDL_DisplayID displayID, int *count);

/* Window creation */
extern SDL_DECLSPEC SDL_Window * SDLCALL SDL_CreateWindow(const char *title, int w, int h, SDL_WindowFlags flags);
extern SDL_DECLSPEC SDL_Window * SDLCALL SDL_CreateWindowWithProperties(SDL_PropertiesID props);
extern SDL_DECLSPEC void SDLCALL SDL_DestroyWindow(SDL_Window *window);

/* Window queries */
extern SDL_DECLSPEC SDL_PropertiesID SDLCALL SDL_GetWindowProperties(SDL_Window *window);
extern SDL_DECLSPEC SDL_WindowID SDLCALL SDL_GetWindowID(SDL_Window *window);
extern SDL_DECLSPEC SDL_Window * SDLCALL SDL_GetWindowFromID(SDL_WindowID id);
extern SDL_DECLSPEC SDL_Window ** SDLCALL SDL_GetWindows(int *count);
extern SDL_DECLSPEC SDL_WindowFlags SDLCALL SDL_GetWindowFlags(SDL_Window *window);
extern SDL_DECLSPEC SDL_DisplayID SDLCALL SDL_GetWindowDisplayID(SDL_Window *window);

/* Window title */
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowTitle(SDL_Window *window, const char *title);
extern SDL_DECLSPEC const char * SDLCALL SDL_GetWindowTitle(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowIcon(SDL_Window *window, SDL_Surface *icon);

/* Window position and size */
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowPosition(SDL_Window *window, int x, int y);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowPosition(SDL_Window *window, int *x, int *y);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowSize(SDL_Window *window, int w, int h);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowSize(SDL_Window *window, int *w, int *h);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowSizeInPixels(SDL_Window *window, int *w, int *h);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowSafeArea(SDL_Window *window, SDL_Rect *rect);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowBordersSize(SDL_Window *window, int *top, int *left, int *bottom, int *right);

/* Window size constraints */
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowMinimumSize(SDL_Window *window, int min_w, int min_h);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowMinimumSize(SDL_Window *window, int *w, int *h);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowMaximumSize(SDL_Window *window, int max_w, int max_h);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowMaximumSize(SDL_Window *window, int *w, int *h);

/* Window aspect ratio */
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowAspectRatio(SDL_Window *window, float min_aspect, float max_aspect);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowAspectRatio(SDL_Window *window, float *min_aspect, float *max_aspect);

/* Window pixel density/scale */
extern SDL_DECLSPEC float SDLCALL SDL_GetWindowPixelDensity(SDL_Window *window);
extern SDL_DECLSPEC float SDLCALL SDL_GetWindowDisplayScale(SDL_Window *window);
extern SDL_DECLSPEC SDL_PixelFormat SDLCALL SDL_GetWindowPixelFormat(SDL_Window *window);

/* Window state */
extern SDL_DECLSPEC bool SDLCALL SDL_ShowWindow(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_HideWindow(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_RaiseWindow(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_MaximizeWindow(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_MinimizeWindow(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_RestoreWindow(SDL_Window *window);

/* Window borders and resizability */
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowBordered(SDL_Window *window, bool bordered);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowResizable(SDL_Window *window, bool resizable);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowAlwaysOnTop(SDL_Window *window, bool on_top);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowFillDocument(SDL_Window *window, bool fill);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowFocusable(SDL_Window *window, bool focusable);

/* Fullscreen */
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowFullscreen(SDL_Window *window, bool fullscreen);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowFullscreenMode(SDL_Window *window, const SDL_DisplayMode *mode);
extern SDL_DECLSPEC const SDL_DisplayMode * SDLCALL SDL_GetWindowFullscreenMode(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowFullscreenState(SDL_Window *window, bool *fullscreen);

/* Window surface (for software rendering) */
extern SDL_DECLSPEC SDL_Surface * SDLCALL SDL_GetWindowSurface(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_UpdateWindowSurface(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_UpdateWindowSurfaceRects(SDL_Window *window, const SDL_Rect *rects, int numrects);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowSurfaceVSync(SDL_Window *window, int vsync);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowSurfaceVSync(SDL_Window *window, int *vsync);
extern SDL_DECLSPEC bool SDLCALL SDL_DestroyWindowSurface(SDL_Window *window);

/* Window grab */
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowKeyboardGrab(SDL_Window *window, bool grabbed);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowKeyboardGrab(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowMouseGrab(SDL_Window *window, bool grabbed);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowMouseGrab(SDL_Window *window);
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowMouseRect(SDL_Window *window, const SDL_Rect *rect);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowMouseRect(SDL_Window *window, SDL_Rect *rect);

/* Window opacity */
extern SDL_DECLSPEC bool SDLCALL SDL_SetWindowOpacity(SDL_Window *window, float opacity);
extern SDL_DECLSPEC bool SDLCALL SDL_GetWindowOpacity(SDL_Window *window, float *opacity);

/* Window ICC profile */
extern SDL_DECLSPEC void * SDLCALL SDL_GetWindowICCProfile(SDL_Window *window, size_t *size);

/* Window parent (for child windows) */
extern SDL_DECLSPEC SDL_Window * SDLCALL SDL_GetWindowParent(SDL_Window *window);

/* System theme */
extern SDL_DECLSPEC SDL_SystemTheme SDLCALL SDL_GetSystemTheme(void);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_video_h_ */
