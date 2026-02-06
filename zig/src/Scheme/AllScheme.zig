const std = @import("std");
const hct_mod = @import("../Hct/Hct.zig");
const temperature_mod = @import("../Temperature/TemperatureCache.zig");
const materialDynamicColor_mod = @import("../DynamicColor/MaterialDynamicColor.zig");
const schemeContent_mod = @import("SchemeContent.zig");
const schemeExpressive_mod = @import("SchemeExpressive.zig");
const schemeFidelity_mod = @import("SchemeFidelity.zig");
const schemeFruitSalad_mod = @import("SchemeFruitSalad.zig");
const schemeMonoChrome_mod = @import("SchemeMonoChrome.zig");
const schemeNeutral_mod = @import("SchemeNeutral.zig");
const schemeRainbow_mod = @import("SchemeRainbow.zig");
const schemeTonalSpot_mod = @import("SchemeTonalSpot.zig");
const schemeVibrant_mod = @import("SchemeVibrant.zig");
const dynamicScheme_mod = @import("../DynamicColor/DynamicScheme.zig");
const temperatureCache = temperature_mod.TemperatureCache;
const fromInt = hct_mod.fromInt;
const schemeContent = schemeContent_mod.schemeContent;
const schemeExpressive = schemeExpressive_mod.schemeExpressive;
const schemeFidelity = schemeFidelity_mod.schemeFidelity;
const schemeFruitSalad = schemeFruitSalad_mod.schemeFruitSalad;
const schemeMonoChrome = schemeMonoChrome_mod.schemeMonoChrome;
const schemeNeutral = schemeNeutral_mod.schemeNeutral;
const schemeRainbow = schemeRainbow_mod.schemeRainbow;
const schemeTonalSpot = schemeTonalSpot_mod.schemeTonalSpot;
const schemeVibrant = schemeVibrant_mod.schemeVibrant;
const allColors = dynamicScheme_mod.allColors;
const allMaterialDynamicColors = materialDynamicColor_mod.allMaterialDynamicColors;

pub const allSchemeColor = struct {
    contentLight: allMaterialDynamicColors,
    contentDark: allMaterialDynamicColors,
    expressiveLight: allMaterialDynamicColors,
    expressiveDark: allMaterialDynamicColors,
    fidelityLight: allMaterialDynamicColors,
    fidelityDark: allMaterialDynamicColors,
    fruitSaladLight: allMaterialDynamicColors,
    fruitSaladDark: allMaterialDynamicColors,
    monoChromeLight: allMaterialDynamicColors,
    monoChromeDark: allMaterialDynamicColors,
    neutralLight: allMaterialDynamicColors,
    neutralDark: allMaterialDynamicColors,
    rainbowLight: allMaterialDynamicColors,
    rainbowDark: allMaterialDynamicColors,
    tonalSpotLight: allMaterialDynamicColors,
    tonalSpotDark: allMaterialDynamicColors,
    vibrantLight: allMaterialDynamicColors,
    vibrantDark: allMaterialDynamicColors,
};

pub fn allSchemes(colorInt: u32, contrastLevel: f32) allSchemeColor {
    const color = fromInt(colorInt);
    const cache = temperatureCache.make(color);
    const contentLight = schemeContent(color, false, contrastLevel, cache);
    const contentDark = schemeContent(color, true, contrastLevel, cache);
    const expressiveLight = schemeExpressive(color, false, contrastLevel);
    const expressiveDark = schemeExpressive(color, true, contrastLevel);
    const fidelityLight = schemeFidelity(color, false, contrastLevel, cache);
    const fidelityDark = schemeFidelity(color, true, contrastLevel, cache);
    const fruitSaladLight = schemeFruitSalad(color, false, contrastLevel);
    const fruitSaladDark = schemeFruitSalad(color, true, contrastLevel);
    const monoChromeLight = schemeMonoChrome(color, false, contrastLevel);
    const monoChromeDark = schemeMonoChrome(color, true, contrastLevel);
    const neutralLight = schemeNeutral(color, false, contrastLevel);
    const neutralDark = schemeNeutral(color, true, contrastLevel);
    const rainbowLight = schemeRainbow(color, false, contrastLevel);
    const rainbowDark = schemeRainbow(color, true, contrastLevel);
    const tonalSpotLight = schemeTonalSpot(color, false, contrastLevel);
    const tonalSpotDark = schemeTonalSpot(color, true, contrastLevel);
    const vibrantLight = schemeVibrant(color, false, contrastLevel);
    const vibrantDark = schemeVibrant(color, true, contrastLevel);
    const res = allSchemeColor{
        .contentLight = allColors(contentLight),
        .contentDark = allColors(contentDark),
        .expressiveLight = allColors(expressiveLight),
        .expressiveDark = allColors(expressiveDark),
        .fidelityLight = allColors(fidelityLight),
        .fidelityDark = allColors(fidelityDark),
        .fruitSaladLight = allColors(fruitSaladLight),
        .fruitSaladDark = allColors(fruitSaladDark),
        .monoChromeLight = allColors(monoChromeLight),
        .monoChromeDark = allColors(monoChromeDark),
        .neutralLight = allColors(neutralLight),
        .neutralDark = allColors(neutralDark),
        .rainbowLight = allColors(rainbowLight),
        .rainbowDark = allColors(rainbowDark),
        .tonalSpotLight = allColors(tonalSpotLight),
        .tonalSpotDark = allColors(tonalSpotDark),
        .vibrantLight = allColors(vibrantLight),
        .vibrantDark = allColors(vibrantDark),
    };
    return res;
}
