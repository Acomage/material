const mathUtils_mod = @import("../Utils/MathUtils.zig");
const colorUtils_mod = @import("../Utils/ColorUtils.zig");
const viewingConditions_mod = @import("ViewingConditions.zig");
const std = @import("std");
const pow = std.math.pow;
const sign = std.math.sign;
const atan2 = std.math.atan2;
const hypot = std.math.hypot;
const deg_per_rad = std.math.deg_per_rad;
const pi = std.math.pi;
const Vec3 = mathUtils_mod.Vec3;
const Mat3 = mathUtils_mod.Mat3;
const dot = mathUtils_mod.dot;
const mul = mathUtils_mod.mul;
const mulMat = mathUtils_mod.mulMat;
const xyzFromArgb = colorUtils_mod.xyzFromArgb;
const linrgbFromArgb = colorUtils_mod.linrgbFromArgb;
const SRGB_TO_XYZ = colorUtils_mod.SRGB_TO_XYZ;
const default = viewingConditions_mod.DEFAULT;
const rgbD = default.rgbD;
const fl = default.fl;
const nbb = default.nbb;
const aw = default.aw;
const c = default.c;
const z = default.z;
const nc = default.nc;
const ncb = default.ncb;
const n = default.n;
const cz = c * z;
pub const p1k = 50000.0 / 13.0 * 0.25 * nc * ncb;
pub const alphak = pow(f32, 1.64 - pow(f32, 0.29, n), 0.73);

const XYZ_TO_CAM16RGB: Mat3 = .{
    .{ 0.401288, 0.650173, -0.051461 },
    .{ -0.250268, 1.204414, 0.045854 },
    .{ -0.002079, 0.048952, 0.953127 },
};

pub const aVec: Vec3 = .{ 11.0 / 11.0, -12.0 / 11.0, 1.0 / 11.0 };
pub const bVec: Vec3 = .{ 1.0 / 9.0, 1.0 / 9.0, -2.0 / 9.0 };
pub const uVec: Vec3 = .{ 20.0 / 20.0, 20.0 / 20.0, 21.0 / 20.0 };
pub const acVec: Vec3 = .{ 40.0 * nbb / 20.0 / aw, 20.0 * nbb / 20.0 / aw, 1.0 * nbb / 20.0 / aw };

const SRGB_TO_CAM16RGB: Mat3 = blk: {
    const m0 = mulMat(XYZ_TO_CAM16RGB, SRGB_TO_XYZ);
    const m1: Mat3 = .{
        @as(Vec3, @splat(fl * rgbD[0])) * m0[0],
        @as(Vec3, @splat(fl * rgbD[1])) * m0[1],
        @as(Vec3, @splat(fl * rgbD[2])) * m0[2],
    };
    const m2: Mat3 = .{
        m1[0] / @as(Vec3, @splat(100.0)),
        m1[1] / @as(Vec3, @splat(100.0)),
        m1[2] / @as(Vec3, @splat(100.0)),
    };
    break :blk m2;
};

pub const Cam16 = struct {
    hue: f32,
    chroma: f32,
};

pub fn fromInt(argb: u32) Cam16 {
    const linrgb = linrgbFromArgb(argb);
    const rgbAfPre = mul(linrgb, SRGB_TO_CAM16RGB);
    const rgbAfPreAbs = @abs(rgbAfPre);
    const rgbAf = Vec3{ pow(f32, rgbAfPreAbs[0], 0.42), pow(f32, rgbAfPreAbs[1], 0.42), pow(f32, rgbAfPreAbs[2], 0.42) };
    const signRgbD = Vec3{
        sign(rgbAfPre[0]),
        sign(rgbAfPre[1]),
        sign(rgbAfPre[2]),
    };
    const rgbA = signRgbD * @as(Vec3, @splat(400.0)) * rgbAf / (rgbAf + @as(Vec3, @splat(27.13)));
    const a = dot(aVec, rgbA);
    const b = dot(bVec, rgbA);
    const u = dot(uVec, rgbA);
    const ac = dot(acVec, rgbA);
    const hue_rad = @mod(atan2(b, a), 2 * pi);
    const hue = hue_rad * deg_per_rad;
    const huePrime = if (hue < 20.14) hue_rad + 2 * pi + 2 else hue_rad + 2;
    const eHue = @cos(huePrime) + 3.8;
    const p1 = eHue * p1k;
    const t = p1 * hypot(a, b) / (u + 0.305);
    const jdiv100 = pow(f32, ac, cz);
    const alpha = alphak * pow(f32, t, 0.9);
    const chroma = alpha * @sqrt(jdiv100);
    return Cam16{
        .hue = hue,
        .chroma = chroma,
    };
}
