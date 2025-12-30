module
public import Material.DynamicColor.Types
public import Material.Dislike.DislikeAnalyzer
public import Material.DynamicColor.DynamicColor

open MathUtils DislikeAnalyzer

def primaryPaletteKeyColor : ToneFn :=
  fromPalette (fun ds => ds.primaryPalette)

def secondaryPaletteKeyColor : ToneFn :=
  fromPalette (fun ds => ds.secondaryPalette)

def tertiaryPaletteKeyColor : ToneFn :=
  fromPalette (fun ds => ds.tertiaryPalette)

def neutralPaletteKeyColor : ToneFn :=
  fromPalette (fun ds => ds.neutralPalette)

def neutralVariantPaletteKeyColor : ToneFn :=
  fromPalette (fun ds => ds.neutralVariantPalette)

def background : ToneFn :=
  darkLightConst 6.0 98.0

def onBackground : ToneFn :=
  withContrast background ⟨3.0, 3.0, 4.5, 7.0⟩ (darkLightConst 90.0 10.0)

def surface : ToneFn :=
  darkLightConst 6.0 98.0

def surfaceDim : ToneFn :=
  darkLight (constantTone 6.0) (fromCurve ⟨87.0, 87.0, 80.0, 75.0⟩)

def surfaceBright : ToneFn :=
  darkLight (fromCurve ⟨24.0, 24.0, 29.0, 34.0⟩) (constantTone 98.0)

def surfaceContainerLowest : ToneFn :=
  darkLight (fromCurve ⟨4.0, 4.0, 2.0, 0.0⟩) (constantTone 100.0)

def surfaceContainerLow : ToneFn :=
  darkLight (fromCurve ⟨10.0, 10.0, 11.0, 12.0⟩) (fromCurve ⟨96.0, 96.0, 96.0, 95.0⟩)

def surfaceContainer : ToneFn :=
  darkLight (fromCurve ⟨12.0, 12.0, 16.0, 20.0⟩) (fromCurve ⟨94.0, 94.0, 92.0, 90.0⟩)

def surfaceContainerHigh : ToneFn :=
  darkLight (fromCurve ⟨17.0, 17.0, 21.0, 25.0⟩) (fromCurve ⟨92.0, 92.0, 88.0, 85.0⟩)

def surfaceContainerHighest : ToneFn :=
  darkLight (fromCurve ⟨22.0, 22.0, 26.0, 30.0⟩) (fromCurve ⟨90.0, 90.0, 84.0, 80.0⟩)

def hightestSurface : ToneFn :=
  darkLight surfaceBright surfaceDim

def onSurface : ToneFn :=
  withContrast hightestSurface ⟨4.5, 7.0, 11.0, 21.0⟩ (darkLightConst 90.0 10.0)

def surfaceVariant : ToneFn :=
  darkLightConst 30.0 90.0

def onSurfaceVariant : ToneFn :=
  withContrast hightestSurface ⟨3.0, 4.5, 7.0, 11.0⟩ (darkLightConst 80.0 30.0)

def inverseSurface : ToneFn :=
  darkLightConst 90.0 20.0

def inverseOnSurface : ToneFn :=
  withContrast inverseSurface ⟨4.5, 7.0, 11.0, 21.0⟩ (darkLightConst 20.0 95.0)

def outline : ToneFn :=
  withContrast hightestSurface ⟨1.5, 3.0, 4.5, 7.0⟩ (darkLightConst 60.0 50.0)

def outlineVariant : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (darkLightConst 30.0 80.0)

def shadow : ToneFn :=
  constantTone 0.0

def scrim : ToneFn :=
  constantTone 0.0

def surfaceTint : ToneFn :=
  darkLightConst 80.0 40.0

def primaryContainerTone : ToneFn :=
  fidelity (fun s => s.sourceColorHct.tone) (monoChrome (darkLightConst 85.0 25.0) (darkLightConst 30.0 90.0))

def primaryContainerBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ primaryContainerTone

def primaryBase : ToneFn :=
  withContrast hightestSurface ⟨3.0, 4.5, 7.0, 7.0⟩ (monoChrome (darkLightConst 100.0 0.0) (darkLightConst 80.0 40.0))

def primaryPair : ToneFnPair := pair 10.0 TonePolarity.nearer false primaryContainerBase primaryBase

