#ifndef LANE_IMAGE_H
#define LANE_IMAGE_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

/**
 * The value of a color channel at a specific location.
 */
typedef uint8_t		lane_color_t;

/**
 * @inheritDoc
 */
typedef struct pixel	lane_pixel_t;

/**
 * @inheritDoc
 */
typedef struct image	lane_image_t;

/**
 * A dot on the screen with a mixture of red, green, and blue colors.
 */
struct pixel {
	lane_color_t r, g, b;
};

/**
 * A representation of an image.<br />
 * <br />
 * The data is horizontally stored in a 2d array.
 */
struct image {
	uint16_t width, height;
	lane_pixel_t *data;
};

/**
 * Allocates a blank new image.
 *
 * @param width		The width in pixels of the new image
 * @param height	The height in pixels of the new image
 * @return		A pointer to the struct
 */
lane_image_t *lane_image_new(uint16_t width, uint16_t height);

/**
 * Deallocates an image and its associated data.
 *
 * @param image		The image to be deallocated
 */
void lane_image_free(lane_image_t *image);

#endif /* LANE_IMAGE_H */

