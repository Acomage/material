#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <turbojpeg.h>

#include "target_pixels.h"

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

int load_jpeg_subsample(unsigned char out[], const char *filename,
                        uint32_t *out_count) {
  FILE *fp = fopen(filename, "rb");
  if (!fp)
    return 1;

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  fseek(fp, 0, SEEK_SET);

  unsigned char *buf = malloc(size);
  if (!buf) {
    fclose(fp);
    return 1;
  }
  fread(buf, 1, size, fp);
  fclose(fp);

  tjhandle tj = tjInitDecompress();
  if (!tj) {
    free(buf);
    return 1;
  }

  int width, height, subsamp, colorspace;
  if (tjDecompressHeader3(tj, buf, size, &width, &height, &subsamp,
                          &colorspace) < 0) {
    free(buf);
    tjDestroy(tj);
    return 1;
  }

  int total_pixels = width * height;
  int step = calculate_step(total_pixels, TARGET_PIXELS);

  int nsf = 0;
  tjscalingfactor *sfs = tjGetScalingFactors(&nsf);

  int best_num = 1, best_den = 1;
  int best_decoded_pixels = total_pixels;

  for (int i = 0; i < nsf; i++) {
    int sw = TJSCALED(width, sfs[i]);
    int sh = TJSCALED(height, sfs[i]);
    int decoded_pixels = sw * sh;

    int decoded_step = calculate_step(decoded_pixels, TARGET_PIXELS);
    int sampled = calculate_sampled_count(decoded_pixels, decoded_step);

    if (sampled >= TARGET_PIXELS && decoded_pixels < best_decoded_pixels) {
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
    return 1;
  }

  if (tjDecompress2(tj, buf, size, rgb, dec_w, 0, dec_h, TJPF_RGB,
                    TJFLAG_FASTDCT | TJFLAG_FASTUPSAMPLE) < 0) {
    free(rgb);
    free(buf);
    tjDestroy(tj);
    return 1;
  }

  free(buf);
  tjDestroy(tj);

  int sample_step = calculate_step(decoded_pixels, TARGET_PIXELS);
  int sampled_count = calculate_sampled_count(decoded_pixels, sample_step);

  int out_pos = 0;
  for (int i = 0; i < decoded_pixels; i += sample_step) {
    out[out_pos++] = rgb[i * 3 + 0];
    out[out_pos++] = rgb[i * 3 + 1];
    out[out_pos++] = rgb[i * 3 + 2];
  }

  free(rgb);

  *out_count = out_pos / 3;
  // return out;
  return 0;
}
