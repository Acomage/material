const tonalPalette_mod = @import("../Palettes/TonalPalette.zig");
const hct_mod = @import("../Hct/Hct.zig");
const TonalPalette = tonalPalette_mod.TonalPalette;
const fromHueAndChroma = tonalPalette_mod.fromHueAndChroma;
const Hct = hct_mod.Hct;

pub const Variant = enum {
    monoChrome,
    neutral,
    tonalSpot,
    vibrant,
    expressive,
    fidelity,
    content,
    rainbow,
    fruitSalad,
};

pub const DynamicScheme = struct {
    sourceColorHct: Hct,
    variant: Variant,
    isDark: bool,
    contrastLevel: f32,
    primaryPalette: TonalPalette,
    secondaryPalette: TonalPalette,
    tertiaryPalette: TonalPalette,
    neutralPalette: TonalPalette,
    neutralVariantPalette: TonalPalette,
    errorPalette: TonalPalette = fromHueAndChroma(25.0, 84.0),
};
