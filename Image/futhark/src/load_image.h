#include <ctype.h>
#include <math.h>
#include <png.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <turbojpeg.h>

unsigned char *load_png_as_rgb(const char *filename, int *out_width,
                               int *out_height) {
  FILE *fp = fopen(filename, "rb");
  if (!fp) {
    fprintf(stderr, "Error: cannot open file %s\n", filename);
    return NULL;
  }

  // Read PNG header
  png_byte header[8];
  if (fread(header, 1, 8, fp) != 8) {
    fprintf(stderr, "Error: cannot read PNG header\n");
    fclose(fp);
    return NULL;
  }

  if (png_sig_cmp(header, 0, 8)) {
    fprintf(stderr, "Error: file is not a valid PNG\n");
    fclose(fp);
    return NULL;
  }

  // Create PNG read struct
  png_structp png_ptr =
      png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if (!png_ptr) {
    fprintf(stderr, "Error: png_create_read_struct failed\n");
    fclose(fp);
    return NULL;
  }

  // Create PNG info struct
  png_infop info_ptr = png_create_info_struct(png_ptr);
  if (!info_ptr) {
    fprintf(stderr, "Error: png_create_info_struct failed\n");
    png_destroy_read_struct(&png_ptr, NULL, NULL);
    fclose(fp);
    return NULL;
  }

  // libpng longjmp error handling
  if (setjmp(png_jmpbuf(png_ptr))) {
    fprintf(stderr, "Error: libpng encountered an error\n");
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(fp);
    return NULL;
  }

  png_init_io(png_ptr, fp);
  png_set_sig_bytes(png_ptr, 8);

  // Read all PNG info
  png_read_info(png_ptr, info_ptr);

  png_uint_32 width = png_get_image_width(png_ptr, info_ptr);
  png_uint_32 height = png_get_image_height(png_ptr, info_ptr);
  png_byte color_type = png_get_color_type(png_ptr, info_ptr);
  png_byte bit_depth = png_get_bit_depth(png_ptr, info_ptr);

  // ---- Normalize to RGB 8-bit ----

  // Palette → RGB
  if (color_type == PNG_COLOR_TYPE_PALETTE)
    png_set_palette_to_rgb(png_ptr);

  // Gray → 8-bit
  if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8)
    png_set_expand_gray_1_2_4_to_8(png_ptr);

  // tRNS → full alpha
  if (png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS))
    png_set_tRNS_to_alpha(png_ptr);

  // 16-bit → 8-bit
  if (bit_depth == 16)
    png_set_strip_16(png_ptr);

  // Gray or Gray+Alpha → RGB
  if (color_type == PNG_COLOR_TYPE_GRAY ||
      color_type == PNG_COLOR_TYPE_GRAY_ALPHA)
    png_set_gray_to_rgb(png_ptr);

  // Drop alpha channel
  if (color_type & PNG_COLOR_MASK_ALPHA ||
      png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS)) {
    png_set_strip_alpha(png_ptr);
  }

  // Update transformations
  png_read_update_info(png_ptr, info_ptr);

  // Allocate output buffer
  size_t rowbytes = png_get_rowbytes(png_ptr, info_ptr);
  unsigned char *image = (unsigned char *)malloc(rowbytes * height);
  if (!image) {
    fprintf(stderr, "Error: malloc failed\n");
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(fp);
    return NULL;
  }

  // Allocate row pointers
  png_bytep *row_pointers = malloc(sizeof(png_bytep) * height);
  if (!row_pointers) {
    fprintf(stderr, "Error: malloc row pointers failed\n");
    free(image);
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(fp);
    return NULL;
  }

  for (size_t i = 0; i < height; i++)
    row_pointers[i] = image + i * rowbytes;

  // Read image into memory
  png_read_image(png_ptr, row_pointers);

  // Cleanup
  png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
  free(row_pointers);
  fclose(fp);

  *out_width = width;
  *out_height = height;

  return image;
}

unsigned char *load_jpeg_as_rgb(const char *filename, int *out_width,
                                int *out_height) {
  FILE *fp = fopen(filename, "rb");
  if (!fp) {
    fprintf(stderr, "Error: cannot open file %s\n", filename);
    return NULL;
  }

  // Get file size
  fseek(fp, 0, SEEK_END);
  long filesize = ftell(fp);
  fseek(fp, 0, SEEK_SET);
  if (filesize <= 0) {
    fprintf(stderr, "Error: empty file %s\n", filename);
    fclose(fp);
    return NULL;
  }

  // Read entire file into memory
  unsigned char *jpegBuf = (unsigned char *)malloc(filesize);
  if (!jpegBuf) {
    fprintf(stderr, "Error: malloc failed\n");
    fclose(fp);
    return NULL;
  }

  if (fread(jpegBuf, 1, filesize, fp) != (size_t)filesize) {
    fprintf(stderr, "Error: fread failed\n");
    free(jpegBuf);
    fclose(fp);
    return NULL;
  }
  fclose(fp);

  // Initialize TurboJPEG decompressor
  tjhandle tj = tjInitDecompress();
  if (!tj) {
    fprintf(stderr, "Error: tjInitDecompress failed: %s\n", tjGetErrorStr());
    free(jpegBuf);
    return NULL;
  }

  int width, height, jpegSubsamp, jpegColorspace;
  if (tjDecompressHeader3(tj, jpegBuf, filesize, &width, &height, &jpegSubsamp,
                          &jpegColorspace) != 0) {
    fprintf(stderr, "Error: tjDecompressHeader3 failed: %s\n", tjGetErrorStr());
    tjDestroy(tj);
    free(jpegBuf);
    return NULL;
  }

  // Allocate output buffer for RGB
  unsigned char *rgbBuf = (unsigned char *)malloc(width * height * 3);
  if (!rgbBuf) {
    fprintf(stderr, "Error: malloc rgbBuf failed\n");
    tjDestroy(tj);
    free(jpegBuf);
    return NULL;
  }

  // Decompress to RGB
  if (tjDecompress2(tj, jpegBuf, filesize, rgbBuf, width, 0 /*pitch*/, height,
                    TJPF_RGB, TJFLAG_FASTDCT) != 0) {
    fprintf(stderr, "Error: tjDecompress2 failed: %s\n", tjGetErrorStr());
    free(rgbBuf);
    tjDestroy(tj);
    free(jpegBuf);
    return NULL;
  }

  // Cleanup
  tjDestroy(tj);
  free(jpegBuf);

  *out_width = width;
  *out_height = height;
  return rgbBuf;
}

