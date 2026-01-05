/*
  Minimal SDL3 rect header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_rect_h_
#define SDL_rect_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Point structures */
typedef struct SDL_Point {
    int x;
    int y;
} SDL_Point;

typedef struct SDL_FPoint {
    float x;
    float y;
} SDL_FPoint;

/* Rectangle structures */
typedef struct SDL_Rect {
    int x, y;
    int w, h;
} SDL_Rect;

typedef struct SDL_FRect {
    float x;
    float y;
    float w;
    float h;
} SDL_FRect;

/* Function declarations - only what's needed */
extern SDL_DECLSPEC bool SDLCALL SDL_RectEmpty(const SDL_Rect *rect);
extern SDL_DECLSPEC bool SDLCALL SDL_RectEmptyFloat(const SDL_FRect *rect);
extern SDL_DECLSPEC bool SDLCALL SDL_RectsEqual(const SDL_Rect *a, const SDL_Rect *b);
extern SDL_DECLSPEC bool SDLCALL SDL_RectsEqualFloat(const SDL_FRect *a, const SDL_FRect *b);
extern SDL_DECLSPEC bool SDLCALL SDL_HasRectIntersection(const SDL_Rect *A, const SDL_Rect *B);
extern SDL_DECLSPEC bool SDLCALL SDL_HasRectIntersectionFloat(const SDL_FRect *A, const SDL_FRect *B);
extern SDL_DECLSPEC bool SDLCALL SDL_GetRectIntersection(const SDL_Rect *A, const SDL_Rect *B, SDL_Rect *result);
extern SDL_DECLSPEC bool SDLCALL SDL_GetRectIntersectionFloat(const SDL_FRect *A, const SDL_FRect *B, SDL_FRect *result);
extern SDL_DECLSPEC void SDLCALL SDL_GetRectUnion(const SDL_Rect *A, const SDL_Rect *B, SDL_Rect *result);
extern SDL_DECLSPEC void SDLCALL SDL_GetRectUnionFloat(const SDL_FRect *A, const SDL_FRect *B, SDL_FRect *result);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_rect_h_ */
