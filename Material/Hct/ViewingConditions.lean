import Material.Utils.ColorUtils
import Material.Utils.MathUtils

structure ViewingConditions where
  n : Float
  aw : Float
  nbb : Float
  ncb : Float
  c : Float
  nc : Float
  rgbD : MathUtils.Vec3
  fl : Float
  flRoot : Float
  z : Float

namespace Cam16

def XYZ_TO_CAM16RGB := #v[
  #v[0.401288,  0.650173, -0.051461],
  #v[-0.250268, 1.204414, 0.045854 ],
  #v[-0.002079, 0.048952, 0.953127 ]
]

def CAM16RGB_TO_XYZ := #v[
  #v[1.8620678,  -1.0112547,  0.14918678 ],
  #v[0.38752654, 0.62144744,  -0.00897398],
  #v[-0.0158415, -0.03412294, 1.0499644  ]
]

end Cam16

namespace ViewingConditions

open MathUtils ColorUtils Cam16

def make (whitePoint : Vec3 := WHITE_POINT_D65)
  (adaptingLuminance : Float := 200.0 / Pi * yFromLstar 50.0 /100)
  (backgroundLstar : Float := 50.0)
  (surround : Float := 2.0)
  (discountingIlluminant : Bool := false) : ViewingConditions :=
  let backgroundLstar := max 0.1 backgroundLstar
  let rgbW := whitePoint * XYZ_TO_CAM16RGB
  let f := 0.8 + surround / 10.0
  let c := if f >= 0.9
    then lerp 0.59 0.69 ((f - 0.9) * 10.0)
    else lerp 0.525 0.59 ((f - 0.8) * 10.0)
  let d := if discountingIlluminant
    then 1.0
    else clampDouble 0.0 1.0 (f * (1.0 - (1.0 / 3.6) * ((-adaptingLuminance - 42.0) / 92.0).exp))
  let rgbD := rgbW.map (fun x => d * (100.0 / x) + 1.0 - d)
  let k4 := (1.0 / (5.0 * adaptingLuminance + 1.0)) ^ 4
  let k4F := 1.0 - k4
  let fl := k4 * adaptingLuminance + 0.1 * k4F ^ 2 * (5.0 * adaptingLuminance).cbrt
  let n := yFromLstar backgroundLstar / whitePoint[1]
  let z := 1.48 + n.sqrt
  let nbb := 0.725 / n ^ 0.2
  let rgbAFactors := (rgbD * rgbW).map (fun x => (fl * x / 100.0).pow (0.42))
  let rgbA := rgbAFactors.map (fun x => 400.0 * x / (x + 27.13))
  let aw := (#v[2.0, 1.0, 0.05] * rgbA).sum * nbb
  ⟨n, aw, nbb, nbb, c, f, rgbD, fl, fl ^ 0.25, z⟩

def DEFAULT : ViewingConditions := make

end ViewingConditions
