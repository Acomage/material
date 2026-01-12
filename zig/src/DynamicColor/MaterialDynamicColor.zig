const types_mod = @import("Types.zig");
const dislike_mod = @import("../Dislike/DislikeAnalyzer.zig");
const dynamicColor_mod = @import("DynamicColor.zig");
const hct_mod = @import("../Hct/Hct.zig");
const ToneFn = types_mod.ToneFn;
const Palette = types_mod.Palette;
const DynamicScheme = types_mod.DynamicScheme;
const TonalPolarity = types_mod.TonalPolarity;
const DynamicColor = types_mod.DynamicColor;
const fixIfDisliked = dislike_mod.fixIfDisliked;
const fromInt = hct_mod.fromInt;
const fromPalette = dynamicColor_mod.fromPalette;
const darkLightConst = dynamicColor_mod.darkLightConst;
const withContrast = dynamicColor_mod.withContrast;
const darkLight = dynamicColor_mod.darkLight;
const constantTone = dynamicColor_mod.constantTone;
const fromCurve = dynamicColor_mod.fromCurve;
const fidelity = dynamicColor_mod.fidelity;
const monoChrome = dynamicColor_mod.monoChrome;
const monoChromeConst = dynamicColor_mod.monoChromeConst;
const pairCombinator = dynamicColor_mod.pairCombinator;
const withTwoBackgrounds = dynamicColor_mod.withTwoBackgrounds;
const foregroundTone = dynamicColor_mod.foregroundTone;
const findDesiredChromaByTone = dynamicColor_mod.findDesiredChromaByTone;

const primaryPaletteKeyColor: ToneFn = fromPalette(Palette.primary);

const secondaryPaletteKeyColor: ToneFn = fromPalette(Palette.secondary);

const tertiaryPaletteKeyColor: ToneFn = fromPalette(Palette.tertiary);

const neutralPaletteKeyColor: ToneFn = fromPalette(Palette.neutral);

const neutralVariantPaletteKeyColor: ToneFn = fromPalette(Palette.neutralVariant);

const background: ToneFn = darkLightConst(6.0, 98.0);

const onBackground: ToneFn = withContrast(
    background,
    .{
        .low = 0.0,
        .normal = 0.0,
        .medium = 0.0,
        .high = 0.0,
    },
    darkLightConst(90.0, 10.0),
);

const surface: ToneFn = background;

const surfaceDim: ToneFn = darkLight(
    constantTone(6.0),
    fromCurve(.{
        .low = 87.0,
        .normal = 87.0,
        .medium = 80.0,
        .high = 75.0,
    }),
);

const surfaceBright: ToneFn = darkLight(
    fromCurve(.{
        .low = 24.0,
        .normal = 24.0,
        .medium = 29.0,
        .high = 34.0,
    }),
    constantTone(98.0),
);

const surfaceContainerLowest: ToneFn = darkLight(
    fromCurve(.{
        .low = 4.0,
        .normal = 4.0,
        .medium = 2.0,
        .high = 0.0,
    }),
    constantTone(100.0),
);

const surfaceContainerLow: ToneFn = darkLight(
    fromCurve(.{
        .low = 10.0,
        .normal = 10.0,
        .medium = 11.0,
        .high = 12.0,
    }),
    fromCurve(.{
        .low = 96.0,
        .normal = 96.0,
        .medium = 96.0,
        .high = 95.0,
    }),
);

const surfaceContainer: ToneFn = darkLight(
    fromCurve(.{
        .low = 12.0,
        .normal = 12.0,
        .medium = 16.0,
        .high = 20.0,
    }),
    fromCurve(.{
        .low = 94.0,
        .normal = 94.0,
        .medium = 92.0,
        .high = 90.0,
    }),
);

const surfaceContainerHigh: ToneFn = darkLight(
    fromCurve(.{
        .low = 17.0,
        .normal = 17.0,
        .medium = 21.0,
        .high = 25.0,
    }),
    fromCurve(.{
        .low = 92.0,
        .normal = 92.0,
        .medium = 88.0,
        .high = 85.0,
    }),
);

const surfaceContainerHighest: ToneFn = darkLight(
    fromCurve(.{
        .low = 22.0,
        .normal = 22.0,
        .medium = 26.0,
        .high = 30.0,
    }),
    fromCurve(.{
        .low = 90.0,
        .normal = 90.0,
        .medium = 84.0,
        .high = 80.0,
    }),
);

