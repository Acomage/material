const std = @import("std");

pub fn hexFromArgb(argb: u32) [7]u8 {
    var result: [7]u8 = undefined;
    result[0] = '#';

    const r: u8 = @intCast((argb >> 16) & 0xFF);
    const g: u8 = @intCast((argb >> 8) & 0xFF);
    const b: u8 = @intCast(argb & 0xFF);

    // 十六进制字符
    const hex = "0123456789ABCDEF";

    result[1] = hex[(r >> 4) & 0xF];
    result[2] = hex[r & 0xF];

    result[3] = hex[(g >> 4) & 0xF];
    result[4] = hex[g & 0xF];

    result[5] = hex[(b >> 4) & 0xF];
    result[6] = hex[b & 0xF];

    return result;
}

test hexFromArgb {
    const color: u32 = 0xFF3366CC; // ARGB format
    const hexStr = hexFromArgb(color);
    try std.testing.expectEqualStrings("#3366CC", &hexStr);
}
