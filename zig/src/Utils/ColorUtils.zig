const std = @import("std");
const pow = std.math.pow;
const clamp = std.math.clamp;
const mathUtils_mod = @import("MathUtils.zig");
const Vec3 = mathUtils_mod.Vec3;
const Mat3 = mathUtils_mod.Mat3;

pub const SRGB_TO_XYZ: Mat3 = .{
    @Vector(3, f32){ 0.41233895, 0.35762064, 0.18051042 },
    @Vector(3, f32){ 0.2126, 0.7152, 0.0722 },
    @Vector(3, f32){ 0.01932141, 0.11916382, 0.95034478 },
};

const XYZ_TO_SRGB: Mat3 = .{
    @Vector(3, f32){ 3.2413774792388685, -1.5376652402851851, -0.49885366846268053 },
    @Vector(3, f32){ -0.9691452513005321, 1.8758853451067872, 0.04156585616912061 },
    @Vector(3, f32){ 0.05562093689691305, -0.20395524564742123, 1.0571799111220335 },
};

pub const WHITE_POINT_D65: @Vector(3, f32) = .{
    100 * @reduce(.Add, SRGB_TO_XYZ[0]),
    100 * @reduce(.Add, SRGB_TO_XYZ[1]),
    100 * @reduce(.Add, SRGB_TO_XYZ[2]),
};

fn linearized(rgbComponent: usize) f32 {
    const normalized = @as(f32, @floatFromInt(rgbComponent)) / 255.0;
    return if (normalized <= 0.040449936) normalized / 12.92 * 100.0 else pow(f32, (normalized + 0.055) / 1.055, 2.4) * 100;
}

const linearizedLUT: [256]f32 = blk: {
    @setEvalBranchQuota(50000);
    var res: [256]f32 = undefined;
    for (0..256) |i| {
        res[i] = linearized(i);
    }
    break :blk res;
};

pub fn rgbFromU32(color: u32) @Vector(3, u32) {
    const r = (color >> 16) & 0xFF;
    const g = (color >> 8) & 0xFF;
    const b = (color & 0xFF);
    return .{ r, g, b };
}

const LUT_SIZE: u32 = 2414;
const SCALE_FACTOR = (@as(f32, @floatFromInt(LUT_SIZE)) - 1) / 100.0;

fn trueDelinearized(rgbComponent: f32) f32 {
    const normalized = rgbComponent / 100.0;
    const delinearized_ = if (normalized <= 0.0031308)
        normalized * 12.92
    else
        1.055 * std.math.pow(f32, normalized, 1.0 / 2.4) - 0.055;
    return delinearized_ * 255.0;
}

const SRGB_LUT: [LUT_SIZE]u8 = blk: {
    @setEvalBranchQuota(1000000);
    var table: [LUT_SIZE]u8 = undefined;

    for (0..LUT_SIZE) |i| {
        const input_val = (@as(f32, @floatFromInt(i))) / SCALE_FACTOR;

        const val = trueDelinearized(input_val);

        table[i] = @intFromFloat(@round(val));
    }
    break :blk table;
};

const coff = 0.1292 * 255.0;

pub fn delinearized(linear: f32) u8 {
    if (linear <= 0.31308) {
        return @intFromFloat(@round(linear * coff));
    }
    const idx_f = linear * SCALE_FACTOR;
    const idx = @as(usize, @intFromFloat(@round(idx_f)));
    return clamp(SRGB_LUT[idx], 0, 255);
}

