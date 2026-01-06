const c = @cImport({
    @cInclude("Extract/futhark/build/extract.h");
});

fn Sorted(max_colors: i64) type {
    return struct { num: i64, colors: [max_colors]u32, hues: [max_colors]f32 };
}

fn diff_degrees(a: f32, b: f32) f32 {
    return 180.0 - @abs(@abs(a - b) - 180.0);
}

fn has_duplicate_hue(chosen_hues: []f32, chose_count: usize, hue: f32, difference_degrees: f32) bool {
    for (0..chose_count) |i| {
        if (diff_degrees(chosen_hues[i], hue) < difference_degrees) {
            return true;
        }
    }
    return false;
}

fn choose_colors(sorted_colors: []const u32, sorted_hues: []const f32, n: i32, comptime desired: usize) [desired]u32 {
    var chosen_hues: [desired]f32 = undefined;
    var chosen_colors: [desired]u32 = undefined;
    var chosen_count: usize = 0;
    var difference_degrees: f32 = 90;
    while (difference_degrees >= 15) : (difference_degrees -= 1) {
        chosen_count = 0;
        var i: usize = 0;
        while (i < n and chosen_count < desired) : (i += 1) {
            const hue = sorted_hues[i];
            if (!has_duplicate_hue(chosen_hues[0..], chosen_count, hue, difference_degrees)) {
                chosen_hues[chosen_count] = hue;
                chosen_colors[chosen_count] = sorted_colors[i];
                chosen_count += 1;
            }
        }
        if (chosen_count >= desired) {
            return chosen_colors;
        }
    }
    return chosen_colors;
}

pub fn extract_colors_and_scores(comptime max_color: i64, input_pixels: []u8) Sorted(max_color) {
    const cfg = c.futhark_context_config_new();
    const ctx = c.futhark_context_new(cfg);
    var out1ptr: [max_color]u32 = undefined;
    var out2ptr: [max_color]f32 = undefined;
    var out0: i64 = undefined;
    var out1 = c.futhark_new_u32_1d(ctx, &out1ptr, 128);
    var out2 = c.futhark_new_f32_1d(ctx, &out2ptr, 128);
    const in1 = c.futhark_new_raw_u8_2d(ctx, input_pixels.ptr, @intCast(input_pixels.len / 3), 3);
    const resCode0 = c.futhark_entry_extract_colors_and_scores(ctx, &out0, &out1, &out2, max_color, in1);
    if (resCode0 != 0) {
        unreachable;
    }
    const resCode1 = c.futhark_context_sync(ctx);
    if (resCode1 != 0) {
        unreachable;
    }
    var out1_data: [max_color]u32 = undefined;
    var out2_data: [max_color]f32 = undefined;
    const resCode2 = c.futhark_values_u32_1d(ctx, out1, &out1_data);
    if (resCode2 != 0) {
        unreachable;
    }
    const resCode3 = c.futhark_values_f32_1d(ctx, out2, &out2_data);
    if (resCode3 != 0) {
        unreachable;
    }
    return .{
        .num = out0,
        .colors = out1_data,
        .hues = out2_data,
    };
}

pub fn extract(comptime max_color: i64, input_pixels: []u8, comptime desired: usize) [desired]u32 {
    const sorted_colors_and_hues = extract_colors_and_scores(max_color, input_pixels);
    return choose_colors(sorted_colors_and_hues.colors[0..@intCast(sorted_colors_and_hues.num)], sorted_colors_and_hues.hues[0..@intCast(sorted_colors_and_hues.num)], @intCast(sorted_colors_and_hues.num), desired);
}
