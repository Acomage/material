module
public import Material.Utils.ColorUtils
public import Material.Utils.MathUtils
public import Material.Hct.ViewingConditions
public import Material.Hct.Cam16

public section

open MathUtils ColorUtils ViewingConditions

def SCALED_DISCOUNT_FROM_LINRGB := #v[
  #v[0.001200833568784504,   0.002389694492170889,  0.0002795742885861124],
  #v[0.0005891086651375999,  0.0029785502573438758, 0.0003270666104008398],
  #v[0.00010146692491640572, 0.0005364214359186694, 0.0032979401770712076]
]
def LINRGB_FROM_SCALED_DISCOUNT := #v[
  #v[1373.2198709594231, -1100.4251190754821, -7.278681089101213],
  #v[-271.815969077903,  559.6580465940733,   -32.46047482791194],
  #v[1.9622899599665666, -57.173814538844006, 308.7233197812385 ]
]

def Y_FROM_LINRGB := #v[0.2126, 0.7152, 0.0722]

def CRITICAL_PLANES := (Vector.range 255).map (fun x => linearized (x.toFloat + 0.5))

def chromaticAdaptation (component : Float) : Float :=
  let af := component.abs ^ 0.42
  signum component * 400.0 * af / (af + 27.13)

def hueOf (linrgb : Vec3) : Float :=
  let rgbA := (linrgb * SCALED_DISCOUNT_FROM_LINRGB).map chromaticAdaptation
  let a := (#v[11.0, -12.0, 1.0] * rgbA).sum / 11.0
  let b := (#v[1.0, 1.0, -2.0] * rgbA).sum / 9.0
  b.atan2 a

def areInCycleOrder (a b c : Float) : Bool :=
  let deltaAB := sanitizeRadians (b - a)
  let deltaAC := sanitizeRadians (c - a)
  deltaAB < deltaAC

def intercept (source mid target : Float) : Float :=
  (mid - source) / (target - source)

def lerpPoint (source : Vec3) (t : Float) (target : Vec3) : Vec3 :=
  source.zipWith (fun so ta => so + (ta - so) * t) target

def setCoordinate (source : Vec3) (coordinate : Float) (target : Vec3) (axis : Fin 3) : Vec3 :=
  let t := intercept (source[axis]) coordinate (target[axis])
  lerpPoint source t target

def isBounded (x : Float) : Bool :=
  0.0 <= x && x <= 100.0

/--
  as we all know that a valid y should be in [0, 100]
  notice that:
    when n = 0,
      if r is bounded, then we have a valid result.
      but at that time, g = 0, b = 0
      so r = y/kR
    when n = 5
      if g is bounded, then we have a valid result.
      but at that time, r = 100, b = 0
      so g = (y - 100kR)/kG
    when n = 11
      if b is bounded, then we have a valid result.
      but at that time, r = 100, g = 100
      so b = (y - 100kR - 100kG)/kB
    if when n = 0, r is unbounded, because y/KR is never less then 0,
    y/kR must be greater than 100, which means y > 100*kR,
    so that (y - 100kR)/kG is always greater than 0
    if when n = 11, b is unbounded, because (y - 100kR - 100kG)/kB is never greater than 100,
    (y - 100kR - 100kG)/kB must be less than 0, which means y < 100kR + 100kG
    so that (y - 100kR)/kG is always less than 100
    summarizing the above analysis, when y is in [0, 100],
    one of n = 0, 5, 11 will give a valid vertex.
-/
def nthVertex (y : Float) (n : Fin 12) : Option Vec3 :=
  let kR := Y_FROM_LINRGB[0]
  let kG := Y_FROM_LINRGB[1]
  let kB := Y_FROM_LINRGB[2]
  let coordA := if (n % 4 <= 1) then 0.0 else 100.0
  let coordB := if (n % 2 == 0) then 0.0 else 100.0
  if n < 4 then
    let g := coordA
    let b := coordB
    let r := (y - g * kG - b * kB) / kR
    if isBounded r then
      some #v[r, g, b]
    else
      none
  else if n < 8 then
    let b := coordA
    let r := coordB
    let g := (y - r * kR - b * kB) / kG
    if isBounded g then
      some #v[r, g, b]
    else
      none
  else
    let r := coordA
    let g := coordB
    let b := (y - r * kR - g * kG) / kB
    if isBounded b then
      some #v[r, g, b]
    else
      none

-- we need the refined type for then range of colorspace so that we can prove something about that
-- TODO: add refined type for colorspace

-- TODO: prove the safety of get!
/--
  notice that when y is in [0, 100], at least one vertex is valid.
  that means in the loop, left and right will always be assigned to a non-none value.
  So the final get! is safe.
-/
def bisectToSegment (y targetHue : Float) : Vector Vec3 2 := runST fun s => do
    let leftRef : (ST.Ref s (Option Vec3)) ← ST.mkRef none
    let rightRef : (ST.Ref s (Option Vec3)) ← ST.mkRef none
    let leftHueRef : (ST.Ref s Float) ← ST.mkRef 0.0
    let rightHueRef : (ST.Ref s Float) ← ST.mkRef 0.0
    let initializedRef : (ST.Ref s Bool) ← ST.mkRef false
    let uncutRef : (ST.Ref s Bool) ← ST.mkRef true
    for n in Array.finRange 12 do
      match nthVertex y n with
      | none => continue
      | some mid =>
        let midHue := hueOf mid
        let initialized ← initializedRef.get
        if !initialized then
          leftRef.set (some mid)
          rightRef.set (some mid)
          leftHueRef.set midHue
          rightHueRef.set midHue
          initializedRef.set true
        else
          let uncut ← uncutRef.get
          let leftHue ← leftHueRef.get
          let rightHue ← rightHueRef.get
          if uncut || areInCycleOrder leftHue midHue rightHue then
            uncutRef.set false
            if areInCycleOrder leftHue targetHue midHue then
              rightRef.set (some mid)
              rightHueRef.set midHue
            else
              leftRef.set (some mid)
              leftHueRef.set midHue
          else continue
    let left ← leftRef.get
    let right ← rightRef.get
    return #v[left.get!, right.get!]

def midpoint (a b : Vec3) : Vec3 :=
  lerpPoint a 0.5 b

def criticalPlaneBelow (x : Float) : Int32 :=
  (x - 0.5).floor.toInt32

def criticalPlaneAbove (x : Float) : Int32 :=
  (x - 0.5).ceil.toInt32

def clampToFin255 (n : Int32) : Fin 255 :=
  let m := n.toNatClampNeg
  if h : m > 254 then
    Fin.mk 254 (by decide)
  else
    Fin.mk m (by grind)

def bisectToLimit (y targetHue : Float) : Vec3 := runST fun s => do
    let segment := bisectToSegment y targetHue
    let leftRef : (ST.Ref s Vec3) ← ST.mkRef segment[0]
    let leftHueRef : (ST.Ref s Float) ← ST.mkRef (hueOf segment[0])
    let rightRef : (ST.Ref s Vec3) ← ST.mkRef segment[1]
    for axis in Array.finRange 3 do
      let left ← leftRef.get
      let right ← rightRef.get
      if left[axis] == right[axis] then
        continue
      else
        let lPlaneRef : (ST.Ref s Int32) ← ST.mkRef (if left[axis] < right[axis]
          then criticalPlaneBelow (trueDelinearized left[axis])
          else criticalPlaneAbove (trueDelinearized left[axis]))
        let rPlaneRef : (ST.Ref s Int32) ← ST.mkRef (if left[axis] < right[axis]
          then criticalPlaneAbove (trueDelinearized right[axis])
          else criticalPlaneBelow (trueDelinearized right[axis]))
        for i in Array.finRange 8 do
          let rPlane ← rPlaneRef.get
          let lPlane ← lPlaneRef.get
          if (rPlane - lPlane).abs <= 1 then
            break
          else
            let mPlane := (lPlane + rPlane) / 2
            -- maybe we can prove that mPlane is always in [0, 255], but not now
            -- so we just clamp it
            let mPlane' := clampToFin255 mPlane
            let midPlaneCoordinate := CRITICAL_PLANES[mPlane']
            let mid := setCoordinate left midPlaneCoordinate right axis
            let midHue := hueOf mid
            if areInCycleOrder (←leftHueRef.get) targetHue midHue then
              rightRef.set mid
              rPlaneRef.set mPlane
            else
              leftRef.set mid
              leftHueRef.set midHue
              lPlaneRef.set mPlane
    return midpoint (←leftRef.get) (←rightRef.get)

def inverseChromaticAdaptation (adapted : Float) : Float :=
  let adaptedAbs := adapted.abs
  let base := max 0.0 (adaptedAbs * 27.13 / (400.0 - adaptedAbs))
  signum adapted * base ^ (1.0 / 0.42)

def findResultByJ (hueRadians chroma y : Float) : UInt32 := runST fun s => do
  let jRef : (ST.Ref s Float) ← ST.mkRef (y.sqrt * 11.0)
  let viewingConditions := DEFAULT
  let tInnerCoeff := 1 / (1.64 - 0.29 ^ (viewingConditions.n)) ^ 0.73
  let eHue := 0.25 * ((hueRadians + 2.0).cos + 3.8)
  let p1 := eHue * (50000.0 / 13.0) * viewingConditions.nc * viewingConditions.ncb
  let hSin := hueRadians.sin
  let hCos := hueRadians.cos
  for iterationRound in Array.finRange 5 do
    let j ← jRef.get
    let jNormalized := j / 100.0
    let alpha := if (chroma == 0.0 || j == 0.0)
      then 0.0
      else chroma / (jNormalized.sqrt)
    let t := (alpha * tInnerCoeff).pow (1.0 / 0.9)
    let ac := viewingConditions.aw * jNormalized ^ (1.0 / viewingConditions.c / viewingConditions.z)
    let p2 := ac / viewingConditions.nbb
    let gamma := 23.0 * (p2 + 0.305) * t / (23.0 * p1 + 11.0 * t * hCos + 108.0 * t * hSin)
    let a := gamma * hCos
    let b := gamma * hSin
    let matrix := #v[
      #v[460.0 / 1403.0, 451.0 / 1403.0,  288.0 / 1403.0  ],
      #v[460.0 / 1403.0, -891.0 / 1403.0, -261.0 / 1403.0 ],
      #v[460.0 / 1403.0, -220.0 / 1403.0, -6300.0 / 1403.0]
    ]
    let rgbA := #v[p2, a, b] * matrix
    let rgbCScaled := rgbA.map inverseChromaticAdaptation
    let linrgb := rgbCScaled * LINRGB_FROM_SCALED_DISCOUNT
    if linrgb.any (·<0) then
      return 0
    else
      let fnj := (linrgb * Y_FROM_LINRGB).sum
      if fnj <= 0 then
        return 0
      else
        if (iterationRound == 4 || (fnj - y).abs < 0.002) then
          return if linrgb.any (·>100.01) then 0 else argbFromLinrgb linrgb
        else
          jRef.set (j - ((fnj - y) * j / (2 * fnj)))
  return 0

namespace HctSolver

def solveToInt (hueDegrees chroma lstar : Float) : UInt32 :=
  if (chroma < 0.0001 || lstar < 0.0001 || lstar > 99.9999) then
    argbFromLstar lstar
  else
    let hueRadians := toRadians (sanitizeDegreesDouble hueDegrees)
    let y := yFromLstar lstar
    let exactAnswer := findResultByJ hueRadians chroma y
    if exactAnswer != 0 then
      exactAnswer
    else
      let linrgb := bisectToLimit y hueRadians
      argbFromLinrgb linrgb

def solveToCam (hueDegress chroma lstar : Float) : Cam16 :=
  let argb := solveToInt hueDegress chroma lstar
  Cam16.fromInt argb

end HctSolver