test "sRGB Round Trip Consistency (0-255)" {
    var perfect_matches: u32 = 0;
    var off_by_one: u32 = 0;
    var failures: u32 = 0;
    for (0..256) |i| {
        const input: u8 = @intCast(i);
        const linear_val = linearizedLUT[i];
        const output = delinearized(linear_val);
        const diff = if (input > output) input - output else output - input;
        if (diff == 0) {
            perfect_matches += 1;
        } else if (diff == 1) {
            off_by_one += 1;
            std.debug.print("warning: Input={d} -> Linear={d:.4} -> Output={d}\n", .{ input, linear_val, output });
        } else {
            failures += 1;
            std.debug.print("error: Input={d} -> Linear={d:.4} -> Output={d} (Diff={d})\n", .{ input, linear_val, output, diff });
        }
    }
    try std.testing.expect(failures == 0);
    try std.testing.expect(perfect_matches > 250);
}

const e = 216.0 / 24389.0;
const kappa = 24389.0 / 27.0;

// TODO: Maybe these four functions can use LUTs for better performance
// TODO: but first benchmark to see if it's necessary
fn labF(t: f32) f32 {
    return if (t > e) pow(f32, t, 1.0 / 3.0) else (kappa * t + 16.0) / 116.0;
}

fn labInvf(t: f32) f32 {
    const t3 = t * t * t;
    return if (t3 > e) t3 else (116.0 * t - 16.0) / kappa;
}

pub fn yFromLstar(lstar: f32) f32 {
    return 100.0 * labInvf((lstar + 16.0) / 116.0);
}

pub fn lstarFromY(y: f32) f32 {
    return 116.0 * labF(y / 100.0) - 16.0;
}

fn argbFromRgb(rgb: [3]u8) u32 {
    return (0xFF000000) | (@as(u32, rgb[0]) << 16) | (@as(u32, rgb[1]) << 8) | @as(u32, rgb[2]);
}

pub fn argbFromLinrgb(linear: Vec3) u32 {
    const srgb = [3]u8{
        delinearized(linear[0]),
        delinearized(linear[1]),
        delinearized(linear[2]),
    };
    return argbFromRgb(srgb);
}

pub fn argbFromXyz(x: f32, y: f32, z: f32) u32 {
    const linearRgb = mathUtils_mod.mul(Vec3{ x, y, z }, XYZ_TO_SRGB);
    return argbFromLinrgb(linearRgb);
}

pub fn linrgbFromArgb(argb: u32) Vec3 {
    const rgb = rgbFromU32(argb);
    return Vec3{
        linearizedLUT[rgb[0]],
        linearizedLUT[rgb[1]],
        linearizedLUT[rgb[2]],
    };
}

pub fn xyzFromArgb(argb: u32) Vec3 {
    const linearRgb = linrgbFromArgb(argb);
    return mathUtils_mod.mul(linearRgb, SRGB_TO_XYZ);
}

test xyzFromArgb {
    const color = 0xFF3366CC; // ARGB
    const result = xyzFromArgb(color);
    const expected = Vec3{ 17.016397, 14.566183, 59.031689 };
    try std.testing.expect(@abs(result[0] - expected[0]) < 0.01);
    try std.testing.expect(@abs(result[1] - expected[1]) < 0.01);
    try std.testing.expect(@abs(result[2] - expected[2]) < 0.01);
}

pub fn labFromArgb(argb: u32) Vec3 {
    const xyz = xyzFromArgb(argb);
    // const xr = xyz[0] / WHITE_POINT_D65[0];
    // const yr = xyz[1] / WHITE_POINT_D65[1];
    // const zr = xyz[2] / WHITE_POINT_D65[2];
    const xyzr = xyz / WHITE_POINT_D65;

    const fx = labF(xyzr[0]);
    const fy = labF(xyzr[1]);
    const fz = labF(xyzr[2]);

    const l = 116.0 * fy - 16.0;
    const a = 500.0 * (fx - fy);
    const b = 200.0 * (fy - fz);

    return Vec3{ l, a, b };
}

pub fn argbFromLstar(lstar: f32) u32 {
    const component = delinearized(yFromLstar(lstar));
    return argbFromRgb(.{ component, component, component });
}

pub fn lstarFromArgb(argb: u32) f32 {
    const xyz = xyzFromArgb(argb);
    return lstarFromY(xyz[1]);
}
