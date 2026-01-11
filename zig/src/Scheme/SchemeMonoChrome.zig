const hct_mod = @import("../Hct/Hct.zig");
const dynamicScheme_mod = @import("DynamicScheme.zig");
const tonalPalette_mod = @import("../Palettes/TonalPalette.zig");
const Hct = hct_mod.Hct;
const Variant = dynamicScheme_mod.Variant;
const DynamicScheme = dynamicScheme_mod.DynamicScheme;
const fromHueAndChroma = tonalPalette_mod.fromHueAndChroma;

pub fn schemeMonoChrome(color: Hct, isDark: bool, contrastLevel: f32) DynamicScheme {
    return .{
        .sourceColorHct = color,
        .variant = Variant.monoChrome,
        .isDark = isDark,
        .contrastLevel = contrastLevel,
        .primaryPalette = fromHueAndChroma(color.hue, 0.0),
        .secondaryPalette = fromHueAndChroma(color.hue, 0.0),
        .tertiaryPalette = fromHueAndChroma(color.hue, 0.0),
        .neutralPalette = fromHueAndChroma(color.hue, 0.0),
        .neutralVariantPalette = fromHueAndChroma(color.hue, 0.0),
    };
}
