const std = @import("std");
const colorUtils_mod = @import("../Utils/ColorUtils.zig");
const mathUtils_mod = @import("../Utils/MathUtils.zig");
const viewingConditions_mod = @import("ViewingConditions.zig");
const cam16_mod = @import("Cam16.zig");
const pow = std.math.pow;
const sign = std.math.sign;
const atan2 = std.math.atan2;
const pi = std.math.pi;
const degreesToRadians = std.math.degreesToRadians;
const radiansToDegrees = std.math.radiansToDegrees;
const Vec3 = mathUtils_mod.Vec3;
const Mat3 = mathUtils_mod.Mat3;
const lstarFromY = colorUtils_mod.lstarFromY;
const yFromLstar = colorUtils_mod.yFromLstar;
const argbFromLinrgb = colorUtils_mod.argbFromLinrgb;
const argbFromLstar = colorUtils_mod.argbFromLstar;
const mul = mathUtils_mod.mul;
const dot = mathUtils_mod.dot;
const hypot = std.math.hypot;
const aVec = cam16_mod.aVec;
const bVec = cam16_mod.bVec;
const uVec = cam16_mod.uVec;
const acVec = cam16_mod.acVec;
const alphak = cam16_mod.alphak;
const default = viewingConditions_mod.DEFAULT;
const n_ = default.n;
const nc = default.nc;
const ncb = default.ncb;
const aw = default.aw;
const c_ = default.c;
const z = default.z;
const cz = c_ * z;
const nbb = default.nbb;
const p1k = 50000.0 / 13.0 * 0.25 * nc * ncb;
const tInnerCoeff = 1.0 / pow(f32, (1.64 - pow(f32, 0.29, n_)), 0.73);

const SCALED_DISCOUNT_FROM_LINRGB = Mat3{
    .{ 0.001200833568784504, 0.002389694492170889, 0.0002795742885861124 },
    .{ 0.0005891086651375999, 0.0029785502573438758, 0.0003270666104008398 },
    .{ 0.00010146692491640572, 0.0005364214359186694, 0.0032979401770712076 },
};

const LINRGB_FROM_SCALED_DISCOUNT = Mat3{
    .{ 1373.2198709594231, -1100.4251190754821, -7.278681089101213 },
    .{ -271.815969077903, 559.6580465940733, -32.46047482791194 },
    .{ 1.9622899599665666, -57.173814538844006, 308.7233197812385 },
};

const TO_RGBA = Mat3{
    .{ 460.0 / 1403.0, 451.0 / 1403.0, 288.0 / 1403.0 },
    .{ 460.0 / 1403.0, -891.0 / 1403.0, -261.0 / 1403.0 },
    .{ 460.0 / 1403.0, -220.0 / 1403.0, -6300.0 / 1403.0 },
};

const Y_FROM_LINRGB = Vec3{ 0.212656, 0.715158, 0.072186 };

const y0 = 100 * Y_FROM_LINRGB[2];
const y1 = 100 * Y_FROM_LINRGB[0];
const y2 = y0 + y1;
const y3 = 100 * Y_FROM_LINRGB[1];
const y4 = y0 + y3;
const y5 = y1 + y3;

fn chromaticAdaptation(component: f32) f32 {
    const af = pow(f32, component, 0.42);
    return 400.0 * af / (af + 27.13);
}

const cutNum = 1024;
const upperBound = @reduce(.Add, SCALED_DISCOUNT_FROM_LINRGB[2]) * 100.0;
const lowerBound = upperBound * 0.1;
const step_length = (upperBound - lowerBound) / @as(comptime_float, @floatFromInt(cutNum - 1));
const chromaticAdaptationLUT: [cutNum]f32 = blk: {
    @setEvalBranchQuota(100000);
    var lut: [cutNum]f32 = undefined;
    for (0..cutNum) |i| {
        const input = lowerBound + @as(f32, @floatFromInt(i)) * step_length;
        lut[i] = chromaticAdaptation(input);
    }
    break :blk lut;
};

fn getChromaticAdaptationFromLUT(component: f32) f32 {
    if (component <= lowerBound) {
        return chromaticAdaptation(component);
    } else {
        const indexF = (component - lowerBound) / step_length;
        const index = @as(usize, @intFromFloat(@round(indexF)));
        return chromaticAdaptationLUT[index];
    }
}

// TODO: maybe speed this up by LUT?
// TODO: check it after profiling.
fn chromaticAdaptationVOld(scaled: Vec3) Vec3 {
    const af = Vec3{
        pow(f32, scaled[0], 0.42),
        pow(f32, scaled[1], 0.42),
        pow(f32, scaled[2], 0.42),
    };
    return @as(Vec3, @splat(400.0)) * af / (af + @as(Vec3, @splat(27.13)));
}

