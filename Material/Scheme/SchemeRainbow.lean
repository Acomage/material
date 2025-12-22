module
public import Material.Hct.Hct
public import Material.Palettes.TonalPalette
public import Material.Utils.MathUtils
public import Material.Scheme.DynamicScheme


open TonalPalette MathUtils

public def schemeRainbow (color : Hct) (isDark : Bool) (contrastLevel : Float := 0.0) : DynamicScheme :=
  {
    sourceColorHct := color,
    variant := Variant.rainbow,
    isDark := isDark,
    contrastLevel := contrastLevel,
    primaryPalette := fromHueAndChroma color.hue 48.0,
    secondaryPalette := fromHueAndChroma color.hue 16.0,
    tertiaryPalette := fromHueAndChroma
      (sanitizeDegreesDouble (color.hue + 60.0)) 24.0,
    neutralPalette := fromHueAndChroma color.hue 0.0,
    neutralVariantPalette := fromHueAndChroma color.hue 0.0
  }
