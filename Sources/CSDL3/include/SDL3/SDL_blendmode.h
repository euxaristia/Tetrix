/*
  Minimal SDL3 blendmode header - Swift-native replacement
  Only includes the minimal definitions needed for SDL3 interop
*/

#ifndef SDL_blendmode_h_
#define SDL_blendmode_h_

#include <SDL3/SDL_stdinc.h>
#include <SDL3/SDL_begin_code.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * The blend mode used in SDL_RenderGeometry() and drawing operations.
 *
 * \since This enum is available since SDL 3.0.0.
 */
typedef enum SDL_BlendMode
{
    SDL_BLENDMODE_NONE = 0x00000000,     /**< no blending */
    SDL_BLENDMODE_BLEND = 0x00000001,    /**< alpha blending */
    SDL_BLENDMODE_ADD = 0x00000002,      /**< additive blending */
    SDL_BLENDMODE_MOD = 0x00000004,      /**< color modulate */
    SDL_BLENDMODE_MUL = 0x00000008,      /**< color multiply */
    SDL_BLENDMODE_INVALID = 0x7FFFFFFF   /**< invalid blend mode */
} SDL_BlendMode;

/**
 * Blend factors.
 *
 * \since This enum is available since SDL 3.0.0.
 */
typedef enum SDL_BlendFactor
{
    SDL_BLENDFACTOR_ZERO = 0x1,      /**< 0, 0, 0, 0 */
    SDL_BLENDFACTOR_ONE = 0x2,       /**< 1, 1, 1, 1 */
    SDL_BLENDFACTOR_SRC_COLOR = 0x3, /**< srcR, srcG, srcB, srcA */
    SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR = 0x4, /**< 1-srcR, 1-srcG, 1-srcB, 1-srcA */
    SDL_BLENDFACTOR_SRC_ALPHA = 0x5, /**< srcA, srcA, srcA, srcA */
    SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA = 0x6, /**< 1-srcA, 1-srcA, 1-srcA, 1-srcA */
    SDL_BLENDFACTOR_DST_COLOR = 0x7, /**< dstR, dstG, dstB, dstA */
    SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR = 0x8, /**< 1-dstR, 1-dstG, 1-dstB, 1-dstA */
    SDL_BLENDFACTOR_DST_ALPHA = 0x9, /**< dstA, dstA, dstA, dstA */
    SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA = 0xA  /**< 1-dstA, 1-dstA, 1-dstA, 1-dstA */
} SDL_BlendFactor;

/**
 * Blend operations.
 *
 * \since This enum is available since SDL 3.0.0.
 */
typedef enum SDL_BlendOperation
{
    SDL_BLENDOPERATION_ADD = 0x1,      /**< destination + source */
    SDL_BLENDOPERATION_SUBTRACT = 0x2, /**< destination - source */
    SDL_BLENDOPERATION_REV_SUBTRACT = 0x3, /**< source - destination */
    SDL_BLENDOPERATION_MINIMUM = 0x4,  /**< min(destination, source) */
    SDL_BLENDOPERATION_MAXIMUM = 0x5   /**< max(destination, source) */
} SDL_BlendOperation;

/**
 * Compose a custom blend mode for renderers.
 *
 * \param srcColorFactor the source color factor
 * \param dstColorFactor the destination color factor
 * \param colorOperation the color operation
 * \param srcAlphaFactor the source alpha factor
 * \param dstAlphaFactor the destination alpha factor
 * \param alphaOperation the alpha operation
 * \returns an SDL_BlendMode that represents the chosen factors and operations,
 *          or SDL_BLENDMODE_INVALID if there's an error
 *
 * \threadsafety It is safe to call this function from any thread.
 *
 * \since This function is available since SDL 3.0.0.
 */
extern SDL_DECLSPEC SDL_BlendMode SDLCALL SDL_ComposeCustomBlendMode(
    SDL_BlendFactor srcColorFactor,
    SDL_BlendFactor dstColorFactor,
    SDL_BlendOperation colorOperation,
    SDL_BlendFactor srcAlphaFactor,
    SDL_BlendFactor dstAlphaFactor,
    SDL_BlendOperation alphaOperation);

#ifdef __cplusplus
}
#endif

#include <SDL3/SDL_close_code.h>

#endif /* SDL_blendmode_h_ */