// LUT version, maybe file near grey axis colors.
fn chromaticAdaptationV(scaled: Vec3) Vec3 {
    return Vec3{
        getChromaticAdaptationFromLUT(scaled[0]),
        getChromaticAdaptationFromLUT(scaled[1]),
        getChromaticAdaptationFromLUT(scaled[2]),
    };
}

fn inverseChromaticAdaptation(adapted: f32) f32 {
    const adaptedAbs = @abs(adapted);
    const base = @max(0.0, (adaptedAbs * 27.13 / (400 - adaptedAbs)));
    return sign(adapted) * pow(f32, base, 1.0 / 0.42);
}

fn inverseChromaticAdaptationV(adapted: Vec3) Vec3 {
    const adaptedAbs = @abs(adapted);
    const base = @max(
        @as(Vec3, @splat(0.0)),
        adaptedAbs * @as(Vec3, @splat(27.13)) / (@as(Vec3, @splat(400.0)) - adaptedAbs),
    );
    return Vec3{
        sign(adapted[0]) * pow(f32, base[0], 1.0 / 0.42),
        sign(adapted[1]) * pow(f32, base[1], 1.0 / 0.42),
        sign(adapted[2]) * pow(f32, base[2], 1.0 / 0.42),
    };
}

// this two epsilons are determined by guessing,
// maybe use a better method to find them later.
// TODO: get better epsilons
const yLowerEpsilon = 2.0;
const yUpperEpsilon = 5.0;
fn hueOf(y: f32, linrgb: Vec3) f32 {
    const scaled = mul(linrgb, SCALED_DISCOUNT_FROM_LINRGB);
    const rgbA = if (y >= yLowerEpsilon and y <= ySingular - yUpperEpsilon) chromaticAdaptationV(scaled) else chromaticAdaptationVOld(scaled);
    const a = dot(aVec, rgbA);
    const b = dot(bVec, rgbA);
    return atan2(b, a);
}

// get this by solving equations:
// SCALED_DISCOUNT_FROM_LINRGB v = [1,1,1]
// v.x = 100
const greyAxis = Vec3{ 100, 96.18310557389496, 95.47888926024586 };
const ySingular = dot(greyAxis, Y_FROM_LINRGB);
const lstarSingular = lstarFromY(ySingular);

fn areInCycleOrder(a: f32, b: f32, c: f32) bool {
    const deltaAB = @mod(b - a, 2 * pi);
    const deltaAC = @mod(c - a, 2 * pi);
    return deltaAB < deltaAC;
}

fn nthVertex(y: f32, comptime n: comptime_int) Vec3 {
    const kR = Y_FROM_LINRGB[0];
    const kG = Y_FROM_LINRGB[1];
    const kB = Y_FROM_LINRGB[2];
    const coordA = if (@mod(n, 4) <= 1) 0.0 else 100.0;
    const coordB = if (@mod(n, 2) == 0) 0.0 else 100.0;
    if (n < 4) {
        const g = coordA;
        const b = coordB;
        const r = (y - kG * g - kB * b) / kR;
        return Vec3{ r, g, b };
    } else if (n < 8) {
        const b = coordA;
        const r = coordB;
        const g = (y - kR * r - kB * b) / kG;
        return Vec3{ r, g, b };
    } else {
        const r = coordA;
        const g = coordB;
        const b = (y - kR * r - kG * g) / kB;
        return Vec3{ r, g, b };
    }
}

fn nthVertexArray(y: f32, comptime v: []const usize) [v.len]Vec3 {
    var result: [v.len]Vec3 = undefined;
    inline for (v, 0..) |n, vIndex| {
        result[vIndex] = nthVertex(y, n);
    }
    return result;
}

fn ccwDist(a: f32, b: f32) f32 {
    return @mod(b - a + 2 * pi, 2 * pi);
}

inline fn pickSegment(
    y: f32,
    targetHueNorm: f32,
    comptime indices: []const usize,
) [2]Vec3 {
    const vlist = nthVertexArray(y, indices);
    var biggest = vlist[0];
    var smallest = vlist[0];
    var biggestDist = ccwDist(targetHueNorm, hueOf(y, biggest));
    var smallestDist = biggestDist;
    inline for (vlist[1..]) |v| {
        const dist = ccwDist(targetHueNorm, hueOf(y, v));
        if (dist > biggestDist) {
            biggest = v;
            biggestDist = dist;
        }
        if (dist < smallestDist) {
            smallest = v;
            smallestDist = dist;
        }
    }
    return .{ biggest, smallest };
}

const Segment = struct {
    y_max: f32,
    indices: []const usize,
};

const segments = [_]Segment{
    .{ .y_max = y0, .indices = &.{ 0, 4, 8 } },
    .{ .y_max = y1, .indices = &.{ 0, 4, 6, 1 } },
    .{ .y_max = y2, .indices = &.{ 1, 10, 5, 4, 6 } },
    .{ .y_max = y3, .indices = &.{ 5, 4, 6, 7 } },
    .{ .y_max = y4, .indices = &.{ 5, 2, 9, 6, 7 } },
    .{ .y_max = y5, .indices = &.{ 2, 3, 7, 5 } },
};

