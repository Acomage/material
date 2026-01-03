#include "jpg.h"
#include "png.h"
#include <string.h>

int load_image_subsample(unsigned char rgb[], const char *filename,
                         uint32_t *out_count) {
  const char *ext = strrchr(filename, '.');
  if (!ext)
    return 1;
  ext++;

  if (!strcasecmp(ext, "png"))
    return load_png_subsample(rgb, filename, out_count);

  if (!strcasecmp(ext, "jpg") || !strcasecmp(ext, "jpeg"))
    return load_jpeg_subsample(rgb, filename, out_count);

  return 1;
}
