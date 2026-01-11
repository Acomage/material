const std = @import("std");
const clamp = std.math.clamp;
const hctSolver_mod = @import("../Hct/HctSolver.zig");
const types_mod = @import("Types.zig");
const contrast_mod = @import("../Contrast/Contrast.zig");
const maxChroma_mod = @import("../Hct/MaxChroma.zig");
const dynamicScheme_mod = @import("../Scheme/DynamicScheme.zig");
const DynamicScheme = dynamicScheme_mod.DynamicScheme;
const Variant = dynamicScheme_mod.Variant;
const lighterUnsafe = contrast_mod.lighterUnsafe;
const darkerUnsafe = contrast_mod.darkerUnsafe;
const rationOfTones = contrast_mod.rationOfTones;
const lighter = contrast_mod.lighter;
const darker = contrast_mod.darker;
const maxChroma = hctSolver_mod.maxChroma;
const maxChromaPeak = maxChroma_mod.maxChromaPeak;
const ToneFn = types_mod.ToneFn;
const Palette = types_mod.Palette;
const ContrastCurve = types_mod.ContrastCurve;
const TonalPolarity = types_mod.TonalPolarity;
const DynamicColor = types_mod.DynamicColor;

fn isFidelity(s: DynamicScheme) bool {
    switch (s.variant) {
        Variant.fidelity => return true,
        Variant.content => return true,
        else => return false,
    }
}

fn isMonoChrome(s: DynamicScheme) bool {
    switch (s.variant) {
        Variant.monoChrome => return true,
        else => return false,
    }
}

fn tonePrefersLightForeground(tone: f32) bool {
    return tone < 60.5;
}

pub fn foregroundTone(bgTone: f32, ratio: f32) f32 {
    const lighterTone = lighterUnsafe(bgTone, ratio);
    const darkerTone = darkerUnsafe(bgTone, ratio);
    const lighterRatio = rationOfTones(lighterTone, bgTone);
    const darkerRatio = rationOfTones(darkerTone, bgTone);
    const preferLighter = tonePrefersLightForeground(bgTone);
    if (preferLighter) {
        const negligibleDifference = @abs(lighterRatio - darkerRatio) < 0.1 and lighterRatio < ratio and darkerRatio < ratio;
        if (lighterRatio >= ratio or lighterRatio >= darkerRatio or negligibleDifference) {
            return lighterTone;
        } else {
            return darkerTone;
        }
    } else if (darkerRatio >= ratio or darkerRatio >= lighterRatio) {
        return darkerTone;
    } else {
        return lighterTone;
    }
}

pub fn findDesiredChromaByTone(hue: f32, chroma: f32, startTone: f32, by_decreasing_tone: bool) f32 {
    const index = @as(usize, @intFromFloat(@round(hue * 2)));
    const peakTone = maxChromaPeak[index].tone;
    const peakChroma = maxChromaPeak[index].chroma;
    if (peakChroma < chroma) {
        return peakTone;
    }
    const isMovingTowardsPeak = if (by_decreasing_tone) peakTone < startTone else peakTone > startTone;
    if (!isMovingTowardsPeak or startTone == peakTone) {
        return peakTone;
    }
    var p0 = startTone;
    var p1 = peakTone;
    var y0 = maxChroma(hue, p0) - chroma;
    var y1 = peakChroma - chroma;
    if (y0 >= 0.0) return startTone;
    const epsilon = 0.1;
    for (0..20) |_| {
        var mid = p0 - y0 * (p1 - p0) / (y1 - y0);
        if (mid <= p0 + 0.005 or mid >= p1 - 0.005) {
            mid = (p0 + p1) / 2.0;
        }
        const y_mid = maxChroma(hue, mid) - chroma;
        if (y_mid < 0.0) {
            p0 = mid;
            y0 = y_mid;
        } else {
            p1 = mid;
            y1 = y_mid;
        }
        if (@abs(p1 - p1) <= epsilon) {
            break;
        }
    }
    return (p0 + p1) / 2.0;
}

// combinators.

pub fn constantTone(tone: f32) ToneFn {
    return struct {
        fn f(_: DynamicScheme) f32 {
            return tone;
        }
    }.f;
}

pub fn fromPalette(p: Palette) ToneFn {
    return struct {
        fn f(s: DynamicScheme) f32 {
            return p.getTone(s);
        }
    }.f;
}

pub fn fromCurve(curve: ContrastCurve) ToneFn {
    return struct {
        fn f(s: DynamicScheme) f32 {
            return curve.get(s.contrastLevel);
        }
    }.f;
}

pub fn darkLight(dark: ToneFn, light: ToneFn) ToneFn {
    return struct {
        fn f(s: DynamicScheme) f32 {
            if (s.isDark) {
                return dark(s);
            } else {
                return light(s);
            }
        }
    }.f;
}

pub fn darkLightConst(dark: f32, light: f32) ToneFn {
    return struct {
        fn f(s: DynamicScheme) f32 {
            if (s.isDark) {
                return dark;
            } else {
                return light;
            }
        }
    }.f;
}

pub fn fidelity(yes: ToneFn, no: ToneFn) ToneFn {
    return struct {
        fn f(s: DynamicScheme) f32 {
            if (isFidelity(s)) {
                return yes(s);
            } else {
                return no(s);
            }
        }
    }.f;
}

