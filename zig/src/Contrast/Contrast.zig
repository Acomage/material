const colorUtils_mod = @import("../Utils/ColorUtils.zig");
const yFromLstar = colorUtils_mod.yFromLstar;
const lstarFromY = colorUtils_mod.lstarFromY;

const CONTRAST_RATIO_EPSILON = 0.04;
const LUMINANCE_GAMUT_MAP_TOLERANCE = 0.4;

fn ratioOfYs(y1: f32, y2: f32) f32 {
    const lighterY = @max(y1, y2);
    const darkerY = @min(y1, y2);
    return (lighterY + 5.0) / (darkerY + 5.0);
}

pub fn rationOfTones(t1: f32, t2: f32) f32 {
    return ratioOfYs(yFromLstar(t1), yFromLstar(t2));
}

pub fn lighter(tone: f32, ratio: f32) ?f32 {
    if (tone < 0.0 or tone > 100.0) return null;
    const darkY = yFromLstar(tone);
    const lightY = ratio * (darkY + 5.0) - 5.0;
    if (lightY < 0.0 or lightY > 100.0) return null;
    const realContrast = ratioOfYs(lightY, darkY);
    const delta = @abs(realContrast - ratio);
    if (realContrast < ratio and delta > CONTRAST_RATIO_EPSILON) return null;
    const returnValue = lstarFromY(lightY) + LUMINANCE_GAMUT_MAP_TOLERANCE;
    if (returnValue < 0.0 or returnValue > 100.0) return null;
    return returnValue;
}

pub fn lighterUnsafe(tone: f32, ratio: f32) f32 {
    return lighter(tone, ratio) orelse 100.0;
}

pub fn darker(tone: f32, ratio: f32) ?f32 {
    if (tone < 0.0 or tone > 100.0) return null;
    const lightY = yFromLstar(tone);
    const darkY = (lightY + 5.0) / ratio - 5.0;
    if (darkY < 0.0 or darkY > 100.0) return null;
    const realContrast = ratioOfYs(lightY, darkY);
    const delta = @abs(realContrast - ratio);
    if (realContrast < ratio and delta > CONTRAST_RATIO_EPSILON) return null;
    const returnValue = lstarFromY(darkY) - LUMINANCE_GAMUT_MAP_TOLERANCE;
    if (returnValue < 0.0 or returnValue > 100.0) return null;
    return returnValue;
}

pub fn darkerUnsafe(tone: f32, ratio: f32) f32 {
    return darker(tone, ratio) orelse 0.0;
}
