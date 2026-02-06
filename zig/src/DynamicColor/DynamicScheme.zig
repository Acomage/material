const std = @import("std");
const hct_mod = @import("../Hct/Hct.zig");
const types_mod = @import("Types.zig");
const dynamicColor_mod = @import("DynamicColor.zig");
const materialDynamicColor_mod = @import("MaterialDynamicColor.zig");
const stringUtils_mod = @import("../Utils/StringUtils.zig");
const tonalPalette_mod = @import("../Palettes/TonalPalette.zig");
const Hct = hct_mod.Hct;
const DynamicScheme = types_mod.DynamicScheme;
const TonalPalette = tonalPalette_mod.TonalPalette;
const allMaterialDynamicColors = materialDynamicColor_mod.allMaterialDynamicColors;
const allMaterialDynamicColorsName = materialDynamicColor_mod.allMaterialDynamicColorsName;
const allMaterialDynamicColorsToneFn = materialDynamicColor_mod.allMaterialDynamicColorsToneFn;
const allMaterialDynamicColorsPalette = materialDynamicColor_mod.allMaterialDynamicColorsPalette;
const hexFromArgb = stringUtils_mod.hexFromArgb;
const getArgb = dynamicColor_mod.getArgb;
const Writer = std.Io.Writer;

pub fn getRotatedHue(sourceColor: Hct, hues: [9]f32, rotations: [9]f32) f32 {
    const sourceHue = sourceColor.hue;
    for (0..8) |i| {
        const thisHue = hues[i];
        const nextHue = hues[i + 1];
        if (thisHue <= sourceHue and sourceHue < nextHue) {
            return @mod(sourceHue + rotations[i], 360.0);
        }
    }
    return sourceHue;
}

fn getAllPalette(s: DynamicScheme) [45]TonalPalette {
    var result: [45]TonalPalette = undefined;
    inline for (allMaterialDynamicColorsPalette, 0..) |palette, i| {
        result[i] = palette.getTonalPalette(s);
    }
    return result;
}

fn getAllTone(s: DynamicScheme) [45]f32 {
    var result: [45]f32 = undefined;
    inline for (allMaterialDynamicColorsToneFn, 0..) |toneFn, i| {
        result[i] = toneFn.*(s);
    }
    return result;
}

pub fn getAllArgb(s: DynamicScheme) [45]u32 {
    const palettes = getAllPalette(s);
    const tones = getAllTone(s);
    var result: [45]u32 = undefined;
    for (palettes, tones, 0..) |palette, tone, i| {
        result[i] = palette.getArgb(tone);
    }
    return result;
}

// pub fn showAllColors(file: *Writer, s: DynamicScheme) !void {
//     const argbs = getAllArgb(s);
//     inline for (allMaterialDynamicColorsName, 0..) |name, i| {
//         const colorHex = hexFromArgb(argbs[i]);
//         try file.print("{s}: Color {s}\n", .{ name, colorHex });
//     }
// }

pub fn allColors(s: DynamicScheme) allMaterialDynamicColors {
    const argbs = getAllArgb(s);
    const res = allMaterialDynamicColors{
        .primary = hexFromArgb(argbs[0]),
        .onPrimary = hexFromArgb(argbs[1]),
        .primaryContainer = hexFromArgb(argbs[2]),
        .onPrimaryContainer = hexFromArgb(argbs[3]),
        .inversePrimary = hexFromArgb(argbs[4]),
        .primaryFixed = hexFromArgb(argbs[5]),
        .primaryFixedDim = hexFromArgb(argbs[6]),
        .onPrimaryFixed = hexFromArgb(argbs[7]),
        .onPrimaryFixedVariant = hexFromArgb(argbs[8]),
        .secondary = hexFromArgb(argbs[9]),
        .onSecondary = hexFromArgb(argbs[10]),
        .secondaryContainer = hexFromArgb(argbs[11]),
        .onSecondaryContainer = hexFromArgb(argbs[12]),
        .secondaryFixed = hexFromArgb(argbs[13]),
        .secondaryFixedDim = hexFromArgb(argbs[14]),
        .onSecondaryFixed = hexFromArgb(argbs[15]),
        .onSecondaryFixedVariant = hexFromArgb(argbs[16]),
        .tertiary = hexFromArgb(argbs[17]),
        .onTertiary = hexFromArgb(argbs[18]),
        .tertiaryContainer = hexFromArgb(argbs[19]),
        .onTertiaryContainer = hexFromArgb(argbs[20]),
        .tertiaryFixed = hexFromArgb(argbs[21]),
        .tertiaryFixedDim = hexFromArgb(argbs[22]),
        .onTertiaryFixed = hexFromArgb(argbs[23]),
        .onTertiaryFixedVariant = hexFromArgb(argbs[24]),
        .surface = hexFromArgb(argbs[25]),
        .surfaceDim = hexFromArgb(argbs[26]),
        .surfaceBright = hexFromArgb(argbs[27]),
        .surfaceContainerLowest = hexFromArgb(argbs[28]),
        .surfaceContainerLow = hexFromArgb(argbs[29]),
        .surfaceContainer = hexFromArgb(argbs[30]),
        .surfaceContainerHigh = hexFromArgb(argbs[31]),
        .surfaceContainerHighest = hexFromArgb(argbs[32]),
        .onSurface = hexFromArgb(argbs[33]),
        .inverseSurface = hexFromArgb(argbs[34]),
        .inverseOnSurface = hexFromArgb(argbs[35]),
        .shadow = hexFromArgb(argbs[36]),
        .scrim = hexFromArgb(argbs[37]),
        .onSurfaceVariant = hexFromArgb(argbs[38]),
        .outline = hexFromArgb(argbs[39]),
        .outlineVariant = hexFromArgb(argbs[40]),
        .@"error" = hexFromArgb(argbs[41]),
        .onError = hexFromArgb(argbs[42]),
        .errorContainer = hexFromArgb(argbs[43]),
        .onErrorContainer = hexFromArgb(argbs[44]),
    };
    return res;
}
