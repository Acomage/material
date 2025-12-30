module
public import Material.Palettes.TonalPalette
public import Material.Scheme.DynamicScheme
public import Material.DynamicColor.ContrastCurve

/- abbrev ToneFn := DynamicScheme → Float -/

abbrev ToneFns (n : Nat) := DynamicScheme → Vector Float n

inductive ToneFnsExpr : Nat → Type where
  | fn : ToneFn → ToneFnsExpr 1
  | tensor : ToneFnsExpr n → ToneFnsExpr m → ToneFnsExpr (n + m)
  | mux : ToneFnsExpr 1 → (m : Nat) → ToneFnsExpr m
  | curve : ToneFnsExpr 2 → ContrastCurve → ToneFnsExpr 1
  | pair : Float → TonePolarity → Bool → ToneFnsExpr 2 → ToneFnsExpr 2

def compile (expr : ToneFnsExpr n) : ToneFns n := sorry
