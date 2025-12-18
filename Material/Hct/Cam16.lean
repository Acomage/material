module
public import Material.Utils.ColorUtils
public import Material.Utils.MathUtils
public import Material.Hct.ViewingConditions

open MathUtils ColorUtils ViewingConditions

public structure Cam16 where
  hue : Float
  chroma : Float

namespace Cam16

def XYZ_TO_CAM16RGB := #v[
  #v[0.401288,  0.650173, -0.051461],
  #v[-0.250268, 1.204414, 0.045854 ],
  #v[-0.002079, 0.048952, 0.953127 ]
]

def fromXyzInViewingConditions (x y z : Float) (viewingConditions : ViewingConditions) : Cam16 :=
  let rgbT := #v[x, y, z] * XYZ_TO_CAM16RGB
  let rgbD := viewingConditions.rgbD * rgbT
  let rgbAf := rgbD.map (fun cD => (viewingConditions.fl * cD.abs / 100.0) ^ 0.42)
  let rgbA := rgbAf.map (fun cAF =>
    signum cAF * 400.0 * cAF / (cAF + 27.13)
  )
  let a := (#v[11.0, -12.0, 1.0] * rgbA).sum / 11.0
  let b := (#v[1.0, 1.0, -2.0] * rgbA).sum / 9.0
  let u := (#v[20.0, 20.0, 21.0] * rgbA).sum / 20.0
  let p2 := (#v[40.0, 20.0, 1.0] * rgbA).sum / 20.0
  let hue := sanitizeDegreesDouble (toDegrees (b.atan2 a))
  let ac := p2 * viewingConditions.nbb
  let j := 100.0 * (ac / viewingConditions.aw) ^ (viewingConditions.c * viewingConditions.z)
  let huePrime := if hue < 20.14 then hue + 360.0 else hue
  let eHue := 0.25 * ((toRadians huePrime + 2.0).cos + 3.8)
  let p1 := 50000.0 / 13.0 * eHue * viewingConditions.nc * viewingConditions.ncb
  let t := p1 * (hypot a b) / (u + 0.305)
  let alpha := (1.64 - 0.29 ^ viewingConditions.n) ^ 0.73 * t ^ 0.9
  let c := alpha * (j / 100.0).sqrt
  ⟨hue, c⟩

def fromIntInViewingConditions (argb : UInt32) (viewingConditions : ViewingConditions) : Cam16 :=
  let xyz := xyzFromArgb argb
  fromXyzInViewingConditions xyz[0] xyz[1] xyz[2] viewingConditions

public def fromInt (argb : UInt32) : Cam16 :=
  fromIntInViewingConditions argb DEFAULT

end Cam16
