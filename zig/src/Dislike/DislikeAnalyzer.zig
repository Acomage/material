const hct_mod = @import("../Hct/Hct.zig");
const Hct = hct_mod.Hct;
const fromHct = hct_mod.fromHct;

fn isDislike(hct: Hct) bool {
    const huePasses = @round(hct.hue) >= 90.0 and @round(hct.hue) <= 111.0;
    const chromaPasses = @round(hct.chroma) > 16.0;
    const tonePasses = @round(hct.tone) < 65.0;
    return huePasses and chromaPasses and tonePasses;
}

pub fn fixIfDisliked(hct: Hct) Hct {
    if (isDislike(hct)) {
        return hct_mod.fromHct(hct.hue, hct.chroma, 70.0);
    } else {
        return hct;
    }
}
