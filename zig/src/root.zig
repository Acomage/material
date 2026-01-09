const std = @import("std");
test {
    _ = .{
        // @import("Utils/MathUtils.zig"),
        // @import("Utils/ColorUtils.zig"),
        // @import("Hct/ViewingConditions.zig"),
        // @import("Hct/HctSolver.zig"),
        @import("Hct/MaxChroma.zig"),
    };
}
