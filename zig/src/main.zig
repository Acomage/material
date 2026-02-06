const std = @import("std");
const load_image_mod = @import("Extract/load_image.zig");
const extract_mod = @import("Extract/extract.zig");
// const hct_mod = @import("Hct/Hct.zig");
const stringUtils_mod = @import("Utils/StringUtils.zig");
// const temperature_mod = @import("Temperature/TemperatureCache.zig");
// const schemeContent_mod = @import("Scheme/SchemeContent.zig");
// const schemeExpressive_mod = @import("Scheme/SchemeExpressive.zig");
// const schemeFidelity_mod = @import("Scheme/SchemeFidelity.zig");
// const schemeFruitSalad_mod = @import("Scheme/SchemeFruitSalad.zig");
// const schemeMonoChrome_mod = @import("Scheme/SchemeMonoChrome.zig");
// const schemeNeutral_mod = @import("Scheme/SchemeNeutral.zig");
// const schemeRainbow_mod = @import("Scheme/SchemeRainbow.zig");
// const schemeTonalSpot_mod = @import("Scheme/SchemeTonalSpot.zig");
// const schemeVibrant_mod = @import("Scheme/SchemeVibrant.zig");
const dynamicScheme_mod = @import("DynamicColor/DynamicScheme.zig");
const allScheme_mod = @import("Scheme/AllScheme.zig");
// const temperatureCache = temperature_mod.TemperatureCache;
const loadImageSubsample = load_image_mod.loadImageSubsample;
const extract = extract_mod.extract;
const hexFromArgb = stringUtils_mod.hexFromArgb;
// const fromInt = hct_mod.fromInt;
// const schemeContent = schemeContent_mod.schemeContent;
// const schemeExpressive = schemeExpressive_mod.schemeExpressive;
// const schemeFidelity = schemeFidelity_mod.schemeFidelity;
// const schemeFruitSalad = schemeFruitSalad_mod.schemeFruitSalad;
// const schemeMonoChrome = schemeMonoChrome_mod.schemeMonoChrome;
// const schemeNeutral = schemeNeutral_mod.schemeNeutral;
// const schemeRainbow = schemeRainbow_mod.schemeRainbow;
// const schemeTonalSpot = schemeTonalSpot_mod.schemeTonalSpot;
// const schemeVibrant = schemeVibrant_mod.schemeVibrant;
// const showAllColors = dynamicScheme_mod.showAllColors;
const allSchemes = allScheme_mod.allSchemes;

var threaded: std.Io.Threaded = .init_single_threaded;
const io = threaded.io();

pub fn main() !void {
    const args_c_style = std.os.argv;
    if (args_c_style.len != 2) {
        std.debug.print("Usage: {s} <image_path>", .{std.mem.span(args_c_style[0])});
        return;
    }
    const image_path: [*:0]const u8 = std.mem.span(args_c_style[1]);
    var stdout_writer = std.Io.File.stdout().writer(io, &.{});
    const stdout = &stdout_writer.interface;
    var rgb: [60000]u8 = undefined;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const out_count = try loadImageSubsample(allocator, &rgb, image_path);
    // try stdout.print("Extract colors from {s}\n", .{image_path});
    const extracted_colors = extract(128, rgb[0 .. out_count * 3], 4);
    try stdout.print("Extracted 4 Colors:\n", .{});
    for (extracted_colors) |color| {
        try stdout.print("{s}\n", .{hexFromArgb(color)});
    }
    // try stdout.print("Use source color {s} to create scheme\n", .{hexFromArgb(extracted_colors[0])});
    try stdout.print("{f}\n", .{std.json.fmt(allSchemes(extracted_colors[0], 0.0), .{ .whitespace = .indent_2 })});
}
