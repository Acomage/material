module
public import Material.Utils.MathUtils
public import Material.Utils.ColorUtils
public import Material.Hct.ViewingConditions

open MathUtils ColorUtils ViewingConditions

public structure Cam16ucs where
  jstar : Float
  astar : Float
  bstar : Float

namespace Cam16ucs

def CAM16RGB_TO_XYZ := #v[
  #v[1.8620678,  -1.0112547,  0.14918678 ],
  #v[0.38752654, 0.62144744,  -0.00897398],
  #v[-0.0158415, -0.03412294, 1.0499644  ]
]

def XYZ_TO_CAM16RGB := #v[
  #v[0.401288,  0.650173, -0.051461],
  #v[-0.250268, 1.204414, 0.045854 ],
  #v[-0.002079, 0.048952, 0.953127 ]
]

def fromXyzInViewingConditions (x y z : Float) (viewingConditions : ViewingConditions) : Cam16ucs :=
  let rgbT := #v[x, y, z] * XYZ_TO_CAM16RGB
  let rgbD := viewingConditions.rgbD * rgbT
  let rgbAf := rgbD.map (fun cD => (viewingConditions.fl * cD.abs / 100.0) ^ 0.42)
  let rgbA := rgbAf.zipWith (fun cAF cD =>
  signum cD * 400.0 * cAF / (cAF + 27.13)
  ) rgbD
  let a := (#v[11.0, -12.0, 1.0] * rgbA).sum / 11.0
  let b := (#v[1.0, 1.0, -2.0] * rgbA).sum / 9.0
  let u := (#v[20.0, 20.0, 21.0] * rgbA).sum / 20.0
  let p2 := (#v[40.0, 20.0, 1.0] * rgbA).sum / 20.0
  let hue := sanitizeDegreesDouble (toDegrees (b.atan2 a))
  let hueRadians := toRadians hue
  let ac := p2 * viewingConditions.nbb
  let j := 100.0 * (ac / viewingConditions.aw) ^ (viewingConditions.c * viewingConditions.z)
  let huePrime := if hue < 20.14 then hue + 360.0 else hue
  let eHue := 0.25 * ((toRadians huePrime + 2.0).cos + 3.8)
  let p1 := 50000.0 / 13.0 * eHue * viewingConditions.nc * viewingConditions.ncb
  let t := p1 * (hypot a b) / (u + 0.305)
  let alpha := (1.64 - 0.29 ^ viewingConditions.n) ^ 0.73 * t ^ 0.9
  let c := alpha * (j / 100.0).sqrt
  let m := c * viewingConditions.flRoot
  let jstar := (1.0 + 100.0 * 0.007) * j / (1.0 + 0.007 * j)
  let mstar := 1.0 / 0.0228 * (1 + 0.0228 * m).log
  let astar := mstar * hueRadians.cos
  let bstar := mstar * hueRadians.sin
  ⟨jstar, astar, bstar⟩

def fromIntInViewingConditions (argb : UInt32) (viewingConditions : ViewingConditions) : Cam16ucs :=
  let xyz := xyzFromArgb argb
  fromXyzInViewingConditions xyz[0] xyz[1] xyz[2] viewingConditions

public def fromInt (argb : UInt32) : Cam16ucs :=
  fromIntInViewingConditions argb DEFAULT

public def fromUcs(jstar astar bstar : Float) : Cam16ucs :=
  ⟨jstar, astar, bstar⟩

public def toInt (cam : Cam16ucs) : UInt32 :=
  let jstar := cam.jstar
  let astar := cam.astar
  let bstar := cam.bstar
  let viewingConditions := DEFAULT
  let m := hypot astar bstar
  let m2 := ((m * 0.0228).exp - 1.0) / 0.0228
  let c := m2 / viewingConditions.flRoot
  let h := toDegrees (bstar.atan2 astar)
  let h := if h < 0.0 then h + 360.0 else h
  let j := jstar / (1.0 - (jstar - 100.0) * 0.007)
  let alpha := if j == 0.0
    then 0.0
    else c / (j / 100.0).sqrt
  let t := (alpha / (1.64 - 0.29 ^ viewingConditions.n) ^ 0.73) ^ (1 / 0.9)
  let hRad := toRadians h
  let eHue := 0.25 * ((hRad + 2.0).cos + 3.8)
  let ac := viewingConditions.aw * (j / 100.0) ^ (1.0 / viewingConditions.c / viewingConditions.z)
  let p1 := eHue * (50000.0 / 13.0) * viewingConditions.nc * viewingConditions.ncb
  let p2 := ac / viewingConditions.nbb
  let hSin := hRad.sin
  let hCos := hRad.cos
  let gamma := 23.0 * (p2 + 0.305) * t / (23.0 * p1 + 11.0 * t * hCos + 108.0 * t * hSin)
  let a := gamma * hCos
  let b := gamma * hSin
  let matrix := #v[
    #v[460.0 / 1403.0, 451.0 / 1403.0,  288.0 / 1403.0  ],
    #v[460.0 / 1403.0, -891.0 / 1403.0, -261.0 / 1403.0 ],
    #v[460.0 / 1403.0, -220.0 / 1403.0, -6300.0 / 1403.0]
  ]
  let rgbA := #v[p2, a, b] * matrix
  let rgbC := rgbA.map (fun cA =>
    let cCBase := max 0.0 (27.13 * cA.abs / (400.0 - cA.abs))
    signum cA * (100.0 / viewingConditions.fl) * cCBase ^ (1 / 0.42)
  )
  let rgbF := rgbC.zipWith (· / ·) viewingConditions.rgbD
  let xyz := rgbF * CAM16RGB_TO_XYZ
  argbFromXyz xyz[0] xyz[1] xyz[2]

end Cam16ucs
