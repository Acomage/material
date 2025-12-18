module
public import Material.Hct.Hct
public import Material.Palettes.TonalPalette
public import Material.Scheme.DynamicScheme

public section

open TonalPalette

def schemeMomoChroma (color : Hct) (isDark : Bool) (contrastLevel : Float := 0.0) : DynamicScheme :=
  {
    sourceColorHct := color,
    variant := Variant.monoChrome,
    isDark := isDark,
    contrastLevel := contrastLevel,
    primaryPalette := fromHueAndChroma color.hue 0.0,
    secondaryPalette := fromHueAndChroma color.hue 0.0,
    tertiaryPalette := fromHueAndChroma color.hue 0.0,
    neutralPalette := fromHueAndChroma color.hue 0.0,
    neutralVariantPalette := fromHueAndChroma color.hue 0.0
  }
