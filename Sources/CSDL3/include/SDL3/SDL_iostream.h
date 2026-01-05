/*
  Minimal SDL3 iostream header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_iostream_h_
#define SDL_iostream_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * An opaque structure representing an I/O stream.
 *
 * \since This struct is available since SDL 3.0.0.
 */
typedef struct SDL_IOStream SDL_IOStream;

/**
 * Read from an SDL_IOStream.
 *
 * \param src the SDL_IOStream to read from
 * \param data a pointer to a buffer to read data into
 * \param size the size of each object to read, in bytes
 * \param numobjects the number of objects to read
 * \returns the number of objects read, or 0 on error or end of file
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC size_t SDLCALL SDL_ReadIO(SDL_IOStream *src, void *data, size_t size, size_t numobjects);

/**
 * Write to an SDL_IOStream.
 *
 * \param dst the SDL_IOStream to write to
 * \param data a pointer to a buffer containing data to write
 * \param size the size of each object to write, in bytes
 * \param numobjects the number of objects to write
 * \returns the number of objects written, or 0 on error
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC size_t SDLCALL SDL_WriteIO(SDL_IOStream *dst, const void *data, size_t size, size_t numobjects);

/**
 * Close and free an SDL_IOStream.
 *
 * \param context the SDL_IOStream to close
 * \returns 0 on success or a negative error code on failure
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL SDL_CloseIO(SDL_IOStream *context);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_iostream_h_ */
