#include <math.h>
#include <png.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <turbojpeg.h>

// 计算采样步长：确保采样数 >= target_pixels 且尽可能接近
static int calculate_step(int total_pixels, int target_pixels) {
  if (target_pixels >= total_pixels)
    return 1;

  // step 使得 ceil(total / step) >= target
  // 即 step <= total / target
  int step = total_pixels / target_pixels;
  return step < 1 ? 1 : step;
}

// 计算按 step 采样后的实际像素数
static int calculate_sampled_count(int total_pixels, int step) {
  return (total_pixels + step - 1) / step;
}

unsigned char *load_png_subsample(const char *filename, int target_pixels,
                                  int *out_count) {
  FILE *fp = fopen(filename, "rb");
  if (!fp)
    return NULL;

  png_byte header[8];
  if (fread(header, 1, 8, fp) != 8 || png_sig_cmp(header, 0, 8)) {
    fclose(fp);
    return NULL;
  }

  png_structp png_ptr =
      png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if (!png_ptr) {
    fclose(fp);
    return NULL;
  }

  png_infop info_ptr = png_create_info_struct(png_ptr);
  if (!info_ptr) {
    png_destroy_read_struct(&png_ptr, NULL, NULL);
    fclose(fp);
    return NULL;
  }

  if (setjmp(png_jmpbuf(png_ptr))) {
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(fp);
    return NULL;
  }

  png_init_io(png_ptr, fp);
  png_set_sig_bytes(png_ptr, 8);
  png_read_info(png_ptr, info_ptr);

  int width = png_get_image_width(png_ptr, info_ptr);
  int height = png_get_image_height(png_ptr, info_ptr);
  int bit_depth = png_get_bit_depth(png_ptr, info_ptr);
  int color_type = png_get_color_type(png_ptr, info_ptr);

  // 归一化到 RGB8
  if (color_type == PNG_COLOR_TYPE_PALETTE)
    png_set_palette_to_rgb(png_ptr);
  if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8)
    png_set_expand_gray_1_2_4_to_8(png_ptr);
  if (png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS))
    png_set_tRNS_to_alpha(png_ptr);
  if (bit_depth == 16)
    png_set_strip_16(png_ptr);
  if (color_type == PNG_COLOR_TYPE_GRAY ||
      color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
    png_set_gray_to_rgb(png_ptr);
  if (color_type & PNG_COLOR_MASK_ALPHA)
    png_set_strip_alpha(png_ptr);

  png_read_update_info(png_ptr, info_ptr);

  int row_bytes = png_get_rowbytes(png_ptr, info_ptr);
  png_bytep row = malloc(row_bytes);
  if (!row) {
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(fp);
    return NULL;
  }

  // 计算采样步长（将图像视为一维像素流）
  int total_pixels = width * height;
  int step = calculate_step(total_pixels, target_pixels);
  int sampled_count = calculate_sampled_count(total_pixels, step);

  unsigned char *out = malloc(sampled_count * 3);
  if (!out) {
    free(row);
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(fp);
    return NULL;
  }

  int pixel_index = 0; // 当前像素的一维索引
  int next_sample = 0; // 下一个要采样的像素索引
  int out_pos = 0;

  for (int y = 0; y < height; y++) {
    png_read_row(png_ptr, row, NULL);

    // 检查这一行是否有需要采样的像素
    int row_start = y * width;
    int row_end = row_start + width;

    while (next_sample < row_end && next_sample < total_pixels) {
      int x = next_sample - row_start;
      out[out_pos++] = row[x * 3 + 0];
      out[out_pos++] = row[x * 3 + 1];
      out[out_pos++] = row[x * 3 + 2];
      next_sample += step;
    }
  }

  free(row);
  png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
  fclose(fp);

  *out_count = out_pos / 3;
  return out;
}

unsigned char *load_jpeg_subsample(const char *filename, int target_pixels,
                                   int *out_count) {
  FILE *fp = fopen(filename, "rb");
  if (!fp)
    return NULL;

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  fseek(fp, 0, SEEK_SET);

  unsigned char *buf = malloc(size);
  if (!buf) {
    fclose(fp);
    return NULL;
  }
  fread(buf, 1, size, fp);
  fclose(fp);

  tjhandle tj = tjInitDecompress();
  if (!tj) {
    free(buf);
    return NULL;
  }

  int width, height, subsamp, colorspace;
  if (tjDecompressHeader3(tj, buf, size, &width, &height, &subsamp,
                          &colorspace) < 0) {
    free(buf);
    tjDestroy(tj);
    return NULL;
  }

  int total_pixels = width * height;
  int step = calculate_step(total_pixels, target_pixels);

  // 选择最接近的缩放因子，使解码后像素数 >= 采样所需
  int nsf = 0;
  tjscalingfactor *sfs = tjGetScalingFactors(&nsf);

  int best_num = 1, best_den = 1;
  int best_decoded_pixels = total_pixels;

  for (int i = 0; i < nsf; i++) {
    int sw = TJSCALED(width, sfs[i]);
    int sh = TJSCALED(height, sfs[i]);
    int decoded_pixels = sw * sh;

    // 解码后像素数必须足够进行采样
    int decoded_step = calculate_step(decoded_pixels, target_pixels);
    int sampled = calculate_sampled_count(decoded_pixels, decoded_step);

    if (sampled >= target_pixels && decoded_pixels < best_decoded_pixels) {
      best_decoded_pixels = decoded_pixels;
      best_num = sfs[i].num;
      best_den = sfs[i].denom;
    }
  }

  int dec_w = TJSCALED(width, ((tjscalingfactor){best_num, best_den}));
  int dec_h = TJSCALED(height, ((tjscalingfactor){best_num, best_den}));
  int decoded_pixels = dec_w * dec_h;

  unsigned char *rgb = malloc(decoded_pixels * 3);
  if (!rgb) {
    free(buf);
    tjDestroy(tj);
    return NULL;
  }

  if (tjDecompress2(tj, buf, size, rgb, dec_w, 0, dec_h, TJPF_RGB,
                    TJFLAG_FASTDCT | TJFLAG_FASTUPSAMPLE) < 0) {
    free(rgb);
    free(buf);
    tjDestroy(tj);
    return NULL;
  }

  free(buf);
  tjDestroy(tj);

  // 从解码后的图像中均匀采样
  int sample_step = calculate_step(decoded_pixels, target_pixels);
  int sampled_count = calculate_sampled_count(decoded_pixels, sample_step);

  unsigned char *out = malloc(sampled_count * 3);
  if (!out) {
    free(rgb);
    return NULL;
  }

  int out_pos = 0;
  for (int i = 0; i < decoded_pixels; i += sample_step) {
    out[out_pos++] = rgb[i * 3 + 0];
    out[out_pos++] = rgb[i * 3 + 1];
    out[out_pos++] = rgb[i * 3 + 2];
  }

  free(rgb);

  *out_count = out_pos / 3;
  return out;
}

unsigned char *load_image_subsample(const char *filename, int target_pixels,
                                    int *out_count) {
  const char *ext = strrchr(filename, '.');
  if (!ext)
    return NULL;
  ext++;

  if (!strcasecmp(ext, "png"))
    return load_png_subsample(filename, target_pixels, out_count);

  if (!strcasecmp(ext, "jpg") || !strcasecmp(ext, "jpeg"))
    return load_jpeg_subsample(filename, target_pixels, out_count);

  return NULL;
}
