module
public import Material.Palettes.TonalPalette
public import Material.Hct.Hct
public import Material.Scheme.DynamicScheme

public section

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

abbrev ToneFnPair := DynamicScheme → Float × Float

structure DynamicColor where
  name : String
  toneFn : ToneFn
  palette : Palette

structure DynamicColorPair where
  name : String
  toneFn : ToneFnPair
  palette : Palette
