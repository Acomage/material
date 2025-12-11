#include "../build/celebi.h"
#include "load_image.h"
#include <stdio.h>
#include <time.h>

typedef struct {
  int32_t key;   // arr2 的值
  int32_t index; // 原始下标
} Pair;

int cmp_pair(const void *a, const void *b) {
  const Pair *pa = (const Pair *)a;
  const Pair *pb = (const Pair *)b;
  return (pa->key - pb->key); // 升序
}

void reorder(int32_t *arr1, int32_t *arr2, int64_t n) {
  Pair *tmp = malloc(sizeof(Pair) * n);
  for (int i = 0; i < n; i++) {
    tmp[i].key = arr2[i];
    tmp[i].index = i;
  }

  // 按 arr2 的值排序
  qsort(tmp, n, sizeof(Pair), cmp_pair);

  // 创建新数组以按排序顺序保存结果
  int *new_arr1 = malloc(sizeof(int32_t) * n);
  int *new_arr2 = malloc(sizeof(int32_t) * n);

  for (int i = 0; i < n; i++) {
    int old = tmp[i].index;
    new_arr1[i] = arr1[old];
    new_arr2[i] = arr2[old];
  }

  // 写回原数组前 n 项
  for (int i = 0; i < n; i++) {
    arr1[i] = new_arr1[i];
    arr2[i] = new_arr2[i];
  }

  free(tmp);
  free(new_arr1);
  free(new_arr2);
}

int main(int argc, char **argv) {
  if (argc != 2) {
    fprintf(stderr, "Usage: %s <input_image>\n", argv[0]);
    return 1;
  }

  // int w, h;
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
  int32_t out1ptr[128], out2ptr[128];
  struct futhark_i32_1d *out1 = futhark_new_i32_1d(ctx, out1ptr, 128);
  struct futhark_i32_1d *out2 = futhark_new_i32_1d(ctx, out2ptr, 128);
  struct futhark_u8_2d *in1 = futhark_new_raw_u8_2d(ctx, rgb, pixels_num, 3);
  int64_t out0;
  int resCode =
      futhark_entry_quantize_celebi(ctx, &out0, &out1, &out2, 128, in1);
  futhark_context_sync(ctx);

  if (resCode != FUTHARK_SUCCESS) {
    char *err = futhark_context_get_error(ctx);
    fprintf(stderr, "Futhark error: %s\n", err);
    free(err);
    return 1;
  }

  int32_t out1_data[128], out2_data[128];
  int res1 = futhark_values_i32_1d(ctx, out1, out1_data);
  int res2 = futhark_values_i32_1d(ctx, out2, out2_data);
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

  reorder(out1_data, out2_data, out0);
  int32_t sum = 0;
  for (int i = 0; i < out0; i++) {
    printf("out[%d] = %X:%i\n", i, out1_data[i], out2_data[i]);
    sum += out2_data[i];
  }
  printf("sum: %d\n", sum);
  // OS will clean up memory on exit, don't free it manually.
  // futhark_free_u8_2d(ctx, in1);
  // futhark_free_i32_1d(ctx, out1);
  // futhark_context_free(ctx);
  // futhark_context_config_free(cfg);
  // free(rgb);
  return 0;
}
