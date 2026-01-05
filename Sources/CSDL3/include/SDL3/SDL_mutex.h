/*
  Minimal SDL3 mutex header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_mutex_h_
#define SDL_mutex_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * An opaque mutex structure.
 *
 * \since This struct is available since SDL 3.0.0.
 */
typedef struct SDL_Mutex SDL_Mutex;

/**
 * Create a mutex.
 *
 * \returns a new mutex or NULL on failure
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC SDL_Mutex * SDLCALL SDL_CreateMutex(void);

/**
 * Lock a mutex.
 *
 * \param mutex the mutex to lock
 * \returns 0 on success or a negative error code on failure
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL SDL_LockMutex(SDL_Mutex *mutex);

/**
 * Try to lock a mutex without blocking.
 *
 * \param mutex the mutex to try to lock
 * \returns 0 if the mutex was locked, SDL_MUTEX_TIMEDOUT if it would block, or a negative error code on failure
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL SDL_TryLockMutex(SDL_Mutex *mutex);

/**
 * Unlock a mutex.
 *
 * \param mutex the mutex to unlock
 * \returns 0 on success or a negative error code on failure
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC int SDLCALL SDL_UnlockMutex(SDL_Mutex *mutex);

/**
 * Destroy a mutex.
 *
 * \param mutex the mutex to destroy
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC void SDLCALL SDL_DestroyMutex(SDL_Mutex *mutex);

/* Mutex timeout constant */
#define SDL_MUTEX_TIMEDOUT 1

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_mutex_h_ */
