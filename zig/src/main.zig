const std = @import("std");
const load_image_mod = @import("Extract/load_image.zig");
const extract_mod = @import("Extract/extract.zig");
const loadImageSubsample = load_image_mod.loadImageSubsample;
const extract = extract_mod.extract;

const io = std.Options.debug_io;

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
    const extracted_colors = extract(128, rgb[0 .. out_count * 3], 4);
    for (extracted_colors) |color| {
        try stdout.print("Color: {x}\n", .{color});
    }
}
