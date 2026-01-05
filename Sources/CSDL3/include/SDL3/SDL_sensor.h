/*
  Minimal SDL3 sensor header - Swift-native replacement
  Stub header for SDL_events.h compatibility
*/

#ifndef SDL_sensor_h_
#define SDL_sensor_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Sensor ID type - minimal stub */
typedef Uint32 SDL_SensorID;

/* Sensor types - minimal stub */
typedef enum SDL_SensorType {
    SDL_SENSOR_INVALID = -1,
    SDL_SENSOR_UNKNOWN,
    SDL_SENSOR_ACCEL,
    SDL_SENSOR_GYRO,
    SDL_SENSOR_ACCEL_L,
    SDL_SENSOR_GYRO_L
} SDL_SensorType;

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_sensor_h_ */