const highestSurface: ToneFn = darkLight(surfaceBright, surfaceDim);

const onSurface: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 4.5,
        .normal = 7.0,
        .medium = 11.0,
        .high = 21.0,
    },
    darkLightConst(90.0, 10.0),
);

const surfaceVariant: ToneFn = darkLightConst(30.0, 90.0);

const onSurfaceVariant: ToneFn = withContrast(
    surfaceVariant,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 11.0,
    },
    darkLightConst(80.0, 30.0),
);

const inverseSurface: ToneFn = darkLightConst(90.0, 20.0);

const inverseOnSurface: ToneFn = withContrast(
    inverseSurface,
    .{
        .low = 4.5,
        .normal = 7.0,
        .medium = 11.0,
        .high = 21.0,
    },
    darkLightConst(20.0, 95.0),
);

const outline: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.5,
        .normal = 3.0,
        .medium = 4.5,
        .high = 7.0,
    },
    darkLightConst(60.0, 50.0),
);

const outlineVariant: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.0,
        .normal = 1.0,
        .medium = 3.0,
        .high = 4.5,
    },
    darkLightConst(30.0, 80.0),
);

const shadow: ToneFn = constantTone(0.0);

const scrim: ToneFn = shadow;

const surfaceTint: ToneFn = darkLightConst(80.0, 40.0);

fn helper1(s: DynamicScheme) f32 {
    return s.sourceColorHct.tone;
}

const primaryContainerTone: ToneFn = fidelity(
    helper1,
    monoChrome(
        darkLightConst(85.0, 25.0),
        darkLightConst(30.0, 90.0),
    ),
);

const primaryContainerBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.0,
        .normal = 1.0,
        .medium = 3.0,
        .high = 4.5,
    },
    primaryContainerTone,
);

const primaryBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 7.0,
    },
    monoChrome(
        darkLightConst(100.0, 0.0),
        darkLightConst(80.0, 40.0),
    ),
);

const primaryPair = pairCombinator(
    10.0,
    TonalPolarity.nearer,
    false,
    primaryContainerBase,
    primaryBase,
);

const primaryContainer: ToneFn = primaryPair[0];

const primary: ToneFn = primaryPair[1];

const onPrimary: ToneFn = withContrast(
    primary,
    .{
        .low = 4.5,
        .normal = 7.0,
        .medium = 11.0,
        .high = 21.0,
    },
    monoChrome(
        darkLightConst(10.0, 90.0),
        darkLightConst(20.0, 100.0),
    ),
);

fn helper2(s: DynamicScheme) f32 {
    return foregroundTone(primaryContainerTone(s), 4.5);
}

const onPrimaryContainer: ToneFn = withContrast(
    primaryContainer,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 11.0,
    },
    fidelity(
        helper2,
        monoChrome(
            darkLightConst(0.0, 100.0),
            darkLightConst(90.0, 30.0),
        ),
    ),
);

const inversePrimary: ToneFn = withContrast(
    inverseSurface,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 7.0,
    },
    darkLightConst(40.0, 80.0),
);

fn helper3(s: DynamicScheme) f32 {
    return findDesiredChromaByTone(
        s.secondaryPalette.hue,
        s.secondaryPalette.chroma,
        darkLightConst(30.0, 90.0)(s),
        !s.isDark,
    );
}

const secondaryContainerTone: ToneFn = monoChrome(
    darkLightConst(30.0, 85.0),
    fidelity(
        helper3,
        darkLightConst(30.0, 90.0),
    ),
);

const secondaryContainerBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.0,
        .normal = 1.0,
        .medium = 3.0,
        .high = 4.5,
    },
    secondaryContainerTone,
);

const secondaryBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 7.0,
    },
    darkLightConst(80.0, 40.0),
);

const secondaryPair = pairCombinator(
    10.0,
    TonalPolarity.nearer,
    false,
    secondaryContainerBase,
    secondaryBase,
);

const secondaryContainer: ToneFn = secondaryPair[0];

const secondary: ToneFn = secondaryPair[1];

const onSecondary: ToneFn = withContrast(
    secondary,
    .{
        .low = 4.5,
        .normal = 7.0,
        .medium = 11.0,
        .high = 21.0,
    },
    monoChrome(
        darkLightConst(10.0, 100.0),
        darkLightConst(20.0, 100.0),
    ),
);

fn helper4(s: DynamicScheme) f32 {
    return foregroundTone(secondaryContainerTone(s), 4.5);
}

