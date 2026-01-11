const hctSolver_mod = @import("Hct/HctSolver.zig");
const precomputeRMin = hctSolver_mod.precomputeRMin;
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const rMin = precomputeRMin();
    print("rMin values: {d}\n", .{rMin});
}
