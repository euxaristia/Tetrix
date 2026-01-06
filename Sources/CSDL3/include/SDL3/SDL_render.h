/* Clean replacement for SDL_render.h - no copyright dependencies */

#ifndef SDL_render_h_
#define SDL_render_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_blendmode.h>
#include <SDL3/SDL_error.h>
#include <SDL3/SDL_events.h>
#include <SDL3/SDL_pixels.h>
#include <SDL3/SDL_properties.h>
#include <SDL3/SDL_rect.h>
#include <SDL3/SDL_surface.h>
#include <SDL3/SDL_video.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Renderer logical presentation modes */
typedef enum SDL_RendererLogicalPresentation
{
    SDL_LOGICAL_PRESENTATION_DISABLED,
    SDL_LOGICAL_PRESENTATION_STRETCH,
    SDL_LOGICAL_PRESENTATION_LETTERBOX,
    SDL_LOGICAL_PRESENTATION_OVERSCAN,
    SDL_LOGICAL_PRESENTATION_INTEGER_SCALE
} SDL_RendererLogicalPresentation;

/* Forward declarations */
typedef struct SDL_Renderer SDL_Renderer;

/* Texture structure - opaque type for Swift interop */
typedef struct SDL_Texture {
    void *opaque;  /* Opaque pointer - Swift needs a non-empty struct */
} SDL_Texture;

/* Renderer functions */
extern SDL_DECLSPEC SDL_Renderer * SDLCALL SDL_CreateRenderer(SDL_Window *window, const char *name);

/* Renderer logical presentation */
extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderLogicalPresentation(SDL_Renderer *renderer, int w, int h, SDL_RendererLogicalPresentation mode);

/* Drawing functions */
extern SDL_DECLSPEC bool SDLCALL SDL_SetRenderDrawColor(SDL_Renderer *renderer, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
extern SDL_DECLSPEC bool SDLCALL SDL_RenderClear(SDL_Renderer *renderer);
extern SDL_DECLSPEC bool SDLCALL SDL_RenderRect(SDL_Renderer *renderer, const SDL_FRect *rect);
extern SDL_DECLSPEC bool SDLCALL SDL_RenderFillRect(SDL_Renderer *renderer, const SDL_FRect *rect);
extern SDL_DECLSPEC bool SDLCALL SDL_RenderTexture(SDL_Renderer *renderer, SDL_Texture *texture, const SDL_FRect *srcrect, const SDL_FRect *dstrect);
extern SDL_DECLSPEC bool SDLCALL SDL_RenderPresent(SDL_Renderer *renderer);

/* Texture functions */
extern SDL_DECLSPEC SDL_Texture * SDLCALL SDL_CreateTextureFromSurface(SDL_Renderer *renderer, SDL_Surface *surface);
extern SDL_DECLSPEC bool SDLCALL SDL_GetTextureSize(SDL_Texture *texture, int *w, int *h);
extern SDL_DECLSPEC void SDLCALL SDL_DestroyTexture(SDL_Texture *texture);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_render_h_ */
