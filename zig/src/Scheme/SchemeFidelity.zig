const hct_mod = @import("../Hct/Hct.zig");
const dynamicScheme_mod = @import("DynamicScheme.zig");
const tonalPalette_mod = @import("../Palettes/TonalPalette.zig");
const dislike_mod = @import("../Dislike/DislikeAnalyzer.zig");
const temperature_mod = @import("../Temperature/TemperatureCache.zig");
const Hct = hct_mod.Hct;
const DynamicScheme = dynamicScheme_mod.DynamicScheme;
const fromHueAndChroma = tonalPalette_mod.fromHueAndChroma;
const fromHct = tonalPalette_mod.fromHct;
const fixIfDisliked = dislike_mod.fixIfDisliked;
const TemperatureCache = temperature_mod.TemperatureCache;

pub fn schemeFidelity(color: Hct, isDark: bool, contrastLevel: f32, cache: TemperatureCache) DynamicScheme {
    return .{
        .sourceColorHct = color,
        .variant = dynamicScheme_mod.Variant.fidelity,
        .isDark = isDark,
        .contrastLevel = contrastLevel,
        .primaryPalette = fromHueAndChroma(color.hue, color.chroma),
        .secondaryPalette = fromHueAndChroma(color.hue, @max(color.chroma - 32.0, color.chroma / 2.0)),
        .tertiaryPalette = fromHct(cache.getComplement()),
        .neutralPalette = fromHueAndChroma(color.hue, color.chroma / 8.0),
        .neutralVariantPalette = fromHueAndChroma(color.hue, color.chroma / 8.0 + 4.0),
    };
}
