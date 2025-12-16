import Material.DynamicColor.Types
import Material.Hct.Hct
import Material.Palettes.TonalPalette
import Material.Utils.MathUtils

open TonalPalette MathUtils

def schemeTonalSpot (color : Hct) (isDark : Bool) (contrastLevel : Float := 0.0) : DynamicScheme :=
  {
    sourceColorHct := color,
    variant := Variant.tonalSpot,
    isDark := isDark,
    contrastLevel := contrastLevel,
    primaryPalette := fromHueAndChroma color.hue 36.0,
    secondaryPalette := fromHueAndChroma color.hue 16.0,
    tertiaryPalette := fromHueAndChroma
      (sanitizeDegreesDouble (color.hue + 60.0)) 24.0,
    neutralPalette := fromHueAndChroma color.hue 6.0,
    neutralVariantPalette := fromHueAndChroma color.hue 8.0
  }
