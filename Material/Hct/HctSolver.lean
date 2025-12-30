module
public import Material.Utils.ColorUtils
public import Material.Utils.MathUtils
public import Material.Hct.ViewingConditions

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
def TO_RGBA :=#v[
  #v[460.0 / 1403.0, 451.0 / 1403.0,  288.0 / 1403.0  ],
  #v[460.0 / 1403.0, -891.0 / 1403.0, -261.0 / 1403.0 ],
  #v[460.0 / 1403.0, -220.0 / 1403.0, -6300.0 / 1403.0]
]

def Y_FROM_LINRGB := #v[0.2126, 0.7152, 0.0722]

def chromaticAdaptation (component : Float) : Float :=
  let af := component.abs ^ 0.42
  signum component * 400.0 * af / (af + 27.13)

def inverseChromaticAdaptation (adapted : Float) : Float :=
  let adaptedAbs := adapted.abs
  let base := max 0.0 (adaptedAbs * 27.13 / (400.0 - adaptedAbs))
  signum adapted * base ^ (1.0 / 0.42)

def hueOf (linrgb : Vec3) : Float :=
  let rgbA := (linrgb * SCALED_DISCOUNT_FROM_LINRGB).map chromaticAdaptation
  let a := (#v[11.0, -12.0, 1.0] * rgbA).sum / 11.0
  let b := (#v[1.0, 1.0, -2.0] * rgbA).sum / 9.0
  b.atan2 a

def lstarSingular := ColorUtils.lstarFromY (100 * 0.2126 + 96.18310557389496 * 0.7152 + 95.47888926024586 * 0.0722)

def areInCycleOrder (a b c : Float) : Bool :=
  let deltaAB := sanitizeRadians (b - a)
  let deltaAC := sanitizeRadians (c - a)
  deltaAB < deltaAC

def nthVertex (y : Float) (n : Nat) : Vec3 :=
  let kR := Y_FROM_LINRGB[0]
  let kG := Y_FROM_LINRGB[1]
  let kB := Y_FROM_LINRGB[2]
  let coordA := if (n % 4 <= 1) then 0.0 else 100.0
  let coordB := if (n % 2 == 0) then 0.0 else 100.0
  if n < 4 then
    let g := coordA
    let b := coordB
    let r := (y - g * kG - b * kB) / kR
    #v[r, g, b]
  else if n < 8 then
    let b := coordA
    let r := coordB
    let g := (y - r * kR - b * kB) / kG
    #v[r, g, b]
  else
    let r := coordA
    let g := coordB
    let b := (y - r * kR - g * kG) / kB
    #v[r, g, b]

def nthVertexList (y : Float) : Array Vec3 :=
  let edges :=
    if y < 7.22 then
      #[0, 4, 8]
    else if y < 21.26 then
      #[0, 4, 6, 1]
    else if y < 28.48 then
      #[1, 10, 5, 4, 6]
    else if y < 71.52 then
      #[5, 4, 6, 7]
    else if y < 78.74 then
      #[5, 2, 9, 6, 7]
    else if y < 92.78 then
      #[2, 3, 7, 5]
    else
      #[3, 7, 11]
  edges.map (fun n => nthVertex y n)

def ccwDist (a b : Float) : Float :=
  (b - a + 2 * Pi) % (2 * Pi)

def bisectToSegment (y targetHue : Float) : Vector Vec3 2 :=
  let targetHue := if targetHue > Pi then targetHue - 2 * Pi else targetHue
  let vertices := nthVertexList y
  let distances := vertices.map (fun v => ccwDist targetHue (hueOf v))
  let left := vertices[argMax distances]!
  let right := vertices[argMin distances]!
  #v[left, right]

def bisectToLimit (y targetHue : Float) : Vec3 :=
  let segment := bisectToSegment y targetHue
  let left0  := segment[0]
  let right0 := segment[1]
  let hueLeft := hueOf left0
  let f (t : Float) : Vec3 :=
    left0 + t * (right0 - left0)
  let rec loop (lo hi : Float) (n : Nat) : Float :=
    match n with
    | 0 => (lo + hi) / 2
    | m + 1 =>
      let mid := (lo + hi) / 2
      let midHue := hueOf (f mid)
      if areInCycleOrder hueLeft targetHue midHue then
        loop lo mid m
      else
        loop mid hi m
  let t := loop 0.0 1.0 8
  f t

def linrgbOfJ (hueRadians chroma : Float) : Float → Vec3 :=
  let viewingConditions := DEFAULT
  let tInnerCoeff := 1 / (1.64 - 0.29 ^ (viewingConditions.n)) ^ 0.73
  let eHue := 0.25 * ((hueRadians + 2.0).cos + 3.8)
  let p1 := eHue * (50000.0 / 13.0) * viewingConditions.nc * viewingConditions.ncb
  let hSin := hueRadians.sin
  let hCos := hueRadians.cos
  fun j =>
    let jNormalized := j / 100.0
    let alpha := if j == 0.0 then 0.0 else chroma / (jNormalized.sqrt)
    let t := (alpha * tInnerCoeff).pow (1.0 / 0.9)
    let ac := viewingConditions.aw * jNormalized ^ (1.0 / viewingConditions.c / viewingConditions.z)
    let p2 := ac / viewingConditions.nbb
    let gamma := 23.0 * (p2 + 0.305) * t / (23.0 * p1 + 11.0 * t * hCos + 108.0 * t * hSin)
    let a := gamma * hCos
    let b := gamma * hSin
    let rgbA := #v[p2, a, b] * TO_RGBA
    let rgbCScaled := rgbA.map inverseChromaticAdaptation
    rgbCScaled * LINRGB_FROM_SCALED_DISCOUNT

def findResultByJ (hueRadians chroma y : Float) : UInt32 := Id.run do
  let maxIter := 5
  let tol := 0.002
  let mut j := y.sqrt * 11.0
  let linrgbFn := linrgbOfJ hueRadians chroma
  for i in Array.range maxIter do
    let linrgb := linrgbFn j
    if linrgb.any (·<0) then
      return 0
    else
      let yj := (linrgb * Y_FROM_LINRGB).sum
      let err := yj - y
      if i == maxIter - 1 || err.abs < tol then
        return if linrgb.any (·>100.01) then 0 else argbFromLinrgb linrgb
      j := j - (err * j / (2.0 * yj))
  return 0

namespace HctSolver

public def solveToInt (hueDegrees chroma lstar : Float) : UInt32 :=
  if (chroma < 0.0001 || lstar < 0.0001 || lstar >= lstarSingular) then
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

public def maxChroma (hue tone : Float) : Float :=
  let viewingConditions := DEFAULT
  let y := yFromLstar tone
  let hueRadians := toRadians (sanitizeDegreesDouble hue)
  let linrgb := bisectToLimit y hueRadians
  let rgbA := (linrgb * SCALED_DISCOUNT_FROM_LINRGB).map chromaticAdaptation
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
  c

end HctSolver
