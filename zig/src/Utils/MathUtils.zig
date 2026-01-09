const std = @import("std");
const expect = std.testing.expect;
pub const Vec3 = @Vector(3, f32);
pub const Mat3 = [3]@Vector(3, f32);

pub fn dot(a: Vec3, b: Vec3) f32 {
    return @reduce(.Add, a * b);
}

pub fn mul(a: Vec3, b: Mat3) Vec3 {
    const x = dot(a, b[0]);
    const y = dot(a, b[1]);
    const z = dot(a, b[2]);
    return Vec3{ x, y, z };
}

// comptime matrix multiplication, don't need to optimize for speed
pub fn mulMat(comptime a: Mat3, comptime b: Mat3) Mat3 {
    var result: Mat3 = undefined;
    for (0..3) |i| {
        for (0..3) |j| {
            var sum: f32 = 0;
            for (0..3) |k| {
                sum += a[i][k] * b[k][j];
            }
            result[i][j] = sum;
        }
    }
    return result;
}

pub fn rotationDirection(current: f32, target: f32) f32 {
    const delta = @mod(target - current, 360);
    return if (delta <= 180) 1 else -1;
}

pub fn differenceDegrees(a: f32, b: f32) f32 {
    return 180 - @abs(@abs(a - b) - 180);
}
