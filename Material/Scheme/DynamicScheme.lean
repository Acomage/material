import Material.Palettes.TonalPalette

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
