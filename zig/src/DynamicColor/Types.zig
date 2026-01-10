const std = @import("std");
const tonalPalette_mod = @import("../Palettes/TonalPalette.zig");
const hct_mod = @import("../Hct/Hct.zig");
const dynamicScheme_mod = @import("../Scheme/DynamicScheme.zig");
const lerp = std.math.lerp;
const DynamicScheme = dynamicScheme_mod.DynamicScheme;
const TonalPalette = tonalPalette_mod.TonalPalette;

pub const ContrastCurve = struct {
    low: f32,
    normal: f32,
    medium: f32,
    high: f32,
    fn get(self: ContrastCurve, contrast_level: f32) f32 {
        if (contrast_level <= -1.0) {
            return self.low;
        } else if (contrast_level < 0.0) {
            return lerp(self.low, self.normal, contrast_level + 1.0);
        } else if (contrast_level < 0.5) {
            return lerp(self.normal, self.medium, contrast_level * 2.0);
        } else if (contrast_level < 1.0) {
            return lerp(self.medium, self.high, contrast_level * 2.0 - 1.0);
        } else {
            return self.high;
        }
    }
};

pub const TonalPolarity = enum {
    darker,
    lighter,
    nearer,
    farther,
};

pub const Palette = enum {
    primary,
    secondary,
    tertiary,
    neutral,
    neutralVariant,
    err,
    pub fn getTone(self: Palette, s: DynamicScheme) f32 {
        switch (self) {
            Palette.primary => return s.primaryPalette.keyColor.tone,
            Palette.secondary => return s.secondaryPalette.keyColor.tone,
            Palette.tertiary => return s.tertiaryPalette.keyColor.tone,
            Palette.neutral => return s.neutralPalette.keyColor.tone,
            Palette.neutralVariant => return s.neutralVariantPalette.keyColor.tone,
            Palette.err => return s.errorPalette.keyColor.tone,
        }
    }
    pub fn getTonalPalette(self: Palette, s: DynamicScheme) TonalPalette {
        switch (self) {
            Palette.primary => return s.primaryPalette,
            Palette.secondary => return s.secondaryPalette,
            Palette.tertiary => return s.tertiaryPalette,
            Palette.neutral => return s.neutralPalette,
            Palette.neutralVariant => return s.neutralVariantPalette,
            Palette.err => return s.errorPalette,
        }
    }
};

pub const ToneFn = fn (s: DynamicScheme) f32;

pub const ToneFnPair = fn (s: DynamicScheme) [2]f32;

pub const DynamicColor = struct {
    name: []const u8,
    toneFn: ToneFn,
    palette: Palette,
};
