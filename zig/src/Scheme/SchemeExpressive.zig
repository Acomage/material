const hct_mod = @import("../Hct/Hct.zig");
const dynamicScheme_mod = @import("DynamicScheme.zig");
const tonalPalette_mod = @import("../Palettes/TonalPalette.zig");
const dynamicScheme2_mod = @import("../DynamicColor/DynamicScheme.zig");
const Hct = hct_mod.Hct;
const DynamicScheme = dynamicScheme_mod.DynamicScheme;
const Variant = dynamicScheme_mod.Variant;
const fromHueAndChroma = tonalPalette_mod.fromHueAndChroma;
const getRotatedHue = dynamicScheme2_mod.getRotatedHue;

const hues = [9]f32{ 0, 21, 51, 121, 151, 191, 271, 321, 360 };
const secindaryRotations = [9]f32{ 45, 95, 45, 20, 45, 90, 45, 45, 45 };
const tertiaryRotations = [9]f32{ 120, 120, 20, 45, 20, 15, 20, 120, 120 };

pub fn schemeExpressive(color: Hct, isDark: bool, contrastLevel: f32) DynamicScheme {
    return .{
        .sourceColorHct = color,
        .variant = Variant.expressive,
        .isDark = isDark,
        .contrastLevel = contrastLevel,
        .primaryPalette = fromHueAndChroma(color.hue + 240.0, 40.0),
        .secondaryPalette = fromHueAndChroma(getRotatedHue(color, hues, secindaryRotations), 24.0),
        .tertiaryPalette = fromHueAndChroma(getRotatedHue(color, hues, tertiaryRotations), 32.0),
        .neutralPalette = fromHueAndChroma(color.hue + 15.0, 8.0),
        .neutralVariantPalette = fromHueAndChroma(color.hue + 15.0, 12.0),
    };
}
