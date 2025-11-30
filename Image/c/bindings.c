#include <lean/lean.h>
#include <stdio.h>
#include <string.h>

// 引入 stb_image
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

extern lean_object *lean_create_image_obj(uint32_t w, uint32_t h,
                                          lean_object *data);

LEAN_EXPORT lean_obj_res lean_load_image(b_lean_obj_arg path_obj) {
  const char *filename = lean_string_cstr(path_obj);

  int width, height, channels;
  unsigned char *img_data = stbi_load(filename, &width, &height, &channels, 4);

  if (img_data == NULL) {
    return lean_io_result_mk_error(
        lean_mk_io_user_error(lean_mk_string("Failed to load image")));
  }

  size_t data_size = (size_t)width * height;
  lean_object *uint32_array = lean_alloc_array(0, data_size);

  for (size_t i = 0; i < data_size; i++) {
    uint32_t pixel_value = (img_data[i * 4 + 0] << 16) | // R
                           (img_data[i * 4 + 1] << 8) |  // G
                           (img_data[i * 4 + 2] << 0) |  // B
                           (img_data[i * 4 + 3] << 24);  // A
    lean_object *boxed = lean_box_uint32((int32_t)pixel_value);
    uint32_array = lean_array_push(uint32_array, boxed);
  }

  stbi_image_free(img_data);

  lean_object *image_obj =
      lean_create_image_obj((uint32_t)width, (uint32_t)height, uint32_array);

  return lean_io_result_mk_ok(image_obj);
}
