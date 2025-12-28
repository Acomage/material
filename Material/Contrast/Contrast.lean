module
public import Material.Utils.ColorUtils

open ColorUtils

def CONTRAST_RATIO_EPSILON := 0.04

def LUMINANCE_GAMUT_MAP_TOLERANCE := 0.4

namespace Contrast

def ratioOfYs (y1 y2 : Float) : Float :=
  let lighter := max y1 y2
  let darker := min y1 y2
  (lighter + 5.0) / (darker + 5.0)

public def rationOfTones (t1 t2 : Float) : Float :=
  ratioOfYs (yFromLstar t1) (yFromLstar t2)

public def lighter (tone ratio : Float) : Option Float := do
  guard (0.0 ≤ tone ∧ tone ≤ 100.0)
  let darkY := yFromLstar tone
  let lightY := ratio * (darkY + 5.0) - 5.0
  guard (0.0 ≤ lightY ∧ lightY ≤ 100.0)
  let realContrast := ratioOfYs lightY darkY
  let delta := (realContrast - ratio).abs
  guard (realContrast ≥ ratio ∨ delta ≤ CONTRAST_RATIO_EPSILON)
  let returnValue := lstarFromY lightY + LUMINANCE_GAMUT_MAP_TOLERANCE
  guard (0.0 ≤ returnValue ∧ returnValue ≤ 100.0)
  return returnValue

public def lighterUnsafe (tone ratio : Float) : Float :=
  (lighter tone ratio).getD 100.0

public def darker (tone ratio : Float) : Option Float := do
  guard (0.0 <= tone ∧ tone <= 100.0)
  let lightY := yFromLstar tone
  let darkY := (lightY + 5.0) / ratio - 5.0
  guard (0.0 <= darkY ∧ darkY <= 100.0)
  let realContrast := ratioOfYs lightY darkY
  let delta := (realContrast - ratio).abs
  guard (realContrast >= ratio ∨ delta <= CONTRAST_RATIO_EPSILON)
  let returnValue := (lstarFromY darkY) - LUMINANCE_GAMUT_MAP_TOLERANCE
  guard (0.0 <= returnValue ∧ returnValue <= 100.0)
  return returnValue

public def darkerUnsafe (tone ratio : Float) : Float :=
  (darker tone ratio).getD 0.0

end Contrast