def primaryGroup : ToneFnGroup :=
  group0 primaryPair
    ⟨3.0, 4.5, 7.0, 11.0⟩
    ⟨4.5, 7.0, 11.0, 21.0⟩
    (fidelity
      (fun s => foregroundTone (primaryContainerTone s) 4.5)
      (monoChrome (darkLightConst 0.0 100.0) (darkLightConst 90.0 30.0)))
    (monoChrome (darkLightConst 10.0 90.0) (darkLightConst 20.0 100.0))

def inversePrimary : ToneFn :=
  withContrast inverseSurface ⟨3.0, 4.5, 7.0, 7.0⟩ (darkLightConst 40.0 80.0)

def secondaryContainerTone : ToneFn :=
  monoChrome
    (darkLightConst 30.0 85.0)
    (fidelity
      (fun s => findDesiredChromaByTone s.secondaryPalette.hue s.secondaryPalette.chroma (darkLightConst 30.0 90.0 s) (not s.isDark))
      (darkLightConst 30.0 90.0))

def secondaryContainerBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ secondaryContainerTone

def secondaryBase : ToneFn :=
  withContrast hightestSurface ⟨3.0, 4.5, 7.0, 7.0⟩ (darkLightConst 80.0 40.0)

def secondaryPair : ToneFnPair := pair 10.0 TonePolarity.nearer false secondaryContainerBase secondaryBase

def secondaryGroup : ToneFnGroup :=
  group0 secondaryPair
    ⟨3.0, 4.5, 7.0, 11.0⟩
    ⟨4.5, 7.0, 11.0, 21.0⟩
    (monoChrome
      (darkLightConst 90.0 10.0)
      (fidelity
        (fun s => foregroundTone (secondaryContainerTone s) 4.5)
     (darkLightConst 90.0 30.0)))
    (monoChrome (darkLightConst 10.0 100.0) (darkLightConst 20.0 100.0))

def tertiaryContainerTone : ToneFn :=
  monoChrome
    (darkLightConst 60.0 49.0)
    (fidelity
      (fun s =>
        (fixIfDisliked
          (Hct.fromInt
            (s.tertiaryPalette.getArgb s.sourceColorHct.tone)
          )
        ).tone)
      (darkLightConst 30.0 90.0))

def tertiaryContainerBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ tertiaryContainerTone

def tertiaryBase : ToneFn :=
  withContrast hightestSurface ⟨3.0, 4.5, 7.0, 7.0⟩ (monoChrome (darkLightConst 90.0 25.0) (darkLightConst 80.0 40.0))

def tertiaryPair : ToneFnPair := pair 10.0 TonePolarity.nearer false tertiaryContainerBase tertiaryBase

def tertiaryGroup : ToneFnGroup :=
  group0 tertiaryPair
    ⟨3.0, 4.5, 7.0, 11.0⟩
    ⟨4.5, 7.0, 11.0, 21.0⟩
    (monoChrome
      (darkLightConst 0.0 100.0)
      (fidelity
        (fun s => foregroundTone (tertiaryContainerTone s) 4.5)
        (darkLightConst 90.0 30.0)))
    (monoChrome (darkLightConst 10.0 90.0) (darkLightConst 20.0 100.0))

def errorContainerBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (darkLightConst 30.0 90.0)

def errorBase : ToneFn :=
  withContrast hightestSurface ⟨3.0, 4.5, 7.0, 7.0⟩ (darkLightConst 80.0 40.0)

def errorPair : ToneFnPair := pair 10.0 TonePolarity.nearer false errorContainerBase errorBase

def errorGroup : ToneFnGroup :=
  group0 errorPair
    ⟨3.0, 4.5, 7.0, 11.0⟩
    ⟨4.5, 7.0, 11.0, 21.0⟩
    (monoChrome (darkLightConst 90.0 10.0) (darkLightConst 90.0 30.0))
    (darkLightConst 20.0 100.0)

def primaryFixedBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 40.0 90.0)

def primaryFixedDimBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 30.0 80.0)

def primaryFixedPair : ToneFnPair := pair 10.0 TonePolarity.lighter true primaryFixedBase primaryFixedDimBase

def primaryFixedGroup : ToneFnGroup :=
  group1 primaryFixedPair
    ⟨4.5, 7.0, 11.0, 21.0⟩
    ⟨3.0, 4.5, 7.0, 11.0⟩
    (monoChromeConst 100.0 10.0)
    (monoChromeConst 90.0 30.0)

def secondaryFixedBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 80.0 90.0)

def secondaryFixedDimBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 70.0 80.0)

def secondaryFixedPair : ToneFnPair := pair 10.0 TonePolarity.lighter true secondaryFixedBase secondaryFixedDimBase

def secondaryFixedGroup : ToneFnGroup :=
  group1 secondaryFixedPair
    ⟨4.5, 7.0, 11.0, 21.0⟩
    ⟨3.0, 4.5, 7.0, 11.0⟩
    (constantTone 10.0)
    (monoChromeConst 25.0 30.0)

def tertiaryFixedBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 40.0 90.0)

def tertiaryFixedDimBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 30.0 80.0)

def tertiaryFixedPair : ToneFnPair := pair 10.0 TonePolarity.lighter true tertiaryFixedBase tertiaryFixedDimBase

def tertiaryFixedGroup : ToneFnGroup :=
  group1 tertiaryFixedPair
    ⟨4.5, 7.0, 11.0, 21.0⟩
    ⟨3.0, 4.5, 7.0, 11.0⟩
    (monoChromeConst 100.0 10.0)
    (monoChromeConst 90.0 30.0)

public def allMaterialDynamicColors : (List DynamicColor) × (List DynamicColorGroup) :=
  ([
    ⟨"primaryPaletteKeyColor", primaryPaletteKeyColor, .primary⟩,
    ⟨"secondaryPaletteKeyColor", secondaryPaletteKeyColor, .secondary⟩,
    ⟨"tertiaryPaletteKeyColor", tertiaryPaletteKeyColor, .tertiary⟩,
    ⟨"neutralPaletteKeyColor", neutralPaletteKeyColor, .neutral⟩,
    ⟨"neutralVariantPaletteKeyColor", neutralVariantPaletteKeyColor, .neutralVariant⟩,
    ⟨"background", background, .neutral⟩,
    ⟨"onBackground", onBackground, .neutral⟩,
    ⟨"surface", surface, .neutral⟩,
    ⟨"surfaceDim", surfaceDim, .neutral⟩,
    ⟨"surfaceBright", surfaceBright, .neutral⟩,
    ⟨"surfaceContainerLowest", surfaceContainerLowest, .neutral⟩,
    ⟨"surfaceContainerLow", surfaceContainerLow, .neutral⟩,
    ⟨"surfaceContainer", surfaceContainer, .neutral⟩,
    ⟨"surfaceContainerHigh", surfaceContainerHigh, .neutral⟩,
    ⟨"surfaceContainerHighest", surfaceContainerHighest, .neutral⟩,
    ⟨"onSurface", onSurface, .neutral⟩,
    ⟨"surfaceVariant", surfaceVariant, .neutralVariant⟩,
    ⟨"onSurfaceVariant", onSurfaceVariant, .neutralVariant⟩,
    ⟨"inverseSurface", inverseSurface, .neutral⟩,
    ⟨"inverseOnSurface", inverseOnSurface, .neutral⟩,
    ⟨"outline", outline, .neutralVariant⟩,
    ⟨"outlineVariant", outlineVariant, .neutralVariant⟩,
    ⟨"shadow", shadow, .neutral⟩,
    ⟨"scrim", scrim, .neutral⟩,
    ⟨"surfaceTint", surfaceTint, .primary⟩,
    ⟨"inversePrimary", inversePrimary, .primary⟩,
  ],
  [
    ⟨"primaryContainer", "primary", "onPrimaryContainer", "onPrimary", primaryGroup, .primary⟩,
    ⟨"secondaryContainer", "secondary", "onSecondaryContainer", "onSecondary", secondaryGroup, .secondary⟩,
    ⟨"tertiaryContainer", "tertiary", "onTertiaryContainer", "onTertiary", tertiaryGroup, .tertiary⟩,
    ⟨"errorContainer", "error", "onErrorContainer", "onError", errorGroup, .error⟩,
    ⟨"primaryFixed", "primaryFixedDim", "onPrimaryFixed", "onPrimaryFixedVariant", primaryFixedGroup, .primary⟩,
    ⟨"secondaryFixed", "secondaryFixedDim", "onSecondaryFixed", "onSecondaryFixedVariant", secondaryFixedGroup, .secondary⟩,
    ⟨"tertiaryFixed", "tertiaryFixedDim", "onTertiaryFixed", "onTertiaryFixedVariant", tertiaryFixedGroup, .tertiary⟩
  ])
