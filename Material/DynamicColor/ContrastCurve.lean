import Material.DynamicColor.Types

open MathUtils

namespace ContrastCurve

def get(cs : ContrastCurve) (contrast_level : Float) : Float :=
  if contrast_level <= -1.0 then
    cs.low
  else if contrast_level < 0.0 then
    lerp cs.normal cs.low (contrast_level + 1.0)
  else if contrast_level < 0.5 then
    lerp cs.normal cs.medium (contrast_level * 2)
  else if contrast_level < 1.0 then
    lerp cs.medium cs.high (contrast_level * 2 - 1.0)
  else
    cs.high

end ContrastCurve
