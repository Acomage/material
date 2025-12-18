module
public import Material.Hct.Hct
public import Material.Palettes.TonalPalette
public import Material.Temperature.TemperatureCache
public import Material.Dislike.DislikeAnalyzer
public import Material.Scheme.DynamicScheme

public section

open TonalPalette DislikeAnalyzer Temperature

def schemeContent (color : Hct) (isDark : Bool) (contrastLevel : Float := 0.0) : DynamicScheme :=
  {
    sourceColorHct := color,
    variant := Variant.content,
    isDark := isDark,
    contrastLevel := contrastLevel,
    primaryPalette := fromHueAndChroma color.hue color.chroma,
    secondaryPalette := fromHueAndChroma
      color.hue (max (color.chroma - 32.0) (color.chroma / 2)) ,
    tertiaryPalette := fromHct (fixIfDisliked (getAnalogousColors color 3 6)[2]!),
    neutralPalette := fromHueAndChroma
      color.hue (color.chroma / 8.0),
    neutralVariantPalette := fromHueAndChroma
      color.hue (color.chroma / 8.0 + 4.0)
  }
