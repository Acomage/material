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
  /- onOther ⟨3.0, 3.0, 4.5, 7.0⟩ (darkLightConst 90.0 10.0) background -/
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

def primaryPair : ToneFn × ToneFn := pairConbinator 10.0 TonePolarity.nearer false (primaryContainerBase , primaryBase)

def primaryContainer : ToneFn :=
  primaryPair.1

def primary : ToneFn :=
  primaryPair.2

def onPrimary : ToneFn :=
  withContrast primary ⟨4.5, 7.0, 11.0, 21.0⟩ (monoChrome (darkLightConst 10.0 90.0) (darkLightConst 20.0 100.0))

def onPrimaryContainer : ToneFn :=
  withContrast
    primaryContainer ⟨3.0, 4.5, 7.0, 11.0⟩
    (fidelity
      (fun s => foregroundTone (primaryContainerTone s) 4.5)
      (monoChrome (darkLightConst 0.0 100.0) (darkLightConst 90.0 30.0)))

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

def secondaryPair : ToneFn × ToneFn := pairConbinator 10.0 TonePolarity.nearer false (secondaryContainerBase , secondaryBase)

def secondaryContainer : ToneFn :=
  secondaryPair.1

def secondary : ToneFn :=
  secondaryPair.2

def onSecondary : ToneFn :=
  withContrast secondary ⟨4.5, 7.0, 11.0, 21.0⟩ (monoChrome (darkLightConst 10.0 100.0) (darkLightConst 20.0 100.0))

def onSecondaryContainer : ToneFn :=
  withContrast
    secondaryContainer ⟨3.0, 4.5, 7.0, 11.0⟩
    (monoChrome
      (darkLightConst 90.0 10.0)
      (fidelity
        (fun s => foregroundTone (secondaryContainerTone s) 4.5)
     (darkLightConst 90.0 30.0)))

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

def tertiaryPair : ToneFn × ToneFn := pairConbinator 10.0 TonePolarity.nearer false (tertiaryContainerBase , tertiaryBase)

def tertiaryContainer : ToneFn :=
  tertiaryPair.1

def tertiary : ToneFn :=
  tertiaryPair.2

def onTertiary : ToneFn :=
  withContrast tertiary ⟨4.5, 7.0, 11.0, 21.0⟩ (monoChrome (darkLightConst 10.0 90.0) (darkLightConst 20.0 100.0))

def onTertiaryContainer : ToneFn :=
  withContrast
    tertiaryContainer ⟨3.0, 4.5, 7.0, 11.0⟩
    (monoChrome
      (darkLightConst 0.0 100.0)
      (fidelity
        (fun s => foregroundTone (tertiaryContainerTone s) 4.5)
        (darkLightConst 90.0 30.0)))

def errorContainerBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (darkLightConst 30.0 90.0)

def errorBase : ToneFn :=
  withContrast hightestSurface ⟨3.0, 4.5, 7.0, 7.0⟩ (darkLightConst 80.0 40.0)

def errorPair : ToneFn × ToneFn := pairConbinator 10.0 TonePolarity.nearer false (errorContainerBase , errorBase)

def errorContainer : ToneFn :=
  errorPair.1

def error : ToneFn :=
  errorPair.2

def onError : ToneFn :=
  withContrast error ⟨4.5, 7.0, 11.0, 21.0⟩ (darkLightConst 20.0 100.0)

def onErrorContainer : ToneFn :=
  withContrast errorContainer ⟨3.0, 4.5, 7.0, 11.0⟩ (monoChrome (darkLightConst 90.0 10.0) (darkLightConst 90.0 30.0))

def primaryFixedBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 40.0 90.0)

def primaryFixedDimBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 30.0 80.0)

def primaryFixedPair : ToneFn × ToneFn := pairConbinator 10.0 TonePolarity.lighter true (primaryFixedBase , primaryFixedDimBase)

def primaryFixed : ToneFn :=
  primaryFixedPair.1

def primaryFixedDim : ToneFn :=
  primaryFixedPair.2

def onPrimaryFixed : ToneFn :=
  withTwoBackgrounds primaryFixedDim primaryFixed ⟨4.5, 7.0, 11.0, 21.0⟩ (monoChromeConst 100.0 10.0)

def onPrimaryFixedVariant : ToneFn :=
  withTwoBackgrounds primaryFixedDim primaryFixed ⟨3.0, 4.5, 7.0, 11.0⟩ (monoChromeConst 90.0 30.0)

def secondaryFixedBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 80.0 90.0)

def secondaryFixedDimBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 70.0 80.0)

def secondaryFixedPair : ToneFn × ToneFn := pairConbinator 10.0 TonePolarity.lighter true (secondaryFixedBase , secondaryFixedDimBase)

def secondaryFixed : ToneFn :=
  secondaryFixedPair.1

def secondaryFixedDim : ToneFn :=
  secondaryFixedPair.2

def onSecondaryFixed : ToneFn :=
  withTwoBackgrounds secondaryFixedDim secondaryFixed ⟨4.5, 7.0, 11.0, 21.0⟩ (constantTone 10.0)

def onSecondaryFixedVariant : ToneFn :=
  withTwoBackgrounds secondaryFixedDim secondaryFixed ⟨3.0, 4.5, 7.0, 11.0⟩ (monoChromeConst 25.0 30.0)

def tertiaryFixedBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 40.0 90.0)

def tertiaryFixedDimBase : ToneFn :=
  withContrast hightestSurface ⟨1.0, 1.0, 3.0, 4.5⟩ (monoChromeConst 30.0 80.0)

def tertiaryFixedPair : ToneFn × ToneFn := pairConbinator 10.0 TonePolarity.lighter true (tertiaryFixedBase , tertiaryFixedDimBase)

def tertiaryFixed : ToneFn :=
  tertiaryFixedPair.1

def tertiaryFixedDim : ToneFn :=
  tertiaryFixedPair.2

def onTertiaryFixed : ToneFn :=
  withTwoBackgrounds tertiaryFixedDim tertiaryFixed ⟨4.5, 7.0, 11.0, 21.0⟩ (monoChromeConst 100.0 10.0)

def onTertiaryFixedVariant : ToneFn :=
  withTwoBackgrounds tertiaryFixedDim tertiaryFixed ⟨3.0, 4.5, 7.0, 11.0⟩ (monoChromeConst 90.0 30.0)

public def allMaterialDynamicColors : List DynamicColor :=
  [
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
    ⟨"primary", primary, .primary⟩,
    ⟨"onPrimary", onPrimary, .primary⟩,
    ⟨"primaryContainer", primaryContainer, .primary⟩,
    ⟨"onPrimaryContainer", onPrimaryContainer, .primary⟩,
    ⟨"inversePrimary", inversePrimary, .primary⟩,
    ⟨"secondary", secondary, .secondary⟩,
    ⟨"onSecondary", onSecondary, .secondary⟩,
    ⟨"secondaryContainer", secondaryContainer, .secondary⟩,
    ⟨"onSecondaryContainer", onSecondaryContainer, .secondary⟩,
    ⟨"tertiary", tertiary, .tertiary⟩,
    ⟨"onTertiary", onTertiary, .tertiary⟩,
    ⟨"tertiaryContainer", tertiaryContainer, .tertiary⟩,
    ⟨"onTertiaryContainer", onTertiaryContainer, .tertiary⟩,
    ⟨"error", error, .error⟩,
    ⟨"onError", onError, .error⟩,
    ⟨"errorContainer", errorContainer, .error⟩,
    ⟨"onErrorContainer", onErrorContainer, .error⟩,
    ⟨"primaryFixed", primaryFixed, .primary⟩,
    ⟨"primaryFixedDim", primaryFixedDim, .primary⟩,
    ⟨"onPrimaryFixed", onPrimaryFixed, .primary⟩,
    ⟨"onPrimaryFixedVariant", onPrimaryFixedVariant, .primary⟩,
    ⟨"secondaryFixed", secondaryFixed, .secondary⟩,
    ⟨"secondaryFixedDim", secondaryFixedDim, .secondary⟩,
    ⟨"onSecondaryFixed", onSecondaryFixed, .secondary⟩,
    ⟨"onSecondaryFixedVariant", onSecondaryFixedVariant, .secondary⟩,
    ⟨"tertiaryFixed", tertiaryFixed, .tertiary⟩,
    ⟨"tertiaryFixedDim", tertiaryFixedDim, .tertiary⟩,
    ⟨"onTertiaryFixed", onTertiaryFixed, .tertiary⟩,
    ⟨"onTertiaryFixedVariant", onTertiaryFixedVariant, .tertiary⟩
  ]
