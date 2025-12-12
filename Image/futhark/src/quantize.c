#include "../build/extract.h"
#include "load_image.h"
#include <stdio.h>
#include <time.h>

float diff_degrees(const float a, const float b) {
  return 180.0 - fabs(fabs(a - b) - 180.0);
}

// 检查是否与已选颜色冲突
static bool has_duplicate_hue(const double *chosen_hues, int chosen_count,
                              double hue, int difference_degrees) {
  for (int i = 0; i < chosen_count; i++) {
    if (diff_degrees(hue, chosen_hues[i]) < difference_degrees) {
      return true;
    }
  }
  return false;
}

// 从排序好的颜色中选择
// sorted_colors, sorted_hues:  Futhark返回的排序结果
// n: 颜色数量
// desired: 需要的颜色数量
// fallback_color: 备用颜色
// out_colors: 输出数组（调用者分配，至少 desired 大小）
// 返回:  实际选择的颜色数量
int choose_colors(const int32_t *sorted_colors, const float *sorted_hues, int n,
                  int desired, int32_t fallback_color, int32_t *out_colors) {

  double *chosen_hues = malloc(desired * sizeof(double));
  int chosen_count = 0;

  for (int difference_degrees = 90; difference_degrees >= 15;
       difference_degrees--) {
    chosen_count = 0;

    for (int i = 0; i < n && chosen_count < desired; i++) {
      double hue = sorted_hues[i];

      if (!has_duplicate_hue(chosen_hues, chosen_count, hue,
                             difference_degrees)) {
        out_colors[chosen_count] = sorted_colors[i];
        chosen_hues[chosen_count] = hue;
        chosen_count++;
      }
    }

    if (chosen_count >= desired)
      break;
  }

  free(chosen_hues);

  // 处理空结果
  if (chosen_count == 0) {
    out_colors[0] = fallback_color;
    return 1;
  }

  return chosen_count;
}

int main(int argc, char **argv) {
  if (argc != 2) {
    fprintf(stderr, "Usage: %s <input_image>\n", argv[0]);
    return 1;
  }

  int pixels_num;
  unsigned char *rgb = load_image_subsample(argv[1], 16384, &pixels_num);
  if (!rgb) {
    fprintf(stderr, "Failed to load image %s\n", argv[1]);
    return 1;
  }

  printf("Loaded %d pixels\n", pixels_num);

  struct timespec start, end;
  clock_gettime(CLOCK_MONOTONIC, &start);

  struct futhark_context_config *cfg = futhark_context_config_new();
  struct futhark_context *ctx = futhark_context_new(cfg);
  printf("Context created\n");
  int32_t out1ptr[128];
  float out2ptr[128];
  struct futhark_i32_1d *out1 = futhark_new_i32_1d(ctx, out1ptr, 128);
  struct futhark_f32_1d *out2 = futhark_new_f32_1d(ctx, out2ptr, 128);
  struct futhark_u8_2d *in1 = futhark_new_raw_u8_2d(ctx, rgb, pixels_num, 3);
  int64_t out0;
  int resCode = futhark_entry_extract_colors_and_scores(ctx, &out0, &out1,
                                                        &out2, 128, in1);
  futhark_context_sync(ctx);

  if (resCode != FUTHARK_SUCCESS) {
    char *err = futhark_context_get_error(ctx);
    fprintf(stderr, "Futhark error: %s\n", err);
    free(err);
    return 1;
  }

  int32_t out1_data[128];
  float out2_data[128];
  int res1 = futhark_values_i32_1d(ctx, out1, out1_data);
  int res2 = futhark_values_f32_1d(ctx, out2, out2_data);
  if (res1 != FUTHARK_SUCCESS || res2 != FUTHARK_SUCCESS) {
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
    printf("out[%d] = %X:%f\n", i, out1_data[i], out2_data[i]);
  }

  int chosen_colors[4];
  int chosen_count =
      choose_colors(out1_data, out2_data, out0, 4, 0x808080, chosen_colors);
  for (int i = 0; i < chosen_count; i++) {
    printf("Chosen color %d: %X\n", i, chosen_colors[i]);
  }

  // OS will clean up memory on exit, don't free it manually.
  return 0;
}
