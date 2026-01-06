const mathUtils = @import("MathUtils.zig");
const Mat3 = mathUtils.Mat3;

const SRGB_TO_XYZ: Mat3 = .{
    @Vector(3, f64){ 0.41233895, 0.35762064, 0.18051042 },
    @Vector(3, f64){ 0.2126, 0.7152, 0.0722 },
    @Vector(3, f64){ 0.01932141, 0.11916382, 0.95034478 },
};

const XYZ_TO_SRGB: Mat3 = .{
    @Vector(3, f64){ 3.2413774792388685, -1.5376652402851851, -0.49885366846268053 },
    @Vector(3, f64){ -0.9691452513005321, 1.8758853451067872, 0.04156585616912061 },
    @Vector(3, f64){ 0.05562093689691305, -0.20395524564742123, 1.0571799111220335 },
};

const WHITE_POINT_D65: @Vector(3, f64) = .{
    100 * @reduce(.Add, SRGB_TO_XYZ[0]),
    100 * @reduce(.Add, SRGB_TO_XYZ[1]),
    100 * @reduce(.Add, SRGB_TO_XYZ[2]),
};
