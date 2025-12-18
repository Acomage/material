import Material.Palettes.TonalPalette
import Material.Hct.Hct
import Material.Scheme.DynamicScheme

structure ContrastCurve where
  low : Float
  normal : Float
  medium : Float
  high : Float
deriving Inhabited

inductive TonePolarity
  | darker
  | lighter
  | nearer
  | farther

inductive Palette
  | primary
  | secondary
  | tertiary
  | neutral
  | neutralVariant
  | error

abbrev ToneFn := DynamicScheme → Float

structure DynamicColor where
  name : String
  toneFn : ToneFn
  palette : Palette
