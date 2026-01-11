const hct_mod = @import("../Hct/Hct.zig");
const dynamicScheme_mod = @import("DynamicScheme.zig");
const tonalPalette_mod = @import("../Palettes/TonalPalette.zig");
const Hct = hct_mod.Hct;
const Variant = dynamicScheme_mod.Variant;
const DynamicScheme = dynamicScheme_mod.DynamicScheme;
const fromHueAndChroma = tonalPalette_mod.fromHueAndChroma;

pub fn schemeFruitSalad(color: Hct, isDark: bool, contrastLevel: f32) DynamicScheme {
    return .{
        .sourceColorHct = color,
        .variant = Variant.fruitSalad,
        .isDark = isDark,
        .contrastLevel = contrastLevel,
        .primaryPalette = fromHueAndChroma(@mod(color.hue - 50.0, 360.0), 48.0),
        .secondaryPalette = fromHueAndChroma(@mod(color.hue - 50.0, 360.0), 36.0),
        .tertiaryPalette = fromHueAndChroma(color.hue, 36.0),
        .neutralPalette = fromHueAndChroma(color.hue, 10.0),
        .neutralVariantPalette = fromHueAndChroma(color.hue, 16.0),
    };
}