pub fn monoChrome(yes: ToneFn, no: ToneFn) ToneFn {
    return struct {
        fn f(s: DynamicScheme) f32 {
            if (isMonoChrome(s)) {
                return yes(s);
            } else {
                return no(s);
            }
        }
    }.f;
}

pub fn monoChromeConst(yes: f32, no: f32) ToneFn {
    return struct {
        fn f(s: DynamicScheme) f32 {
            if (isMonoChrome(s)) {
                return yes;
            } else {
                return no;
            }
        }
    }.f;
}

pub fn withContrast(bg: ToneFn, curve: ContrastCurve, toneFn: ToneFn) ToneFn {
    return struct {
        fn f(s: DynamicScheme) f32 {
            const bgTone = bg(s);
            const desired = curve.get(s.contrastLevel);
            var t = toneFn(s);
            if (rationOfTones(bgTone, t) < desired) {
                t = foregroundTone(bgTone, desired);
            }
            if (s.contrastLevel < 0) {
                t = foregroundTone(bgTone, desired);
            }
            return t;
        }
    }.f;
}

pub fn withTwoBackgrounds(bg1: ToneFn, bg2: ToneFn, curve: ContrastCurve, toneFn: ToneFn) ToneFn {
    return struct {
        fn f(s: DynamicScheme) f32 {
            const bgTone1 = bg1(s);
            const bgTone2 = bg2(s);
            const upper = @max(bgTone1, bgTone2);
            const lower = @min(bgTone1, bgTone2);
            const desired = curve.get(s.contrastLevel);
            var t = toneFn(s);
            if (rationOfTones(upper, t) >= desired and rationOfTones(lower, t) >= desired) {
                if (s.contrastLevel < 0) {
                    t = foregroundTone(bgTone1, desired);
                }
                return t;
            }
            const lightOption = lighter(upper, desired);
            const darkOption = darker(lower, desired);
            const preferLighter = tonePrefersLightForeground(bgTone1) or tonePrefersLightForeground(bgTone2);
            if (preferLighter) {
                return lightOption orelse 100.0;
            } else {
                return darkOption orelse (lightOption orelse 0.0);
            }
        }
    }.f;
}

pub fn toneFnPair(roleA: ToneFn, roleB: ToneFn, delta: f32, polarity: TonalPolarity, stay_together: bool, s: DynamicScheme) [2]f32 {
    const aIsNearer = switch (polarity) {
        TonalPolarity.nearer => true,
        TonalPolarity.farther => false,
        TonalPolarity.lighter => !s.isDark,
        TonalPolarity.darker => s.isDark,
    };
    // const nearer = if (aIsNearer) roleA else roleB;
    // const farther = if (aIsNearer) roleB else roleA;
    const expansionDir: f32 = if (s.isDark) 1.0 else -1.0;
    // var n_tone = nearer(s);
    // var f_tone = farther(s);
    var n_tone = if (aIsNearer) roleA(s) else roleB(s);
    var f_tone = if (aIsNearer) roleB(s) else roleA(s);
    if ((f_tone - n_tone) * expansionDir < delta) {
        f_tone = clamp(n_tone + delta * expansionDir, 0.0, 100.0);
        if ((f_tone - n_tone) * expansionDir < delta) {
            n_tone = clamp(f_tone - delta * expansionDir, 0.0, 100.0);
        }
    }
    if (n_tone >= 50.0 and n_tone < 60.0) {
        if (expansionDir > 0) {
            n_tone = 60.0;
            f_tone = @max(f_tone, n_tone + delta * expansionDir);
        } else {
            n_tone = 49.0;
            f_tone = @min(f_tone, n_tone + delta * expansionDir);
        }
    } else if (f_tone >= 50.0 and f_tone < 60.0) {
        if (stay_together) {
            if (expansionDir > 0) {
                n_tone = 60.0;
                f_tone = @max(f_tone, n_tone + delta * expansionDir);
            } else {
                n_tone = 49.0;
                f_tone = @min(f_tone, n_tone + delta * expansionDir);
            }
        } else {
            if (expansionDir > 0) {
                f_tone = 60.0;
            } else {
                f_tone = 49.0;
            }
        }
    }
    if (aIsNearer) {
        return [2]f32{ n_tone, f_tone };
    } else {
        return [2]f32{ f_tone, n_tone };
    }
}

pub fn pairCombinator(delta: f32, polarity: TonalPolarity, stayTogether: bool, roleA: ToneFn, roleB: ToneFn) [2]ToneFn {
    const nearer = struct {
        fn f(s: DynamicScheme) f32 {
            return toneFnPair(roleA, roleB, delta, polarity, stayTogether, s)[0];
        }
    }.f;
    const farther = struct {
        fn f(s: DynamicScheme) f32 {
            return toneFnPair(roleA, roleB, delta, polarity, stayTogether, s)[1];
        }
    }.f;
    return [2]ToneFn{ nearer, farther };
}

pub fn getArgb(comptime c: DynamicColor, s: DynamicScheme) u32 {
    return c.palette.getTonalPalette(s).getArgb(c.toneFn.*(s));
}
