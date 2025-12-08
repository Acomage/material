#include "../build/wu.h"
#include "load_image.h"
#include <stdio.h>
#include <time.h>

int main(int argc, char **argv) {
  if (argc != 2) {
    fprintf(stderr, "Usage: %s <input_image>\n", argv[0]);
    return 1;
  }

  int w, h;
  unsigned char *rgb = load_image_subsample(argv[1], 16384, &w, &h);
  if (!rgb) {
    fprintf(stderr, "Failed to load image %s\n", argv[1]);
    return 1;
  }

  printf("Loaded %dx%d RGB image\n", w, h);

  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC, &start);

  struct futhark_context_config *cfg = futhark_context_config_new();
  struct futhark_context *ctx = futhark_context_new(cfg);
  printf("Context created\n");
  int32_t out1ptr[128];
  struct futhark_i32_1d *out1 = futhark_new_i32_1d(ctx, out1ptr, 128);
  struct futhark_u8_2d *in1 = futhark_new_raw_u8_2d(ctx, rgb, h * w, 3);
  int64_t out0;
  int resCode = futhark_entry_quantize(ctx, &out0, &out1, 128, in1);
  futhark_context_sync(ctx);

  if (resCode != FUTHARK_SUCCESS) {
    char *err = futhark_context_get_error(ctx);
    fprintf(stderr, "Futhark error: %s\n", err);
    free(err);
    return 1;
  }

  int32_t out_data[128];
  int res = futhark_values_i32_1d(ctx, out1, out_data);
  if (res != FUTHARK_SUCCESS) {
    char *err = futhark_context_get_error(ctx);
    fprintf(stderr, "Futhark error when reading output: %s\n", err);
    free(err);
    return 1;
  }

  clock_gettime(CLOCK_MONOTONIC, &end);

  double elapsed =
      (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;

  printf("Computation took %.10f seconds\n", elapsed);

  for (int i = 0; i < out0; i++) {
    printf("out[%d] = %X\n", i, out_data[i]);
  }
  // OS will clean up memory on exit, don't free it manually.
  // futhark_free_u8_2d(ctx, in1);
  // futhark_free_i32_1d(ctx, out1);
  // futhark_context_free(ctx);
  // futhark_context_config_free(cfg);
  // free(rgb);
  return 0;
}