fn bisectToSegment(y: f32, targetHue: f32) [2]Vec3 {
    const targetHueNorm =
        if (targetHue > pi) targetHue - 2 * pi else targetHue;
    inline for (segments) |seg| {
        if (y < seg.y_max) {
            return pickSegment(y, targetHueNorm, seg.indices);
        }
    }
    return pickSegment(y, targetHueNorm, &.{ 3, 7, 11 });
}

fn bisectToLimit(y: f32, targetHue: f32) Vec3 {
    var left, var right = bisectToSegment(y, targetHue);
    const hueLeft = hueOf(y, left);
    const half = @as(Vec3, @splat(0.5));
    var mid = (left + right) * half;
    var midHue = hueOf(y, mid);
    const n: u8 = 8;
    const epsilon = @as(Vec3, @splat(0.1));
    inline for (0..n) |_| {
        if (@reduce(.And, @abs(right - left) <= epsilon)) {
            break;
        }
        mid = (left + right) * half;
        midHue = hueOf(y, mid);
        if (areInCycleOrder(hueLeft, targetHue, midHue)) {
            right = mid;
        } else {
            left = mid;
        }
    }
    return (left + right) * half;
}

fn findResultByJ(hueRadians: f32, chroma: f32, y: f32) u32 {
    const maxIter = 5;
    const tol = 0.002;
    const eHue = @cos(hueRadians + 2.0) + 3.8;
    const p1 = eHue * p1k;
    const hsin = @sin(hueRadians);
    const hcos = @cos(hueRadians);
    var j = 11 * @sqrt(y);
    for (0..maxIter) |i| {
        const jNormalized = j / 100.0;
        const alpha = if (j == 0.0) 0.0 else chroma / @sqrt(jNormalized);
        const t = pow(f32, alpha * tInnerCoeff, 1.0 / 0.9);
        const ac = aw * pow(f32, jNormalized, 1.0 / cz);
        const p2 = ac / nbb;
        const gamma = 23.0 * (p2 + 0.305) * t / (23.0 * p1 + 11.0 * t * hcos + 108.0 * t * hsin);
        const a = gamma * hcos;
        const b = gamma * hsin;
        const rgbA = mul(.{ p2, a, b }, TO_RGBA);
        const rgbScaled = inverseChromaticAdaptationV(rgbA);
        const linrgb = mul(rgbScaled, LINRGB_FROM_SCALED_DISCOUNT);
        if (@reduce(.Or, linrgb < @as(Vec3, @splat(0)))) {
            return 0;
        }
        const yj = dot(linrgb, Y_FROM_LINRGB);
        const err = yj - y;
        if (i == maxIter - 1 or @abs(err) < tol) {
            return if (@reduce(.Or, linrgb > @as(Vec3, @splat(100.01)))) 0 else argbFromLinrgb(linrgb);
        }
        j = j - (err * j / (2.0 * yj));
    }
    return 0;
}

pub fn solveToInt(hueDegrees: f32, chroma: f32, lstar: f32) u32 {
    if (chroma < 0.0001 or lstar < 0.0001 or lstar >= lstarSingular - 0.0001) {
        return argbFromLstar(lstar);
    }
    const hueRadians = degreesToRadians(@mod(hueDegrees, 360.0));
    const y = yFromLstar(lstar);
    const exactAnswer = findResultByJ(hueRadians, chroma, y);
    if (exactAnswer != 0) {
        return exactAnswer;
    }
    const linrgb = bisectToLimit(y, hueRadians);
    return argbFromLinrgb(linrgb);
}

pub fn maxChroma(hue: f32, tone: f32) f32 {
    const y = yFromLstar(tone);
    const hueRadians = degreesToRadians(@mod(hue, 360.0));
    const linrgb = bisectToLimit(y, hueRadians);
    const scaled = mul(linrgb, SCALED_DISCOUNT_FROM_LINRGB);
    const rgbA = if (y >= yLowerEpsilon or y <= ySingular - yUpperEpsilon) chromaticAdaptationV(scaled) else chromaticAdaptationVOld(scaled);
    const a = dot(aVec, rgbA);
    const b = dot(bVec, rgbA);
    const u = dot(uVec, rgbA);
    const ac = dot(acVec, rgbA);
    const hue_rad = @mod(atan2(b, a), 2 * pi);
    const huePrime = if (radiansToDegrees(hue_rad) < 20.14) hue_rad + 2 * pi + 2 else hue_rad + 2;
    const eHue = @cos(huePrime) + 3.8;
    const p1 = eHue * p1k;
    const t = p1 * hypot(a, b) / (u + 0.305);
    const jdiv100 = pow(f32, ac, cz);
    const alpha = alphak * pow(f32, t, 0.9);
    const chroma = alpha * @sqrt(jdiv100);
    return chroma;
}
