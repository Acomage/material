const colorUtils_mod = @import("../Utils/ColorUtils.zig");
const cam16_mod = @import("Cam16.zig");
const hctSolver_mod = @import("HctSolver.zig");
const viewingConditions_mod = @import("ViewingConditions.zig");
const lstarFromArgb = colorUtils_mod.lstarFromArgb;
const solveToInt = hctSolver_mod.solveToInt;

pub const Hct = struct {
    hue: f32,
    chroma: f32,
    tone: f32,
    argb: u32,
    fn toInt(self: Hct) u32 {
        return self.argb;
    }
};

fn setInteralState(argb: u32) Hct {
    const cam16 = cam16_mod.fromInt(argb);
    const tone = lstarFromArgb(argb);
    return Hct{
        .hue = cam16.hue,
        .chroma = cam16.chroma,
        .tone = tone,
        .argb = argb,
    };
}

pub fn fromHct(hue: f32, chroma: f32, tone: f32) Hct {
    const argb = solveToInt(hue, chroma, tone);
    return setInteralState(argb);
}

pub fn fromInt(argb: u32) Hct {
    return setInteralState(argb);
}

pub fn isYellow(hue: f32) bool {
    return (hue >= 105.0) and (hue <= 125.0);
}
