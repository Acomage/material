module
public import Material.Hct.Hct
public import Material.Palettes.TonalPalette
public import Material.Scheme.DynamicScheme
public import Material.DynamicColor.DynamicScheme


def hues : Vector Float 9 := #v[0, 41, 61, 101, 131, 181, 251, 301, 360]
def secondaryRotations : Vector Float 9 := #v[18, 15, 10, 12, 15, 18, 15, 12, 12]
def tertiaryRotations : Vector Float 9 := #v[35, 30, 20, 25, 30, 35, 30, 25, 25]


open TonalPalette DynamicScheme

public def schemeVibrant (color : Hct) (isDark : Bool) (contrastLevel : Float := 0.0) : DynamicScheme :=
  {
    sourceColorHct := color,
    variant := Variant.vibrant,
    isDark := isDark,
    contrastLevel := contrastLevel,
    primaryPalette := fromHueAndChroma color.hue 200.0,
    secondaryPalette := fromHueAndChroma
       (getRotatedHue color hues secondaryRotations) 24.0,
    tertiaryPalette := fromHueAndChroma
       (getRotatedHue color hues tertiaryRotations) 32.0,
    neutralPalette := fromHueAndChroma color.hue 10.0,
    neutralVariantPalette := fromHueAndChroma color.hue 12.0
  }
