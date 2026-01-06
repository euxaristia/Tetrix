/* Clean replacement for SDL_error.h - no copyright dependencies */

#ifndef SDL_error_h_
#define SDL_error_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

#include <stdarg.h>

/* Error message functions - declarations only, implementations in SDL3.dll */
extern SDL_DECLSPEC const char * SDLCALL SDL_GetError(void);
extern SDL_DECLSPEC void SDLCALL SDL_ClearError(void);
extern SDL_DECLSPEC bool SDLCALL SDL_SetError(SDL_PRINTF_FORMAT_STRING const char *fmt, ...) SDL_PRINTF_VARARG_FUNC(1);
extern SDL_DECLSPEC bool SDLCALL SDL_SetErrorV(SDL_PRINTF_FORMAT_STRING const char *fmt, va_list ap) SDL_PRINTF_VARARG_FUNCV(1);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_error_h_ */
