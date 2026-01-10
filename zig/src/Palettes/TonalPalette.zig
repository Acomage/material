const hct_mod = @import("../Hct/Hct.zig");
const hctSolver_mod = @import("../Hct/HctSolver.zig");
const maxChroma_mod = @import("../Hct/MaxChroma.zig");
const colorUtils_mod = @import("../Utils/ColorUtils.zig");
const mathUtils_mod = @import("../Utils/MathUtils.zig");
const Hct = hct_mod.Hct;
const maxChroma = hctSolver_mod.maxChroma;
const maxChromaPeak = maxChroma_mod.maxChromaPeak;
const solveToInt = hctSolver_mod.solveToInt;

const KeyColor = struct {
    hue: f32,
    requestedChroma: f32,
    fn create(self: KeyColor) Hct {
        const pivotTone = 50.0;
        const hue = self.hue;
        const requestedChroma = self.requestedChroma;
        const index = @as(usize, @intFromFloat(@round(hue * 2)));
        const peakTone = maxChromaPeak[index].tone;
        const peakChroma = maxChromaPeak[index].chroma;
        if (peakChroma <= requestedChroma) {
            return hct_mod.fromHct(hue, requestedChroma, peakTone);
        }
        var y0 = maxChroma(hue, pivotTone) - requestedChroma;
        var p0 = pivotTone;
        var p1 = peakTone;
        var y1 = peakChroma - requestedChroma;
        if (y0 >= 0) {
            return hct_mod.fromHct(hue, requestedChroma, pivotTone);
        }
        const epsilon = 0.1;
        for (0..20) |_| {
            var mid = p0 - y0 * (p1 - p0) / (y1 - y0);
            if (mid <= p0 + 0.005 or mid >= p1 - 0.005) {
                mid = (p0 + p1) / 2.0;
            }
            const y_mid = maxChroma(hue, mid) - requestedChroma;
            if (y_mid < 0.0) {
                p0 = mid;
                y0 = y_mid;
            } else {
                p1 = mid;
                y1 = y_mid;
            }
            if (@abs(p1 - p0) <= epsilon) {
                break;
            }
        }
        return hct_mod.fromHct(hue, requestedChroma, (p0 + p1) / 2.0);
    }
};

pub const TonalPalette = struct {
    hue: f32,
    chroma: f32,
    keyColor: Hct,
    pub fn getArgb(self: TonalPalette, tone: f32) u32 {
        return solveToInt(self.hue, self.chroma, tone);
    }
};

pub fn fromHct(hct: Hct) TonalPalette {
    return TonalPalette{
        .hue = hct.hue,
        .chroma = hct.chroma,
        .keyColor = hct,
    };
}

pub fn fromHueAndChroma(hue: f32, chorma: f32) TonalPalette {
    const hue_ = @mod(hue, 360.0);
    const keyColor = KeyColor{
        .hue = hue_,
        .requestedChroma = chorma,
    };
    const keyColor_ = keyColor.create();
    return TonalPalette{
        .hue = hue_,
        .chroma = chorma,
        .keyColor = keyColor_,
    };
}