const onSecondaryContainer: ToneFn = withContrast(
    secondaryContainer,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 11.0,
    },
    monoChrome(
        darkLightConst(90.0, 10.0),
        fidelity(
            helper4,
            darkLightConst(90.0, 30.0),
        ),
    ),
);

fn helper5(s: DynamicScheme) f32 {
    return fixIfDisliked(fromInt(s.tertiaryPalette.getArgb(s.sourceColorHct.tone))).tone;
}

const tertiaryContainerTone: ToneFn = monoChrome(
    darkLightConst(60.0, 49.0),
    fidelity(
        helper5,
        darkLightConst(30.0, 90.0),
    ),
);

const tertiaryContainerBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.0,
        .normal = 1.0,
        .medium = 3.0,
        .high = 4.5,
    },
    tertiaryContainerTone,
);

const tertiaryBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 7.0,
    },
    monoChrome(
        darkLightConst(90.0, 25.0),
        darkLightConst(80.0, 40.0),
    ),
);

const tertiaryPair = pairCombinator(
    10.0,
    TonalPolarity.nearer,
    false,
    tertiaryContainerBase,
    tertiaryBase,
);

const tertiaryContainer: ToneFn = tertiaryPair[0];

const tertiary: ToneFn = tertiaryPair[1];

const onTertiary: ToneFn = withContrast(
    tertiary,
    .{
        .low = 4.5,
        .normal = 7.0,
        .medium = 11.0,
        .high = 21.0,
    },
    monoChrome(
        darkLightConst(10.0, 90.0),
        darkLightConst(20.0, 100.0),
    ),
);

fn helper6(s: DynamicScheme) f32 {
    return foregroundTone(tertiaryContainerTone(s), 4.5);
}

const onTertiaryContainer: ToneFn = withContrast(
    tertiaryContainer,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 11.0,
    },
    monoChrome(
        darkLightConst(0.0, 100.0),
        fidelity(
            helper6,
            darkLightConst(90.0, 30.0),
        ),
    ),
);

const errorContainerBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.0,
        .normal = 1.0,
        .medium = 3.0,
        .high = 4.5,
    },
    darkLightConst(30.0, 90.0),
);

const errorBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 7.0,
    },
    darkLightConst(80.0, 40.0),
);

const errorPair = pairCombinator(
    10.0,
    TonalPolarity.nearer,
    false,
    errorContainerBase,
    errorBase,
);

const errorContainer: ToneFn = errorPair[0];

// `error` is zig's keyword, so we use `err` instead
// use @"error" is another option but I had used this style elsewhere
const err: ToneFn = errorPair[1];

const onError: ToneFn = withContrast(
    err,
    .{
        .low = 4.5,
        .normal = 7.0,
        .medium = 11.0,
        .high = 21.0,
    },
    darkLightConst(20.0, 100.0),
);

const onErrorContainer: ToneFn = withContrast(
    errorContainer,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 11.0,
    },
    monoChrome(
        darkLightConst(90.0, 10.0),
        darkLightConst(90.0, 30.0),
    ),
);

const primaryFixedBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.0,
        .normal = 1.0,
        .medium = 3.0,
        .high = 4.5,
    },
    monoChromeConst(40.0, 90.0),
);

const primaryFixedDimBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.0,
        .normal = 1.0,
        .medium = 3.0,
        .high = 4.5,
    },
    monoChromeConst(30.0, 80.0),
);

const primaryFixedPair = pairCombinator(
    10.0,
    TonalPolarity.lighter,
    true,
    primaryFixedBase,
    primaryFixedDimBase,
);

const primaryFixed: ToneFn = primaryFixedPair[0];

const primaryFixedDim: ToneFn = primaryFixedPair[1];

const onPrimaryFixed: ToneFn = withTwoBackgrounds(
    primaryFixedDim,
    primaryFixed,
    .{
        .low = 4.5,
        .normal = 7.0,
        .medium = 11.0,
        .high = 21.0,
    },
    monoChromeConst(100.0, 10.0),
);

const onPrimaryFixedVariant: ToneFn = withTwoBackgrounds(
    primaryFixedDim,
    primaryFixed,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 11.0,
    },
    monoChromeConst(90.0, 30.0),
);

const secondaryFixedBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.0,
        .normal = 1.0,
        .medium = 3.0,
        .high = 4.5,
    },
    monoChromeConst(80.0, 90.0),
);

const secondaryFixedDimBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.0,
        .normal = 1.0,
        .medium = 3.0,
        .high = 4.5,
    },
    monoChromeConst(70.0, 80.0),
);

const secondaryFixedPair = pairCombinator(
    10.0,
    TonalPolarity.lighter,
    true,
    secondaryFixedBase,
    secondaryFixedDimBase,
);

const secondaryFixed: ToneFn = secondaryFixedPair[0];

const secondaryFixedDim: ToneFn = secondaryFixedPair[1];

const onSecondaryFixed: ToneFn = withTwoBackgrounds(
    secondaryFixedDim,
    secondaryFixed,
    .{
        .low = 4.5,
        .normal = 7.0,
        .medium = 11.0,
        .high = 21.0,
    },
    constantTone(10.0),
);

const onSecondaryFixedVariant: ToneFn = withTwoBackgrounds(
    secondaryFixedDim,
    secondaryFixed,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 11.0,
    },
    monoChromeConst(25.0, 30.0),
);

const tertiaryFixedBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.0,
        .normal = 1.0,
        .medium = 3.0,
        .high = 4.5,
    },
    monoChromeConst(40.0, 90.0),
);

const tertiaryFixedDimBase: ToneFn = withContrast(
    highestSurface,
    .{
        .low = 1.0,
        .normal = 1.0,
        .medium = 3.0,
        .high = 4.5,
    },
    monoChromeConst(30.0, 80.0),
);

const tertiaryFixedPair = pairCombinator(
    10.0,
    TonalPolarity.lighter,
    true,
    tertiaryFixedBase,
    tertiaryFixedDimBase,
);

const tertiaryFixed: ToneFn = tertiaryFixedPair[0];

const tertiaryFixedDim: ToneFn = tertiaryFixedPair[1];

const onTertiaryFixed: ToneFn = withTwoBackgrounds(
    tertiaryFixedDim,
    tertiaryFixed,
    .{
        .low = 4.5,
        .normal = 7.0,
        .medium = 11.0,
        .high = 21.0,
    },
    monoChromeConst(100.0, 10.0),
);

const onTertiaryFixedVariant: ToneFn = withTwoBackgrounds(
    tertiaryFixedDim,
    tertiaryFixed,
    .{
        .low = 3.0,
        .normal = 4.5,
        .medium = 7.0,
        .high = 11.0,
    },
    monoChromeConst(90.0, 30.0),
);

