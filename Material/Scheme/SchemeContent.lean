import Material.DynamicColor.Types
import Material.Hct.Hct
import Material.Palettes.TonalPalette
import Material.Temperature.TemperatureCache
import Material.Dislike.DislikeAnalyzer

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
