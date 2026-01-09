const std = @import("std");
const mathUtils_mod = @import("../Utils/MathUtils.zig");
const colorUtils_mod = @import("../Utils/ColorUtils.zig");
const pi = std.math.pi;
const lerp = std.math.lerp;
const exp = std.math.exp;
const cbrt = std.math.cbrt;
const sqrt = std.math.sqrt;
const pow = std.math.pow;
const whitePointD65 = colorUtils_mod.WHITE_POINT_D65;
const Vec3 = mathUtils_mod.Vec3;
const Mat3 = mathUtils_mod.Mat3;
const mul = mathUtils_mod.mul;
const yFromLstar = colorUtils_mod.yFromLstar;

const ViewingConditions = struct {
    n: f32,
    aw: f32,
    nbb: f32,
    ncb: f32,
    c: f32,
    nc: f32,
    rgbD: @Vector(3, f32),
    fl: f32,
    flRoot: f32,
    z: f32,
};

const m: Mat3 = .{
    @Vector(3, f32){ 0.401288, 0.650173, -0.051461 },
    @Vector(3, f32){ -0.250268, 1.204414, 0.045854 },
    @Vector(3, f32){ -0.002079, 0.048952, 0.953127 },
};

fn make() ViewingConditions {
    const xyz = whitePointD65;
    const adaptedLuminance = (200.0 / pi) * yFromLstar(50.0) / 100;
    const backgroundLstar = 50.0;
    const surround = 2.0;
    const discountingIlluminant = false;
    const rgbW = mul(xyz, m);
    const f = surround / 10.0 + 0.8;
    const c = if (f >= 0.9) lerp(0.59, 0.69, (f - 0.9) * 10.0) else lerp(0.525, 0.59, (f - 0.8) * 10.0);
    const d = if (discountingIlluminant) 1.0 else f * (1.0 - (1.0 / 3.6) * exp((-adaptedLuminance - 42.0) / 92.0));
    const nc = f;
    const rgbD = @as(Vec3, @splat(d * 100.0)) / rgbW + @as(Vec3, @splat(1.0)) - @as(Vec3, @splat(d));
    const k = 1.0 / (5.0 * adaptedLuminance + 1.0);
    const k4 = k * k * k * k;
    const k4F = 1.0 - k4;
    const fl = k4 * adaptedLuminance + 0.1 * k4F * k4F * cbrt(5.0 * adaptedLuminance);
    const n = yFromLstar(backgroundLstar) / xyz[1];
    const z = 1.48 + sqrt(n);
    const nbb = 0.725 / pow(f32, n, 0.2);
    const ncb = nbb;
    const rgbAFactorsBase = @as(Vec3, @splat(fl)) * rgbD * rgbW / @as(Vec3, @splat(100.0));
    const rgbAFactors = @Vector(3, f32){
        pow(f32, rgbAFactorsBase[0], 0.42),
        pow(f32, rgbAFactorsBase[1], 0.42),
        pow(f32, rgbAFactorsBase[2], 0.42),
    };
    const rgbA = (@as(Vec3, @splat(400.0)) * rgbAFactors) / (rgbAFactors + @as(Vec3, @splat(27.13)));
    const aw = (2.0 * rgbA[0] + rgbA[1] + 0.05 * rgbA[2]) * nbb;
    return ViewingConditions{
        .n = n,
        .aw = aw,
        .nbb = nbb,
        .ncb = ncb,
        .c = c,
        .nc = nc,
        .rgbD = rgbD,
        .fl = fl,
        .flRoot = sqrt(sqrt(fl)),
        .z = z,
    };
}

pub const DEFAULT = make();

test DEFAULT {
    const d = ViewingConditions{
        .n = 0.18418651851244414,
        .aw = 29.98099719444734,
        .nbb = 1.0169191804458757,
        .ncb = 1.0169191804458757,
        .c = 0.69,
        .nc = 1,
        .rgbD = .{ 1.02117770275752, 0.9863077294280124, 0.9339605082802299 },
        .fl = 0.3884814537800353,
        .flRoot = 0.7894826179304937,
        .z = 1.909169568483652,
    };
    try std.testing.expectApproxEqRel(d.n, DEFAULT.n, 0.0001);
    try std.testing.expectApproxEqRel(d.aw, DEFAULT.aw, 0.0001);
    try std.testing.expectApproxEqRel(d.nbb, DEFAULT.nbb, 0.0001);
    try std.testing.expectApproxEqRel(d.ncb, DEFAULT.ncb, 0.0001);
    try std.testing.expectApproxEqRel(d.c, DEFAULT.c, 0.0001);
    try std.testing.expectApproxEqRel(d.nc, DEFAULT.nc, 0.0001);
    try std.testing.expectApproxEqRel(d.rgbD[0], DEFAULT.rgbD[0], 0.0001);
    try std.testing.expectApproxEqRel(d.rgbD[1], DEFAULT.rgbD[1], 0.0001);
    try std.testing.expectApproxEqRel(d.rgbD[2], DEFAULT.rgbD[2], 0.0001);
    try std.testing.expectApproxEqRel(d.fl, DEFAULT.fl, 0.0001);
    try std.testing.expectApproxEqRel(d.flRoot, DEFAULT.flRoot, 0.0001);
    try std.testing.expectApproxEqRel(d.z, DEFAULT.z, 0.0001);
}