pub const allMaterialDynamicColors: [54]DynamicColor = .{
    .{ .name = "primaryPaletteKeyColor", .toneFn = &primaryPaletteKeyColor, .palette = Palette.primary },
    .{ .name = "secondaryPaletteKeyColor", .toneFn = &secondaryPaletteKeyColor, .palette = Palette.secondary },
    .{ .name = "tertiaryPaletteKeyColor", .toneFn = &tertiaryPaletteKeyColor, .palette = Palette.tertiary },
    .{ .name = "neutralPaletteKeyColor", .toneFn = &neutralPaletteKeyColor, .palette = Palette.neutral },
    .{ .name = "neutralVariantPaletteKeyColor", .toneFn = &neutralVariantPaletteKeyColor, .palette = Palette.neutralVariant },
    .{ .name = "background", .toneFn = &background, .palette = Palette.neutral },
    .{ .name = "onBackground", .toneFn = &onBackground, .palette = Palette.neutral },
    .{ .name = "surface", .toneFn = &surface, .palette = Palette.neutral },
    .{ .name = "surfaceDim", .toneFn = &surfaceDim, .palette = Palette.neutral },
    .{ .name = "surfaceBright", .toneFn = &surfaceBright, .palette = Palette.neutral },
    .{ .name = "surfaceContainerLowest", .toneFn = &surfaceContainerLowest, .palette = Palette.neutral },
    .{ .name = "surfaceContainerLow", .toneFn = &surfaceContainerLow, .palette = Palette.neutral },
    .{ .name = "surfaceContainer", .toneFn = &surfaceContainer, .palette = Palette.neutral },
    .{ .name = "surfaceContainerHigh", .toneFn = &surfaceContainerHigh, .palette = Palette.neutral },
    .{ .name = "surfaceContainerHighest", .toneFn = &surfaceContainerHighest, .palette = Palette.neutral },
    .{ .name = "onSurface", .toneFn = &onSurface, .palette = Palette.neutral },
    .{ .name = "surfaceVariant", .toneFn = &surfaceVariant, .palette = Palette.neutralVariant },
    .{ .name = "onSurfaceVariant", .toneFn = &onSurfaceVariant, .palette = Palette.neutralVariant },
    .{ .name = "inverseSurface", .toneFn = &inverseSurface, .palette = Palette.neutral },
    .{ .name = "inverseOnSurface", .toneFn = &inverseOnSurface, .palette = Palette.neutral },
    .{ .name = "outline", .toneFn = &outline, .palette = Palette.neutralVariant },
    .{ .name = "outlineVariant", .toneFn = &outlineVariant, .palette = Palette.neutralVariant },
    .{ .name = "shadow", .toneFn = &shadow, .palette = Palette.neutral },
    .{ .name = "scrim", .toneFn = &scrim, .palette = Palette.neutral },
    .{ .name = "surfaceTint", .toneFn = &surfaceTint, .palette = Palette.primary },
    .{ .name = "primary", .toneFn = &primary, .palette = Palette.primary },
    .{ .name = "onPrimary", .toneFn = &onPrimary, .palette = Palette.primary },
    .{ .name = "primaryContainer", .toneFn = &primaryContainer, .palette = Palette.primary },
    .{ .name = "onPrimaryContainer", .toneFn = &onPrimaryContainer, .palette = Palette.primary },
    .{ .name = "inversePrimary", .toneFn = &inversePrimary, .palette = Palette.primary },
    .{ .name = "secondary", .toneFn = &secondary, .palette = Palette.secondary },
    .{ .name = "onSecondary", .toneFn = &onSecondary, .palette = Palette.secondary },
    .{ .name = "secondaryContainer", .toneFn = &secondaryContainer, .palette = Palette.secondary },
    .{ .name = "onSecondaryContainer", .toneFn = &onSecondaryContainer, .palette = Palette.secondary },
    .{ .name = "tertiary", .toneFn = &tertiary, .palette = Palette.tertiary },
    .{ .name = "onTertiary", .toneFn = &onTertiary, .palette = Palette.tertiary },
    .{ .name = "tertiaryContainer", .toneFn = &tertiaryContainer, .palette = Palette.tertiary },
    .{ .name = "onTertiaryContainer", .toneFn = &onTertiaryContainer, .palette = Palette.tertiary },
    .{ .name = "error", .toneFn = &err, .palette = Palette.err },
    .{ .name = "onError", .toneFn = &onError, .palette = Palette.err },
    .{ .name = "errorContainer", .toneFn = &errorContainer, .palette = Palette.err },
    .{ .name = "onErrorContainer", .toneFn = &onErrorContainer, .palette = Palette.err },
    .{ .name = "primaryFixed", .toneFn = &primaryFixed, .palette = Palette.primary },
    .{ .name = "primaryFixedDim", .toneFn = &primaryFixedDim, .palette = Palette.primary },
    .{ .name = "onPrimaryFixed", .toneFn = &onPrimaryFixed, .palette = Palette.primary },
    .{ .name = "onPrimaryFixedVariant", .toneFn = &onPrimaryFixedVariant, .palette = Palette.primary },
    .{ .name = "secondaryFixed", .toneFn = &secondaryFixed, .palette = Palette.secondary },
    .{ .name = "secondaryFixedDim", .toneFn = &secondaryFixedDim, .palette = Palette.secondary },
    .{ .name = "onSecondaryFixed", .toneFn = &onSecondaryFixed, .palette = Palette.secondary },
    .{ .name = "onSecondaryFixedVariant", .toneFn = &onSecondaryFixedVariant, .palette = Palette.secondary },
    .{ .name = "tertiaryFixed", .toneFn = &tertiaryFixed, .palette = Palette.tertiary },
    .{ .name = "tertiaryFixedDim", .toneFn = &tertiaryFixedDim, .palette = Palette.tertiary },
    .{ .name = "onTertiaryFixed", .toneFn = &onTertiaryFixed, .palette = Palette.tertiary },
    .{ .name = "onTertiaryFixedVariant", .toneFn = &onTertiaryFixedVariant, .palette = Palette.tertiary },
};

