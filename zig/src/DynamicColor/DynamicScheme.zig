const std = @import("std");
const hct_mod = @import("../Hct/Hct.zig");
const types_mod = @import("Types.zig");
const dynamicColor_mod = @import("DynamicColor.zig");
const materialDynamicColor_mod = @import("MaterialDynamicColor.zig");
const stringUtils_mod = @import("../Utils/StringUtils.zig");
const Hct = hct_mod.Hct;
const DynamicScheme = types_mod.DynamicScheme;
const allMaterialDynamicColors = materialDynamicColor_mod.allMaterialDynamicColors;
const hexFromArgb = stringUtils_mod.hexFromArgb;
const getArgb = dynamicColor_mod.getArgb;

const io = std.Options.debug_io;

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

pub fn showAllColors(s: DynamicScheme) !void {
    var stdout_writer = std.Io.File.stdout().writer(io, &.{});
    const stdout = &stdout_writer.interface;
    inline for (allMaterialDynamicColors) |materialColor| {
        const colorValue = getArgb(materialColor, s);
        const colorHex = hexFromArgb(colorValue);
        try stdout.print("{s}: {s}\n", .{ materialColor.name, colorHex });
    }
}
