import Material.Hct.Hct
import Material.Palettes.TonalPalette
import Material.Temperature.TemperatureCache
import Material.Dislike.DislikeAnalyzer
import Material.Scheme.DynamicScheme

open TonalPalette DislikeAnalyzer Temperature

def schemeFidelity (color : Hct) (isDark : Bool) (contrastLevel : Float := 0.0) : DynamicScheme :=
  {
    sourceColorHct := color,
    variant := Variant.fidelity,
    isDark := isDark,
    contrastLevel := contrastLevel,
    primaryPalette := fromHueAndChroma color.hue color.chroma,
    secondaryPalette := fromHueAndChroma
      color.hue (max (color.chroma - 32.0) (color.chroma / 2)) ,
    tertiaryPalette := fromHct (fixIfDisliked (getComplement color)),
    neutralPalette := fromHueAndChroma
      color.hue (color.chroma / 8.0),
    neutralVariantPalette := fromHueAndChroma
      color.hue (color.chroma / 8.0 + 4.0)
  }
