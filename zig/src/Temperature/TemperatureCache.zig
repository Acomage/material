const std = @import("std");
const assert = std.debug.assert;
const hct_mod = @import("../Hct/Hct.zig");
const colorUtils_mod = @import("../Utils/ColorUtils.zig");
const mathUtils_mod = @import("../Utils/MathUtils.zig");
const atan2 = std.math.atan2;
const hypot = std.math.hypot;
const pow = std.math.pow;
const radiansToDegrees = std.math.radiansToDegrees;
const degreesToRadians = std.math.degreesToRadians;
const Hct = hct_mod.Hct;
const fromHct = hct_mod.fromHct;
const labFromArgb = colorUtils_mod.labFromArgb;

const AppendPlan = struct {
    colorHue: usize,
    count: usize,
};

const PlanState = struct {
    lastTemp: f32,
    totalTempDelta: f32,
    plans: []AppendPlan,
    fn size(self: PlanState) usize {
        var s: usize = 0;
        for (self.plans) |plan| {
            s += plan.count;
        }
        return s;
    }
};

fn rawTemperature(color: u32) f32 {
    const lab = labFromArgb(color);
    const hue = @mod(radiansToDegrees(atan2(lab[2], lab[1])), 360.0);
    const chroma = hypot(lab[1], lab[2]);
    return -0.5 + 0.02 * pow(f32, chroma, 1.07) * @cos(degreesToRadians(@mod(hue - 50.0, 360.0)));
}

fn isBetween(angle_: f32, a: usize, b: usize) bool {
    const angle: usize = @intFromFloat(angle_);
    if (a < b) {
        return angle >= a and angle <= b;
    } else {
        return angle >= a or angle <= b;
    }
}

