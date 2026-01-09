const std = @import("std");
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("png.h");
    @cInclude("turbojpeg.h");
});

pub const TARGET_PIXELS: usize = 16384;

pub const ImageError = error{
    FileOpenFailed,
    InvalidPngSignature,
    PngCreateReadStructFailed,
    PngCreateInfoStructFailed,
    PngReadFailed,
    JpegDecompressInitFailed,
    JpegHeaderDecodeFailed,
    JpegDecompressFailed,
    UnsupportedFormat,
    OutOfMemory,
    ReadFailed,
};

fn calculateStep(total_pixels: usize, target_pixels: usize) usize {
    if (target_pixels >= total_pixels) return 1;
    const step = total_pixels / target_pixels;
    return if (step < 1) 1 else step;
}

fn calculateSampledCount(total_pixels: usize, step: usize) usize {
    return (total_pixels + step - 1) / step;
}

pub fn loadPngSubsample(allocator: Allocator, out: []u8, filename: [*:0]const u8) ImageError!usize {
    const fp = c.fopen(filename, "rb") orelse return ImageError.FileOpenFailed;
    defer _ = c.fclose(fp);

    var header: [8]u8 = undefined;
    if (c.fread(&header, 1, 8, fp) != 8) {
        return ImageError.InvalidPngSignature;
    }
    if (c.png_sig_cmp(&header, 0, 8) != 0) {
        return ImageError.InvalidPngSignature;
    }

    var png_ptr: c.png_structp = c.png_create_read_struct(
        c.PNG_LIBPNG_VER_STRING,
        null,
        null,
        null,
    ) orelse {
        return ImageError.PngCreateReadStructFailed;
    };

    var info_ptr: c.png_infop = c.png_create_info_struct(png_ptr) orelse {
        c.png_destroy_read_struct(&png_ptr, null, null);
        return ImageError.PngCreateInfoStructFailed;
    };

    defer c.png_destroy_read_struct(&png_ptr, &info_ptr, null);

    c.png_init_io(png_ptr, fp);
    c.png_set_sig_bytes(png_ptr, 8);
    c.png_read_info(png_ptr, info_ptr);

    const width: usize = @intCast(c.png_get_image_width(png_ptr, info_ptr));
    const height: usize = @intCast(c.png_get_image_height(png_ptr, info_ptr));
    const bit_depth = c.png_get_bit_depth(png_ptr, info_ptr);
    const color_type = c.png_get_color_type(png_ptr, info_ptr);

    if (color_type == c.PNG_COLOR_TYPE_PALETTE)
        c.png_set_palette_to_rgb(png_ptr);
    if (color_type == c.PNG_COLOR_TYPE_GRAY and bit_depth < 8)
        c.png_set_expand_gray_1_2_4_to_8(png_ptr);
    if (c.png_get_valid(png_ptr, info_ptr, c.PNG_INFO_tRNS) != 0)
        c.png_set_tRNS_to_alpha(png_ptr);
    if (bit_depth == 16)
        c.png_set_strip_16(png_ptr);
    if (color_type == c.PNG_COLOR_TYPE_GRAY or color_type == c.PNG_COLOR_TYPE_GRAY_ALPHA)
        c.png_set_gray_to_rgb(png_ptr);
    if ((color_type & c.PNG_COLOR_MASK_ALPHA) != 0)
        c.png_set_strip_alpha(png_ptr);

    c.png_read_update_info(png_ptr, info_ptr);

    const row_bytes: usize = c.png_get_rowbytes(png_ptr, info_ptr);
    const row = allocator.alloc(u8, row_bytes) catch return ImageError.OutOfMemory;
    defer allocator.free(row);

    const total_pixels = width * height;
    const step = calculateStep(total_pixels, TARGET_PIXELS);
    _ = calculateSampledCount(total_pixels, step);

    var next_sample: usize = 0;
    var out_pos: usize = 0;

    for (0..height) |y| {
        c.png_read_row(png_ptr, row.ptr, null);
        const row_start = y * width;
        const row_end = row_start + width;

        while (next_sample < row_end and next_sample < total_pixels) {
            const x: usize = next_sample - row_start;
            if (out_pos + 2 < out.len) {
                out[out_pos] = row[x * 3 + 0];
                out[out_pos + 1] = row[x * 3 + 1];
                out[out_pos + 2] = row[x * 3 + 2];
                out_pos += 3;
            }
            next_sample += step;
        }
    }

    return out_pos / 3;
}