// 辅助函数：小写化字符串
static void str_tolower(char *dst, const char *src) {
  while (*src) {
    *dst++ = (char)tolower((unsigned char)*src++);
  }
  *dst = '\0';
}

// 通用加载函数
unsigned char *load_image_as_rgb(const char *filename, int *out_width,
                                 int *out_height) {
  // 获取文件扩展名
  const char *dot = strrchr(filename, '.');
  if (!dot || dot == filename) {
    fprintf(stderr, "Error: file %s has no extension\n", filename);
    return NULL;
  }

  char ext[16];
  str_tolower(ext, dot + 1); // 小写化扩展名

  if (strcmp(ext, "png") == 0) {
    return load_png_as_rgb(filename, out_width, out_height);
  } else if (strcmp(ext, "jpg") == 0 || strcmp(ext, "jpeg") == 0) {
    return load_jpeg_as_rgb(filename, out_width, out_height);
  } else {
    fprintf(stderr, "Error: unsupported file extension '%s' for file %s\n", ext,
            filename);
    return NULL;
  }
}

unsigned char *load_png_subsample(const char *filename, int target_pixels,
                                  int *out_w, int *out_h) {
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
  png_infop info_ptr = png_create_info_struct(png_ptr);

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

  // --- normalize to RGB8 ---
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

  // ---- sampling grid size ----
  int side = (int)sqrt(target_pixels);
  if (side < 1)
    side = 1;

  int step_y = height / side;
  int step_x = width / side;
  if (step_y < 1)
    step_y = 1;
  if (step_x < 1)
    step_x = 1;

  int outH = height / step_y;
  int outW = width / step_x;

  unsigned char *out = malloc(outW * outH * 3);
  int p = 0;

  for (int y = 0; y < height; y++) {
    png_read_row(png_ptr, row, NULL);

    if (y % step_y != 0)
      continue;

    for (int x = 0; x < width; x += step_x) {
      out[p++] = row[x * 3 + 0];
      out[p++] = row[x * 3 + 1];
      out[p++] = row[x * 3 + 2];
    }
  }

  free(row);
  png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
  fclose(fp);

  *out_w = outW;
  *out_h = outH;

  return out;
}

unsigned char *load_jpeg_subsample(const char *filename, int target_pixels,
                                   int *out_w, int *out_h) {
  // Read file
  FILE *fp = fopen(filename, "rb");
  if (!fp)
    return NULL;

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  fseek(fp, 0, SEEK_SET);

  unsigned char *buf = malloc(size);
  fread(buf, 1, size, fp);
  fclose(fp);

  tjhandle tj = tjInitDecompress();

  int w, h, subsamp, colorspace;
  tjDecompressHeader3(tj, buf, size, &w, &h, &subsamp, &colorspace);

  // Choose scale factor
  int best_num = 1, best_den = 1;
  double best_error = 1e30;

  // tjscalingfactor *sfs = tjGetScalingFactors(NULL);
  // int nsf = tjGetNumScalingFactors();

  int nsf = 0;
  tjscalingfactor *sfs = tjGetScalingFactors(&nsf);

  for (int i = 0; i < nsf; i++) {
    int sw = (w * sfs[i].num) / sfs[i].denom;
    int sh = (h * sfs[i].num) / sfs[i].denom;
    double pixels = (double)sw * sh;
    double err = fabs(pixels - target_pixels);

    if (err < best_error) {
      best_error = err;
      best_num = sfs[i].num;
      best_den = sfs[i].denom;
    }
  }

  int outW = (w * best_num) / best_den;
  int outH = (h * best_num) / best_den;

  unsigned char *rgb = malloc(outW * outH * 3);

  tjDecompress2(tj, buf, size, rgb, outW, 0, outH, TJPF_RGB,
                TJFLAG_FASTDCT | TJFLAG_FASTUPSAMPLE);

  free(buf);
  tjDestroy(tj);

  *out_w = outW;
  *out_h = outH;
  return rgb;
}

unsigned char *load_image_subsample(const char *filename, int target_pixels,
                                    int *out_w, int *out_h) {
  const char *ext = strrchr(filename, '.');
  if (!ext)
    return NULL;
  ext++;

  if (!strcasecmp(ext, "png"))
    return load_png_subsample(filename, target_pixels, out_w, out_h);

  if (!strcasecmp(ext, "jpg") || !strcasecmp(ext, "jpeg"))
    return load_jpeg_subsample(filename, target_pixels, out_w, out_h);

  return NULL;
}
