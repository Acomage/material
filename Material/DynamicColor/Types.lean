import Material.Palettes.TonalPalette

structure ContrastCurve where
  low : Float
  normal : Float
  medium : Float
  high : Float
deriving Inhabited

inductive Variant
  | monoChrome
  | neutral
  | tonalSpot
  | vibrant
  | expressive
  | fidelity
  | content
  | rainbow
  | fruitSalad

structure DynamicScheme where
  sourceColorHct : Hct
  variant : Variant
  isDark : Bool
  contrastLevel : Float
  primaryPalette : TonalPalette
  secondaryPalette : TonalPalette
  tertiaryPalette : TonalPalette
  neutralPalette : TonalPalette
  neutralVariantPalette : TonalPalette
  errorPalette : TonalPalette := TonalPalette.fromHueAndChroma 25.0 84.0

inductive TonePolarity
  | darker
  | lighter
  | nearer
  | farther

mutual
  structure ToneDeltaPair where
    role_a : DynamicColor
    role_b : DynamicColor
    delta : Float
    polarity : TonePolarity
    stay_together : Bool

  structure DynamicColor where
    name : String
    palette : DynamicScheme → TonalPalette
    tone : DynamicScheme → Float
    isBackground : Bool
    background : Option (DynamicScheme → DynamicColor)
    second_background : Option (DynamicScheme → DynamicColor)
    contrast_curve : Option ContrastCurve
    tone_delta_pair : Option (DynamicScheme → ToneDeltaPair)
end

instance : Inhabited DynamicColor where
  default := {
    name := ""
    palette := fun _ => Inhabited.default
    tone := fun _ => 50.0
    isBackground := false
    background := none
    second_background := none
    contrast_curve := none
    tone_delta_pair := none
  }