pub fn loadJpegSubsample(allocator: Allocator, out: []u8, filename: [*:0]const u8) ImageError!usize {
    const fp = c.fopen(filename, "rb") orelse return ImageError.FileOpenFailed;

    _ = c.fseek(fp, 0, c.SEEK_END);
    const size: usize = @intCast(c.ftell(fp));
    _ = c.fseek(fp, 0, c.SEEK_SET);

    const buf = allocator.alloc(u8, size) catch return ImageError.OutOfMemory;
    defer allocator.free(buf);

    const bytes_read = c.fread(buf.ptr, 1, size, fp);
    _ = c.fclose(fp);

    if (bytes_read != size) {
        return ImageError.ReadFailed;
    }

    const tj = c.tjInitDecompress() orelse return ImageError.JpegDecompressInitFailed;
    defer _ = c.tjDestroy(tj);

    var width: c_int = 0;
    var height: c_int = 0;
    var subsamp: c_int = 0;
    var colorspace: c_int = 0;

    if (c.tjDecompressHeader3(tj, buf.ptr, size, &width, &height, &subsamp, &colorspace) < 0) {
        return ImageError.JpegHeaderDecodeFailed;
    }

    const total_pixels: usize = @intCast(width * height);
    _ = calculateStep(total_pixels, TARGET_PIXELS);

    var nsf: c_int = 0;
    const sfs = c.tjGetScalingFactors(&nsf);

    var best_num: c_int = 1;
    var best_den: c_int = 1;
    var best_decoded_pixels: usize = total_pixels;

    for (0..@intCast(nsf)) |i| {
        const sf = sfs[i];
        const sw: usize = @intCast(@divTrunc(width * sf.num + sf.denom - 1, sf.denom));
        const sh: usize = @intCast(@divTrunc(height * sf.num + sf.denom - 1, sf.denom));
        const decoded_pixels = sw * sh;
        const decoded_step = calculateStep(decoded_pixels, TARGET_PIXELS);
        const sampled = calculateSampledCount(decoded_pixels, decoded_step);

        if (sampled >= TARGET_PIXELS and decoded_pixels < best_decoded_pixels) {
            best_decoded_pixels = decoded_pixels;
            best_num = sf.num;
            best_den = sf.denom;
        }
    }

    const dec_w: usize = @intCast(@divTrunc(width * best_num + best_den - 1, best_den));
    const dec_h: usize = @intCast(@divTrunc(height * best_num + best_den - 1, best_den));
    const decoded_pixels = dec_w * dec_h;

    const rgb = allocator.alloc(u8, decoded_pixels * 3) catch return ImageError.OutOfMemory;
    defer allocator.free(rgb);

    if (c.tjDecompress2(
        tj,
        buf.ptr,
        size,
        rgb.ptr,
        @intCast(dec_w),
        0,
        @intCast(dec_h),
        c.TJPF_RGB,
        c.TJFLAG_FASTDCT | c.TJFLAG_FASTUPSAMPLE,
    ) < 0) {
        return ImageError.JpegDecompressFailed;
    }

    const sample_step = calculateStep(decoded_pixels, TARGET_PIXELS);
    _ = calculateSampledCount(decoded_pixels, sample_step);

    var out_pos: usize = 0;
    var idx: usize = 0;
    while (idx < decoded_pixels) : (idx += sample_step) {
        if (out_pos + 2 < out.len) {
            out[out_pos] = rgb[idx * 3 + 0];
            out[out_pos + 1] = rgb[idx * 3 + 1];
            out[out_pos + 2] = rgb[idx * 3 + 2];
            out_pos += 3;
        }
    }

    return out_pos / 3;
}

pub fn loadImageSubsample(allocator: Allocator, rgb: []u8, filename: [*:0]const u8) ImageError!usize {
    const filename_slice = std.mem.span(filename);

    const ext_pos = std.mem.lastIndexOfScalar(u8, filename_slice, '.') orelse {
        return ImageError.UnsupportedFormat;
    };
    const ext = filename_slice[ext_pos + 1 ..];

    if (std.ascii.eqlIgnoreCase(ext, "png")) {
        return loadPngSubsample(allocator, rgb, filename);
    }
    if (std.ascii.eqlIgnoreCase(ext, "jpg") or std.ascii.eqlIgnoreCase(ext, "jpeg")) {
        return loadJpegSubsample(allocator, rgb, filename);
    }
    return ImageError.UnsupportedFormat;
}
