/*
  Minimal SDL3 properties header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_properties_h_
#define SDL_properties_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * An identifier for a property container.
 *
 * \since This datatype is available since SDL 3.0.0.
 */
typedef Uint32 SDL_PropertiesID;

/**
 * An invalid property ID.
 *
 * \since This macro is available since SDL 3.0.0.
 */
#define SDL_PROPERTIES_ID_INVALID ((SDL_PropertiesID) 0)

/**
 * Get a property on a set of properties.
 *
 * \param props the properties to query
 * \param name the name of the property to retrieve
 * \param default_value the value to return if the property doesn't exist
 * \returns the property value, or default_value if it doesn't exist
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC SDL_PropertiesID SDLCALL SDL_GetGlobalProperties(void);

/**
 * Set a property on a set of properties.
 *
 * \param props the properties to modify
 * \param name the name of the property to set
 * \param value the value to set (can be NULL to remove a property)
 * \returns true if the property was set, false on error
 *
 * \threadsafety It is safe to call this function from any thread, however
 *               you must synchronize access to the same properties object
 *               yourself if you are setting properties from multiple threads.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC void* SDLCALL SDL_GetProperty(SDL_PropertiesID props, const char *name, void *default_value);

/**
 * Set a property on a set of properties.
 *
 * \param props the properties to modify
 * \param name the name of the property to set
 * \param value the value to set (can be NULL to remove a property)
 * \returns true if the property was set, false on error
 *
 * \threadsafety It is safe to call this function from any thread, however
 *               you must synchronize access to the same properties object
 *               yourself if you are setting properties from multiple threads.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC SDL_bool SDLCALL SDL_SetProperty(SDL_PropertiesID props, const char *name, const void *value);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_properties_h_ */
