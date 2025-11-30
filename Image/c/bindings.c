#include <lean/lean.h>
#include <stdio.h>
#include <string.h>

// 引入 stb_image
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

// 声明我们在 Lean 中导出的构造函数
// 注意：Lean 中的 UInt32 在 C 中对应 uint32_t（无装箱）
extern lean_object *lean_create_image_obj(uint32_t w, uint32_t h,
                                          lean_object *data);

LEAN_EXPORT lean_obj_res lean_load_image(b_lean_obj_arg path_obj) {
  // 1. 获取文件路径 (无需释放，因为是 borrowed)
  const char *filename = lean_string_cstr(path_obj);

  // 2. 使用 stb_image 加载图片
  int width, height, channels;
  // 强制加载为期望的通道数（例如 0 表示按原样加载，3 表示 RGB，4 表示 RGBA）
  unsigned char *img_data = stbi_load(filename, &width, &height, &channels, 4);

  if (img_data == NULL) {
    // 加载失败，返回 IO Error
    return lean_io_result_mk_error(
        lean_mk_io_user_error(lean_mk_string("Failed to load image")));
  }

  // 3. 创建 Lean ByteArray
  // size_t 是字节大小
  size_t data_size = (size_t)width * height * channels;
  // 分配一个 sarray (scalar array)，元素大小为 1 字节
  lean_object *byte_array = lean_alloc_sarray(1, data_size, data_size);

  // 4. 将 stb 的数据拷贝到 Lean 的 ByteArray 中
  // lean_sarray_cptr 获取指向 ByteArray 数据区域的指针
  memcpy(lean_sarray_cptr(byte_array), img_data, data_size);

  // 5. 释放 stb 分配的原始内存
  stbi_image_free(img_data);

  // 6. 调用 Lean 导出的构造函数创建 Image 对象
  // 注意：byte_array 的所有权在这里被传递给了 lean_create_image_obj
  lean_object *image_obj =
      lean_create_image_obj((uint32_t)width, (uint32_t)height, byte_array);

  // 7. 返回 IO Result Ok
  return lean_io_result_mk_ok(image_obj);
}
