const hct_mod = @import("../Hct/Hct.zig");
const dynamicScheme_mod = @import("DynamicScheme.zig");
const tonalPalette_mod = @import("../Palettes/TonalPalette.zig");
const dynamicScheme2_mod = @import("../DynamicColor/DynamicScheme.zig");
const Hct = hct_mod.Hct;
const DynamicScheme = dynamicScheme_mod.DynamicScheme;
const Variant = dynamicScheme_mod.Variant;
const fromHueAndChroma = tonalPalette_mod.fromHueAndChroma;
const getRotatedHue = dynamicScheme2_mod.getRotatedHue;

const hues = [9]f32{ 0, 41, 61, 101, 131, 181, 251, 301, 360 };
const secindaryRotations = [9]f32{ 18, 15, 10, 12, 15, 18, 15, 12, 12 };
const tertiaryRotations = [9]f32{ 35, 30, 20, 25, 30, 35, 30, 25, 25 };

pub fn schemeVibrant(color: Hct, isDark: bool, contrastLevel: f32) DynamicScheme {
    return .{
        .sourceColorHct = color,
        .variant = Variant.vibrant,
        .isDark = isDark,
        .contrastLevel = contrastLevel,
        .primaryPalette = fromHueAndChroma(color.hue, 200.0),
        .secondaryPalette = fromHueAndChroma(getRotatedHue(color, hues, secindaryRotations), 24.0),
        .tertiaryPalette = fromHueAndChroma(getRotatedHue(color, hues, tertiaryRotations), 32.0),
        .neutralPalette = fromHueAndChroma(color.hue, 10.0),
        .neutralVariantPalette = fromHueAndChroma(color.hue, 12.0),
    };
}
