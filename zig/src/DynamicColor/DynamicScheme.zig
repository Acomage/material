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

fn getAllPalette(s: DynamicScheme) [54]TonalPalette {
    var result: [54]TonalPalette = undefined;
    inline for (allMaterialDynamicColorsPalette, 0..) |palette, i| {
        result[i] = palette.getTonalPalette(s);
    }
    return result;
}

fn getAllTone(s: DynamicScheme) [54]f32 {
    var result: [54]f32 = undefined;
    inline for (allMaterialDynamicColorsToneFn, 0..) |toneFn, i| {
        result[i] = toneFn.*(s);
    }
    return result;
}

fn getAllArgb(s: DynamicScheme) [54]u32 {
    const palettes = getAllPalette(s);
    const tones = getAllTone(s);
    var result: [54]u32 = undefined;
    for (palettes, tones, 0..) |palette, tone, i| {
        result[i] = palette.getArgb(tone);
    }
    return result;
}

// pub fn showAllColors(file: *Writer, s: DynamicScheme) !void {
//     inline for (allMaterialDynamicColors) |materialColor| {
//         const colorValue = getArgb(materialColor, s);
//         const colorHex = hexFromArgb(colorValue);
//         try file.print("{s}: Color {s}\n", .{ materialColor.name, colorHex });
//     }
// }

pub fn showAllColors(file: *Writer, s: DynamicScheme) !void {
    const argbs = getAllArgb(s);
    inline for (allMaterialDynamicColorsName, 0..) |name, i| {
        const colorHex = hexFromArgb(argbs[i]);
        try file.print("{s}: Color {s}\n", .{ name, colorHex });
    }
}
