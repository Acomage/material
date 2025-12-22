module
public import Material.Hct.Hct
public import Material.Palettes.TonalPalette
public import Material.Utils.MathUtils
public import Material.Scheme.DynamicScheme


open TonalPalette MathUtils

public def schemeFruitSalad (color : Hct) (isDark : Bool) (contrastLevel : Float := 0.0) : DynamicScheme :=
  {
    sourceColorHct := color,
    variant := Variant.fruitSalad,
    isDark := isDark,
    contrastLevel := contrastLevel,
    primaryPalette := fromHueAndChroma
      (sanitizeDegreesDouble (color.hue - 50.0)) 48.0,
    secondaryPalette := fromHueAndChroma
      (sanitizeDegreesDouble (color.hue - 50.0)) 36.0,
    tertiaryPalette := fromHueAndChroma color.hue 36.0,
    neutralPalette := fromHueAndChroma color.hue 10.0,
    neutralVariantPalette := fromHueAndChroma color.hue 16.0
  }
