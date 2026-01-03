#include "../build/extract.h"
#include "load_image.h"
#include <lean/lean.h>
#include <math.h>
#include <stdlib.h>

// Helper functions (same as your original code)
static float diff_degrees(const float a, const float b) {
  return 180.0f - fabsf(fabsf(a - b) - 180.0f);
}

static bool has_duplicate_hue(const double *chosen_hues, int chosen_count,
                              double hue, int difference_degrees) {
  for (int i = 0; i < chosen_count; i++) {
    if (diff_degrees(hue, chosen_hues[i]) < difference_degrees) {
      return true;
    }
  }
  return false;
}

static int choose_colors(const int32_t *sorted_colors, const float *sorted_hues,
                         int n, int desired, int32_t fallback_color,
                         int32_t *out_colors) {
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
  if (chosen_count == 0) {
    out_colors[0] = fallback_color;
    return 1;
  }
  return chosen_count;
}

// Lean FFI:  Extract colors from image
// Returns: (Array UInt32 × UInt32) encoded as a Lean object
// The second element is the actual count of colors extracted
LEAN_EXPORT lean_obj_res lean_extract_colors(b_lean_obj_arg path_obj,
                                             uint32_t desired_count) {
  // Get the file path string from Lean
  const char *path = lean_string_cstr(path_obj);

  // Clamp desired_count to reasonable bounds
  if (desired_count > 128)
    desired_count = 128;
  if (desired_count == 0)
    desired_count = 1;

  // Load image
  uint32_t pixels_num;
  // unsigned char *rgb = load_image_subsample(path, &pixels_num);
  unsigned char rgb[60000];
  int rescode = load_image_subsample(rgb, path, &pixels_num);
  // if (!rgb) {
  //   // Return empty array with count 0 on failure
  //   lean_obj_res arr = lean_alloc_array(0, 0);
  //   lean_obj_res result = lean_alloc_ctor(0, 2, 0);
  //   lean_ctor_set(result, 0, arr);
  //   lean_ctor_set(result, 1, lean_box_uint32(0));
  //   return result;
  // }
  if (rescode) {
    // Return empty array with count 0 on failure
    lean_obj_res arr = lean_alloc_array(0, 0);
    lean_obj_res result = lean_alloc_ctor(0, 2, 0);
    lean_ctor_set(result, 0, arr);
    lean_ctor_set(result, 1, lean_box_uint32(0));
    return result;
  }

  // Initialize Futhark context
  struct futhark_context_config *cfg = futhark_context_config_new();
  struct futhark_context *ctx = futhark_context_new(cfg);

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
    // Cleanup and return empty on error
    futhark_free_i32_1d(ctx, out1);
    futhark_free_f32_1d(ctx, out2);
    futhark_free_u8_2d(ctx, in1);
    futhark_context_free(ctx);
    futhark_context_config_free(cfg);
    // free(rgb);

    lean_obj_res arr = lean_alloc_array(0, 0);
    lean_obj_res result = lean_alloc_ctor(0, 2, 0);
    lean_ctor_set(result, 0, arr);
    lean_ctor_set(result, 1, lean_box_uint32(0));
    return result;
  }

  // Read results
  int32_t out1_data[128];
  float out2_data[128];
  futhark_values_i32_1d(ctx, out1, out1_data);
  futhark_values_f32_1d(ctx, out2, out2_data);

  // Choose colors
  int32_t *chosen_colors = malloc(desired_count * sizeof(int32_t));
  int chosen_count = choose_colors(out1_data, out2_data, (int)out0,
                                   (int)desired_count, 0x808080, chosen_colors);

  // Create Lean array
  lean_obj_res arr = lean_alloc_array(chosen_count, chosen_count);
  for (int i = 0; i < chosen_count; i++) {
    lean_array_set_core(arr, i, lean_box_uint32((uint32_t)chosen_colors[i]));
  }

  free(chosen_colors);

  // Cleanup Futhark resources
  futhark_free_i32_1d(ctx, out1);
  futhark_free_f32_1d(ctx, out2);
  futhark_free_u8_2d(ctx, in1);
  futhark_context_free(ctx);
  futhark_context_config_free(cfg);
  // free(rgb);

  // Return tuple (Array UInt32, UInt32)
  lean_obj_res result = lean_alloc_ctor(0, 2, 0);
  lean_ctor_set(result, 0, arr);
  lean_ctor_set(result, 1, lean_box_uint32((uint32_t)chosen_count));
  return result;
}
