module
public import Material.Palettes.TonalPalette
public import Material.Scheme.DynamicScheme
public import Material.DynamicColor.ContrastCurve

/- abbrev ToneFn := DynamicScheme → Float -/

public section

abbrev ToneFlow (i o : Nat) := DynamicScheme → Vector Float i → Vector Float o

inductive ToneFlowExpr : Nat → Nat → Type where
  | id : ToneFlowExpr n n
  | par : (n1 n2 : Nat) → ToneFlowExpr n1 m1 → ToneFlowExpr n2 m2 → ToneFlowExpr (n1 + n2) (m1 + m2)
  | com : ToneFlowExpr n m → ToneFlowExpr m p → ToneFlowExpr n p
  | dup : (n : Nat) → ToneFlowExpr 1 n
  | src : ToneFn → ToneFlowExpr 0 1

def compile (expr : ToneFlowExpr i o) : ToneFlow i o :=
  match expr with
  | .id => fun _ v => v
  | .par n1 n2 e1 e2 =>
    let f1 := compile e1
    let f2 := compile e2
    fun s v =>
      let v1 := v.take n1
      let v2 := v.drop n1
      have h1 : min n1 (n1 + n2) = n1 := by simp
      have h2 : n1 + n2 - n1 = n2 := by simp
      let r1 := f1 s (h1 ▸ v1)
      let r2 := f2 s (h2 ▸ v2)
      r1 ++ r2
  | .com e1 e2 =>
    let f1 := compile e1
    let f2 := compile e2
    fun s v => f2 s (f1 s v)
  | .dup n =>
    fun _ v =>
      let tone := v[0]
      Vector.replicate n tone
  | .src toneFn =>
    fun s _ => #v[toneFn s]

abbrev ToneFnsExpr (n : Nat) := ToneFlowExpr 0 n

abbrev ToneFns (n : Nat) := ToneFlow 0 n
