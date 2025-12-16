import Material.DynamicColor.Types
import Material.Hct.Hct
import Material.Palettes.TonalPalette
import Material.DynamicColor.DynamicScheme

def hues : Array Float := #[0, 21, 51, 121, 151, 191, 271, 321, 360]
def secondaryRotations : Array Float := #[45, 95, 45, 20, 45, 90, 45, 45, 45]
def tertiaryRotations : Array Float := #[120, 120, 20, 45, 20, 15, 20, 120, 120]


open TonalPalette DynamicScheme

def schemeExpressive (color : Hct) (isDark : Bool) (contrastLevel : Float := 0.0) : DynamicScheme :=
  {
    sourceColorHct := color,
    variant := Variant.expressive,
    isDark := isDark,
    contrastLevel := contrastLevel,
    primaryPalette := fromHueAndChroma (color.hue + 240) 40.0,
    secondaryPalette := fromHueAndChroma
       (getRotatedHue color hues secondaryRotations) 24.0,
    tertiaryPalette := fromHueAndChroma
       (getRotatedHue color hues tertiaryRotations) 32.0,
    neutralPalette := fromHueAndChroma (color.hue + 15.0) 8.0,
    neutralVariantPalette := fromHueAndChroma (color.hue + 15.0) 12.0
  }
