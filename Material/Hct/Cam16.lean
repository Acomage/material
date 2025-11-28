import Material.Utils.ColorUtils
import Material.Utils.MathUtils
import Material.Hct.ViewingConditions

structure Cam16 where
  hue : Float
  chroma : Float
  j : Float
  q : Float
  m : Float
  s : Float
  jstar : Float
  astar : Float
  bstar : Float

namespace Cam16

open MathUtils ColorUtils ViewingConditions

def distance (cam1 cam2 : Cam16) : Float :=
  let dJ := cam1.jstar - cam2.jstar
  let dA := cam1.astar - cam2.astar
  let dB := cam1.bstar - cam2.bstar
  let dEprime := (dJ * dJ + dA * dA + dB * dB).sqrt
  1.41 * dEprime ^ 0.63

def xyzInViewingConditions (cam : Cam16) (viewingConditions : ViewingConditions) : Vec3 :=
  let alpha := if cam.j == 0.0
    then 0.0
    else cam.chroma / (cam.j / 100.0).sqrt
  let t := (alpha / (1.64 - 0.29 ^ viewingConditions.n) ^ 0.73) ^ (1 / 0.9)
  let hRad := toRadians cam.hue
  let eHue := 0.25 * ((hRad + 2.0).cos + 3.8)
  let ac := viewingConditions.aw * (cam.j / 100.0) ^ (1.0 / viewingConditions.c / viewingConditions.z)
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
  rgbF * CAM16RGB_TO_XYZ

def viewed (cam : Cam16) (viewingConditions : ViewingConditions) : Int32 :=
  let xyz := xyzInViewingConditions cam viewingConditions
  argbFromXyz xyz[0] xyz[1] xyz[2]

def toInt (cam : Cam16) : Int32 :=
  cam.viewed DEFAULT

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
  let hueRadians := toRadians hue
  let ac := p2 * viewingConditions.nbb
  let j := 100.0 * (ac / viewingConditions.aw) ^ (viewingConditions.c * viewingConditions.z)
  let q := 4.0 / viewingConditions.c * (j / 100.0).sqrt * (viewingConditions.aw + 4.0) * viewingConditions.flRoot
  let huePrime := if hue < 20.14 then hue + 360.0 else hue
  let eHue := 0.25 * ((toRadians huePrime + 2.0).cos + 3.8)
  let p1 := 50000.0 / 13.0 * eHue * viewingConditions.nc * viewingConditions.ncb
  let t := p1 * (hypot a b) / (u + 0.305)
  let alpha := (1.64 - 0.29 ^ viewingConditions.n) ^ 0.73 * t ^ 0.9
  let c := alpha * (j / 100.0).sqrt
  let m := c * viewingConditions.flRoot
  let s := 50.0 * (alpha * viewingConditions.c / (viewingConditions.aw + 4.0)).sqrt
  let jstar := (1.0 + 100.0 * 0.007) * j / (1.0 + 0.007 * j)
  let mstar := 1.0 / 0.0228 * (1 + 0.0228 * m).log
  let astar := mstar * hueRadians.cos
  let bstar := mstar * hueRadians.sin
  ⟨hue, c, j, q, m, s, jstar, astar, bstar⟩

def fromIntInViewingConditions (argb : Int32) (viewingConditions : ViewingConditions) : Cam16 :=
  let xyz := xyzFromArgb argb
  fromXyzInViewingConditions xyz[0] xyz[1] xyz[2] viewingConditions

def fromInt (argb : Int32) : Cam16 :=
  fromIntInViewingConditions argb DEFAULT

def fromJchInViewingConditions (j c h : Float) (viewingConditions : ViewingConditions) : Cam16 :=
  let q := 4.0 / viewingConditions.c * (j / 100.0).sqrt * (viewingConditions.aw + 4.0) * viewingConditions.flRoot
  let m := c * viewingConditions.flRoot
  let alpha := c / (j / 100.0).sqrt
  let s := 50.0 * (alpha * viewingConditions.c / (viewingConditions.aw + 4.0)).sqrt
  let hueRadians := toRadians h
  let jstar := (1.0 + 100.0 * 0.007) * j / (1.0 + 0.007 * j)
  let mstar := 1.0 / 0.0228 * (1 + 0.0228 * m).log
  let astar := mstar * hueRadians.cos
  let bstar := mstar * hueRadians.sin
  ⟨h, c, j, q, m, s, jstar, astar, bstar⟩

def fromJch (j c h : Float) : Cam16 :=
  fromJchInViewingConditions j c h DEFAULT

def fromUcsInViewingConditions (jstar astar bstar : Float) (viewingConditions : ViewingConditions) : Cam16 :=
  let m := hypot astar bstar
  let m2 := ((m * 0.0228).exp - 1.0) / 0.0228
  let c := m2 / viewingConditions.flRoot
  let h := toDegrees (bstar.atan2 astar)
  let h := if h < 0.0 then h + 360.0 else h
  let j := jstar / (1.0 - (jstar - 100.0) * 0.007)
  fromJchInViewingConditions j c h viewingConditions

def fromUcs(jstar astar bstar : Float) : Cam16 :=
  fromUcsInViewingConditions jstar astar bstar DEFAULT

end Cam16
