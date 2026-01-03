#include <blend2d/blend2d.h>

#include "target_pixels.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// Evenly sample up to max_samples pixels into out_rgb (RGB8 packed).
static BLResult sample_image_rgb8(const BLImageData *data,
                                  unsigned char *out_rgb,
                                  uint32_t *actual_samples) {
  if (!data || !out_rgb || !actual_samples)
    return BL_ERROR_INVALID_VALUE;
  if (data->size.w <= 0 || data->size.h <= 0)
    return BL_ERROR_INVALID_VALUE;

  const int32_t width = data->size.w;
  const int32_t height = data->size.h;
  const size_t stride =
      (size_t)(data->stride >= 0 ? data->stride : -data->stride);
  const uint8_t *row0 = (const uint8_t *)data->pixel_data;
  if (data->stride < 0) {
    row0 += (size_t)(height - 1) * stride; // Handle bottom-up layout.
  }

  const uint64_t total_pixels = (uint64_t)width * (uint64_t)height;
  const uint32_t wanted = TARGET_PIXELS;
  const uint32_t count =
      (uint32_t)(total_pixels < wanted ? total_pixels : wanted);
  if (count == 0)
    return BL_ERROR_INVALID_VALUE;

  // Map evenly across the flattened pixel grid.
  for (uint32_t i = 0; i < count; ++i) {
    uint64_t idx = (count == 1) ? 0 : (i * (total_pixels - 1)) / (count - 1);
    uint32_t y = (uint32_t)(idx / (uint64_t)width);
    uint32_t x = (uint32_t)(idx - (uint64_t)y * (uint64_t)width);

    const uint8_t *px =
        row0 + (size_t)y * stride + (size_t)x * 4u; // XRGB32 => B,G,R,X
    *out_rgb++ = px[2];                             // R
    *out_rgb++ = px[1];                             // G
    *out_rgb++ = px[0];                             // B
  }

  *actual_samples = count;
  return BL_SUCCESS;
}

int load_png_subsample(unsigned char out[], const char *filename,
                       uint32_t *out_count) {

  BLImageCore image;
  bl_image_init(&image);

  BLResult result = bl_image_read_from_file(&image, filename, NULL);
  if (result != BL_SUCCESS) {
    fprintf(stderr, "Failed to read image: code %u\n", (unsigned)result);
    bl_image_destroy(&image);
    return EXIT_FAILURE;
  }

  result = bl_image_convert(&image, BL_FORMAT_XRGB32);
  if (result != BL_SUCCESS) {
    fprintf(stderr, "Failed to convert image to XRGB32: code %u\n",
            (unsigned)result);
    bl_image_destroy(&image);
    return EXIT_FAILURE;
  }

  BLImageData data;
  result = bl_image_get_data(&image, &data);
  if (result != BL_SUCCESS) {
    fprintf(stderr, "Failed to query image data: code %u\n", (unsigned)result);
    bl_image_destroy(&image);
    return EXIT_FAILURE;
  }

  result = sample_image_rgb8(&data, out, out_count);
  if (result != BL_SUCCESS) {
    fprintf(stderr, "Sampling failed: code %u\n", (unsigned)result);
    bl_image_destroy(&image);
    return EXIT_FAILURE;
  }

  bl_image_destroy(&image);
  return EXIT_SUCCESS;
}
