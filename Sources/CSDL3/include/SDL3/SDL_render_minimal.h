// Minimal SDL3 render header - forward declarations only
// No copyright - this is a minimal stub for Swift interop

#ifndef SDL_render_h_
#define SDL_render_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_rect.h>
#include <SDL3/SDL_pixels.h>
#include <SDL3/SDL_surface.h>
#include <SDL3/SDL_video.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque renderer handle
typedef struct SDL_Renderer SDL_Renderer;

// Opaque texture handle
typedef struct SDL_Texture SDL_Texture;

// Renderer logical presentation enum
typedef enum {
    SDL_LOGICAL_PRESENTATION_DISABLED = 0,
    SDL_LOGICAL_PRESENTATION_STRETCH = 4,
    SDL_LOGICAL_PRESENTATION_LETTERBOX = 1,
    SDL_LOGICAL_PRESENTATION_OVERSCAN = 2,
    SDL_LOGICAL_PRESENTATION_INTEGER_SCALE = 3
} SDL_RendererLogicalPresentation;

// Function declarations - only what's used
extern SDL_DECLSPEC SDL_Renderer * SDLCALL SDL_CreateRenderer(SDL_Window *window, const char *name);
extern SDL_DECLSPEC void SDLCALL SDL_SetRenderDrawColor(SDL_Renderer *renderer, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
extern SDL_DECLSPEC int SDLCALL SDL_RenderClear(SDL_Renderer *renderer);
extern SDL_DECLSPEC int SDLCALL SDL_RenderFillRect(SDL_Renderer *renderer, const SDL_FRect *rect);
extern SDL_DECLSPEC int SDLCALL SDL_RenderRect(SDL_Renderer *renderer, const SDL_FRect *rect);
extern SDL_DECLSPEC void SDLCALL SDL_RenderPresent(SDL_Renderer *renderer);
extern SDL_DECLSPEC SDL_Texture * SDLCALL SDL_CreateTextureFromSurface(SDL_Renderer *renderer, SDL_Surface *surface);
extern SDL_DECLSPEC void SDLCALL SDL_DestroyTexture(SDL_Texture *texture);
extern SDL_DECLSPEC int SDLCALL SDL_GetTextureSize(SDL_Texture *texture, float *w, float *h);
extern SDL_DECLSPEC int SDLCALL SDL_RenderTexture(SDL_Renderer *renderer, SDL_Texture *texture, const SDL_FRect *srcrect, const SDL_FRect *dstrect);
extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderLogicalPresentation(SDL_Renderer *renderer, int w, int h, SDL_RendererLogicalPresentation mode);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_render_h_ */