pub const TemperatureCache = struct {
    input: Hct,
    temps: [360]f32,
    hcts: [360]Hct,
    coldestHue: usize,
    warmestHue: usize,
    coldestTemp: f32,
    warmestTemp: f32,
    invRange: f32,
    pub fn make(input: Hct) TemperatureCache {
        const chroma = input.chroma;
        const tone = input.tone;
        var hcts: [360]Hct = undefined;
        var temps: [360]f32 = undefined;
        var hct = fromHct(0.0, chroma, tone);
        var temp: f32 = rawTemperature(hct.argb);
        hcts[0] = hct;
        temps[0] = temp;
        var coldestHue: usize = 0;
        var warmestHue: usize = 0;
        var coldestTemp: f32 = temp;
        var warmestTemp: f32 = temp;
        for (1..360) |i| {
            hct = fromHct(@floatFromInt(i), chroma, tone);
            temp = rawTemperature(hct.argb);
            hcts[i] = hct;
            temps[i] = temp;
            if (temp < coldestTemp) {
                coldestTemp = temp;
                coldestHue = i;
            }
            if (temp > warmestTemp) {
                warmestTemp = temp;
                warmestHue = i;
            }
        }
        const range = warmestTemp - coldestTemp;
        const invRange = if (range == 0.0) 0.0 else 1.0 / range;
        return TemperatureCache{
            .input = input,
            .temps = temps,
            .hcts = hcts,
            .coldestHue = coldestHue,
            .warmestHue = warmestHue,
            .coldestTemp = coldestTemp,
            .warmestTemp = warmestTemp,
            .invRange = invRange,
        };
    }
    pub fn getComplement(self: TemperatureCache) Hct {
        const coldestHue = self.coldestHue;
        const coldestTemp = self.coldestTemp;
        const warmestHue = self.warmestHue;
        const warmestTemp = self.warmestTemp;
        const startHueIsColdestToWarmest = isBetween(self.input.hue, coldestHue, warmestHue);
        const startHue = if (startHueIsColdestToWarmest) warmestHue else coldestHue;
        const endHue = if (startHueIsColdestToWarmest) coldestHue else warmestHue;
        const complementTemp: f32 = coldestTemp + warmestTemp - rawTemperature(self.input.argb);
        var bestHue: usize = startHue;
        var bestErr: f32 = @abs(self.temps[bestHue] - complementTemp);
        if (startHue <= endHue) {
            for (startHue..endHue + 1) |h| {
                const err = @abs(self.temps[h] - complementTemp);
                if (err < bestErr) {
                    bestErr = err;
                    bestHue = h;
                }
            }
        } else {
            for (startHue..360) |h1| {
                const err = @abs(self.temps[h1] - complementTemp);
                if (err < bestErr) {
                    bestErr = err;
                    bestHue = h1;
                }
            }
            for (0..endHue + 1) |h2| {
                const err = @abs(self.temps[h2] - complementTemp);
                if (err < bestErr) {
                    bestErr = err;
                    bestHue = h2;
                }
            }
        }
        return self.hcts[bestHue];
    }
    // TODO: maybe times invRange outside?
    // decide whether to keep or not after testing
    fn calculateTotalTempDeltaOld(self: TemperatureCache, startHue: usize) f32 {
        var lastTemp: f32 = (self.temps[startHue] - self.coldestTemp) * self.invRange;
        var sum: f32 = 0.0;
        for (startHue + 1..startHue + 360) |i| {
            const hue = @mod(i, 360);
            const temp = (self.temps[hue] - self.coldestTemp) * self.invRange;
            const delta = @abs(temp - lastTemp);
            lastTemp = temp;
            sum += delta;
        }
        return sum;
    }
    fn calculateTotalTempDelta(self: TemperatureCache, startHue: usize) f32 {
        var lastTemp: f32 = self.temps[startHue];
        var sum: f32 = 0.0;
        for (startHue + 1..startHue + 360) |i| {
            const hue = @mod(i, 360);
            const temp = self.temps[hue];
            const delta = @abs(temp - lastTemp);
            lastTemp = temp;
            sum += delta;
        }
        return sum * self.invRange;
    }
    pub fn getAnalogousColorAt(self: TemperatureCache, comptime count: comptime_int, comptime divisions: comptime_int, comptime index: comptime_int) Hct {
        comptime assert(count > 0);
        comptime assert(divisions > 0);
        comptime assert(index >= 0 and index < count);
        const ccwCount = (count - 1) / 2;
        if (index == ccwCount) return self.input;
        const divIndex = @mod(index - ccwCount, divisions);
        if (divIndex == 0) return self.input;
        const startHue: usize = @intFromFloat(@floor(self.input.hue));
        const totalDelta = self.calculateTotalTempDelta(startHue);
        if (totalDelta == 0.0) return self.input;
        const tempStep: f32 = totalDelta / @as(f32, @floatFromInt(divisions));
        const target: f32 = @as(f32, @floatFromInt(divIndex)) * tempStep;
        var lastNorm: f32 = (self.temps[startHue] - self.coldestTemp) * self.invRange;
        var cumulative: f32 = 0.0;
        var prevHue: usize = startHue;
        var prevCum: f32 = 0.0;
        for (1..360) |stepCount| {
            const hue = @mod(startHue + stepCount, 360);
            const norm = (self.temps[hue] - self.coldestTemp) * self.invRange;
            const delta = @abs(norm - lastNorm);
            lastNorm = norm;
            const newCum = cumulative + delta;
            if (target <= newCum) {
                const errPrev = @abs(target - prevCum);
                const errCur = @abs(newCum - target);
                const answerHue = if (errCur < errPrev) hue else prevHue;
                return self.hcts[answerHue];
            }
            prevHue = hue;
            prevCum = newCum;
            cumulative = newCum;
        }
        return self.hcts[prevHue];
    }
};

test TemperatureCache {
    const print = std.debug.print;
    const hexFromArgb = @import("../Utils/StringUtils.zig").hexFromArgb;
    const t = TemperatureCache.make(fromHct(451.0, 56.0, 94.0));
    const complement = t.getComplement();
    const analogous = t.getAnalogousColorAt(3, 6, 2);
    print("color: {s}\n", .{hexFromArgb(t.input.argb)});
    print("complement: {s}\n", .{hexFromArgb(complement.argb)});
    print("analogous: {s}\n", .{hexFromArgb(analogous.argb)});
}
