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

abbrev ToneFnPair := DynamicScheme → Vector Float 2

abbrev ToneFnGroup := DynamicScheme → Vector Float 4

structure DynamicColor where
  name : String
  toneFn : ToneFn
  palette : Palette

structure DynamicColorGroup where
  nameA : String
  nameB : String
  nameC : String
  nameD : String
  toneFnGroup : ToneFnGroup
  palette : Palette
