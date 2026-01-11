const hct_mod = @import("../Hct/Hct.zig");
const dynamicScheme_mod = @import("DynamicScheme.zig");
const tonalPalette_mod = @import("../Palettes/TonalPalette.zig");
const Hct = hct_mod.Hct;
const Variant = dynamicScheme_mod.Variant;
const DynamicScheme = dynamicScheme_mod.DynamicScheme;
const fromHueAndChroma = tonalPalette_mod.fromHueAndChroma;

pub fn schemeTonalSpot(color: Hct, isDark: bool, contrastLevel: f32) DynamicScheme {
    return .{
        .sourceColorHct = color,
        .variant = Variant.tonalSpot,
        .isDark = isDark,
        .contrastLevel = contrastLevel,
        .primaryPalette = fromHueAndChroma(color.hue, 36.0),
        .secondaryPalette = fromHueAndChroma(color.hue, 16.0),
        .tertiaryPalette = fromHueAndChroma(@mod(color.hue + 60.0, 360.0), 24.0),
        .neutralPalette = fromHueAndChroma(color.hue, 6.0),
        .neutralVariantPalette = fromHueAndChroma(color.hue, 8.0),
    };
}