pub const allMaterialDynamicColorsName: [54][]const u8 = .{
    "primaryPaletteKeyColor",
    "secondaryPaletteKeyColor",
    "tertiaryPaletteKeyColor",
    "neutralPaletteKeyColor",
    "neutralVariantPaletteKeyColor",
    "background",
    "onBackground",
    "surface",
    "surfaceDim",
    "surfaceBright",
    "surfaceContainerLowest",
    "surfaceContainerLow",
    "surfaceContainer",
    "surfaceContainerHigh",
    "surfaceContainerHighest",
    "onSurface",
    "surfaceVariant",
    "onSurfaceVariant",
    "inverseSurface",
    "inverseOnSurface",
    "outline",
    "outlineVariant",
    "shadow",
    "scrim",
    "surfaceTint",
    "primary",
    "onPrimary",
    "primaryContainer",
    "onPrimaryContainer",
    "inversePrimary",
    "secondary",
    "onSecondary",
    "secondaryContainer",
    "onSecondaryContainer",
    "tertiary",
    "onTertiary",
    "tertiaryContainer",
    "onTertiaryContainer",
    "error",
    "onError",
    "errorContainer",
    "onErrorContainer",
    "primaryFixed",
    "primaryFixedDim",
    "onPrimaryFixed",
    "onPrimaryFixedVariant",
    "secondaryFixed",
    "secondaryFixedDim",
    "onSecondaryFixed",
    "onSecondaryFixedVariant",
    "tertiaryFixed",
    "tertiaryFixedDim",
    "onTertiaryFixed",
    "onTertiaryFixedVariant",
};

pub const allMaterialDynamicColorsToneFn: [54]*const ToneFn = .{
    &primaryPaletteKeyColor,
    &secondaryPaletteKeyColor,
    &tertiaryPaletteKeyColor,
    &neutralPaletteKeyColor,
    &neutralVariantPaletteKeyColor,
    &background,
    &onBackground,
    &surface,
    &surfaceDim,
    &surfaceBright,
    &surfaceContainerLowest,
    &surfaceContainerLow,
    &surfaceContainer,
    &surfaceContainerHigh,
    &surfaceContainerHighest,
    &onSurface,
    &surfaceVariant,
    &onSurfaceVariant,
    &inverseSurface,
    &inverseOnSurface,
    &outline,
    &outlineVariant,
    &shadow,
    &scrim,
    &surfaceTint,
    &primary,
    &onPrimary,
    &primaryContainer,
    &onPrimaryContainer,
    &inversePrimary,
    &secondary,
    &onSecondary,
    &secondaryContainer,
    &onSecondaryContainer,
    &tertiary,
    &onTertiary,
    &tertiaryContainer,
    &onTertiaryContainer,
    &err,
    &onError,
    &errorContainer,
    &onErrorContainer,
    &primaryFixed,
    &primaryFixedDim,
    &onPrimaryFixed,
    &onPrimaryFixedVariant,
    &secondaryFixed,
    &secondaryFixedDim,
    &onSecondaryFixed,
    &onSecondaryFixedVariant,
    &tertiaryFixed,
    &tertiaryFixedDim,
    &onTertiaryFixed,
    &onTertiaryFixedVariant,
};

pub const allMaterialDynamicColorsPalette: [54]Palette = .{
    Palette.primary,
    Palette.secondary,
    Palette.tertiary,
    Palette.neutral,
    Palette.neutralVariant,
    Palette.neutral,
    Palette.neutral,
    Palette.neutral,
    Palette.neutral,
    Palette.neutral,
    Palette.neutral,
    Palette.neutral,
    Palette.neutral,
    Palette.neutral,
    Palette.neutral,
    Palette.neutral,
    Palette.neutralVariant,
    Palette.neutralVariant,
    Palette.neutral,
    Palette.neutral,
    Palette.neutralVariant,
    Palette.neutralVariant,
    Palette.neutral,
    Palette.neutral,
    Palette.primary,
    Palette.primary,
    Palette.primary,
    Palette.primary,
    Palette.primary,
    Palette.primary,
    Palette.secondary,
    Palette.secondary,
    Palette.secondary,
    Palette.secondary,
    Palette.tertiary,
    Palette.tertiary,
    Palette.tertiary,
    Palette.tertiary,
    Palette.err,
    Palette.err,
    Palette.err,
    Palette.err,
    Palette.primary,
    Palette.primary,
    Palette.primary,
    Palette.primary,
    Palette.secondary,
    Palette.secondary,
    Palette.secondary,
    Palette.secondary,
    Palette.tertiary,
    Palette.tertiary,
    Palette.tertiary,
    Palette.tertiary,
};
