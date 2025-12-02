import Material.Utils.ColorUtils
import Material.Quantize.QuantizerResult
import Material.Utils.MathUtils

open ColorUtils

def QuantizerWu := PUnit

namespace QuantizerWu

abbrev INDEX_BITS : UInt32 := 5

abbrev INDEX_COUNT := 33

abbrev TOTAL_SIZE := 35937

abbrev MAX_COLOR := 256

structure Box where
  r0 : UInt32
  r1 : UInt32
  g0 : UInt32
  g1 : UInt32
  b0 : UInt32
  b1 : UInt32
  vol : UInt32

inductive Direction
  | kRed
  | kGreen
  | kBlue

-- TODO: prove this

/--
  since r g b is less or equal to 2^5, so ((r <<< (INDEX_BITS * 2)) + (r <<< (INDEX_BITS + 1)) + (g <<< INDEX_BITS) + r + g + b) <= 2^5*2^10 + 2^5*2^6 + 2^5*2^5 + 3*2^5 = 35936 < 35937
-/
def getIndex (r g b : UInt32) : Fin TOTAL_SIZE :=
  let n := ((r <<< (INDEX_BITS * 2)) + (r <<< (INDEX_BITS + 1)) + (g <<< INDEX_BITS) + r + g + b).toNat
  have h : n < TOTAL_SIZE := by sorry
  ⟨n, h⟩

def constructHistogram (pixels : Array UInt32) (moments : ST.Ref σ (Vector (Vector Int64 5) TOTAL_SIZE)) : ST σ Unit := do
  for pixel in pixels do
    let rgb := rgbFromArgb pixel
    let bitsToRemove := 8 - INDEX_BITS
    let indexRGB := rgb.map (fun c => (c >>> bitsToRemove) + 1)
    let index := getIndex indexRGB[0] indexRGB[1] indexRGB[2]
    let rgb64 := rgb.map (·.toNat.toInt64)
    let rgbSq := (rgb64.map (·^2)).sum
    moments.modify (fun m => m.modify index (fun x => x + (rgb64.append #v[1, rgbSq])))

def computeMoments (moments : ST.Ref σ (Vector (Vector Int64 5) TOTAL_SIZE)): ST σ Unit := do
    for hr : r in [1:INDEX_COUNT] do
      let mut area : Vector (Vector Int64 5) INDEX_COUNT := Vector.replicate INDEX_COUNT #v[0, 0, 0, 0, 0]
      for hg : g in [1:INDEX_COUNT] do
        let mut line : Vector Int64 5 := #v[0, 0, 0, 0, 0]
        for b in ((Array.finRange (INDEX_COUNT))[1:]) do
          let index := getIndex r.toUInt32 g.toUInt32 b.toNat.toUInt32
          line := line + ((←moments.get)[index])
          area := area.modify b (fun v => v + line)
          let prevIndex := getIndex (r-1).toUInt32 g.toUInt32 b.toNat.toUInt32
          moments.modify (fun m => m.modify index (fun x => m[prevIndex] + area[b]))

def top (cube : Box) (direction : Direction) (position : UInt32) (moment : Vector Int64 TOTAL_SIZE) : Int64 :=
  match direction with
  | .kRed =>
    moment[getIndex position cube.g1 cube.b1] -
    moment[getIndex position cube.g1 cube.b0] -
    moment[getIndex position cube.g0 cube.b1] +
    moment[getIndex position cube.g0 cube.b0]
  | .kGreen =>
    moment[getIndex cube.r1 position cube.b1] -
    moment[getIndex cube.r1 position cube.b0] -
    moment[getIndex cube.r0 position cube.b1] +
    moment[getIndex cube.r0 position cube.b0]
  | .kBlue =>
    moment[getIndex cube.r1 cube.g1 position] -
    moment[getIndex cube.r1 cube.g0 position] -
    moment[getIndex cube.r0 cube.g1 position] +
    moment[getIndex cube.r0 cube.g0 position]

def top' (cube : Box) (direction : Direction) (position : UInt32) (moment : Vector (Vector Int64 4) TOTAL_SIZE) : Vector Int64 4 :=
  match direction with
  | .kRed =>
    moment[getIndex position cube.g1 cube.b1] -
    moment[getIndex position cube.g1 cube.b0] -
    moment[getIndex position cube.g0 cube.b1] +
    moment[getIndex position cube.g0 cube.b0]
  | .kGreen =>
    moment[getIndex cube.r1 position cube.b1] -
    moment[getIndex cube.r1 position cube.b0] -
    moment[getIndex cube.r0 position cube.b1] +
    moment[getIndex cube.r0 position cube.b0]
  | .kBlue =>
    moment[getIndex cube.r1 cube.g1 position] -
    moment[getIndex cube.r1 cube.g0 position] -
    moment[getIndex cube.r0 cube.g1 position] +
    moment[getIndex cube.r0 cube.g0 position]

def bottom (cube : Box) (direction : Direction) (moment : Vector Int64 TOTAL_SIZE) : Int64 :=
  match direction with
  | .kRed =>
    -moment[getIndex cube.r0 cube.g1 cube.b1] +
    moment[getIndex cube.r0 cube.g1 cube.b0] +
    moment[getIndex cube.r0 cube.g0 cube.b1] -
    moment[getIndex cube.r0 cube.g0 cube.b0]
  | .kGreen =>
    -moment[getIndex cube.r1 cube.g0 cube.b1] +
    moment[getIndex cube.r1 cube.g0 cube.b0] +
    moment[getIndex cube.r0 cube.g0 cube.b1] -
    moment[getIndex cube.r0 cube.g0 cube.b0]
  | .kBlue =>
    -moment[getIndex cube.r1 cube.g1 cube.b0] +
    moment[getIndex cube.r1 cube.g0 cube.b0] +
    moment[getIndex cube.r0 cube.g1 cube.b0] -
    moment[getIndex cube.r0 cube.g0 cube.b0]

def bottom' (cube : Box) (direction : Direction) (moment : Vector (Vector Int64 4) TOTAL_SIZE) : Vector Int64 4 :=
  match direction with
  | .kRed =>
    -moment[getIndex cube.r0 cube.g1 cube.b1] +
    moment[getIndex cube.r0 cube.g1 cube.b0] +
    moment[getIndex cube.r0 cube.g0 cube.b1] -
    moment[getIndex cube.r0 cube.g0 cube.b0]
  | .kGreen =>
    -moment[getIndex cube.r1 cube.g0 cube.b1] +
    moment[getIndex cube.r1 cube.g0 cube.b0] +
    moment[getIndex cube.r0 cube.g0 cube.b1] -
    moment[getIndex cube.r0 cube.g0 cube.b0]
  | .kBlue =>
    -moment[getIndex cube.r1 cube.g1 cube.b0] +
    moment[getIndex cube.r1 cube.g0 cube.b0] +
    moment[getIndex cube.r0 cube.g1 cube.b0] -
    moment[getIndex cube.r0 cube.g0 cube.b0]

def vol (cube : Box) (moment : Vector Int64 TOTAL_SIZE) : Int64 :=
  moment[getIndex cube.r1 cube.g1 cube.b1] -
  moment[getIndex cube.r1 cube.g1 cube.b0] -
  moment[getIndex cube.r1 cube.g0 cube.b1] +
  moment[getIndex cube.r1 cube.g0 cube.b0] -
  moment[getIndex cube.r0 cube.g1 cube.b1] +
  moment[getIndex cube.r0 cube.g1 cube.b0] +
  moment[getIndex cube.r0 cube.g0 cube.b1] -
  moment[getIndex cube.r0 cube.g0 cube.b0]

def vol' (cube : Box) (moments : Vector (Vector Int64 5) TOTAL_SIZE) : Vector Int64 5 :=
  moments[getIndex cube.r1 cube.g1 cube.b1] -
  moments[getIndex cube.r1 cube.g1 cube.b0] -
  moments[getIndex cube.r1 cube.g0 cube.b1] +
  moments[getIndex cube.r1 cube.g0 cube.b0] -
  moments[getIndex cube.r0 cube.g1 cube.b1] +
  moments[getIndex cube.r0 cube.g1 cube.b0] +
  moments[getIndex cube.r0 cube.g0 cube.b1] -
  moments[getIndex cube.r0 cube.g0 cube.b0]

def vol'' (cube : Box) (moments : Vector (Vector Int64 4) TOTAL_SIZE) : Vector Int64 4 :=
  moments[getIndex cube.r1 cube.g1 cube.b1] -
  moments[getIndex cube.r1 cube.g1 cube.b0] -
  moments[getIndex cube.r1 cube.g0 cube.b1] +
  moments[getIndex cube.r1 cube.g0 cube.b0] -
  moments[getIndex cube.r0 cube.g1 cube.b1] +
  moments[getIndex cube.r0 cube.g1 cube.b0] +
  moments[getIndex cube.r0 cube.g0 cube.b1] -
  moments[getIndex cube.r0 cube.g0 cube.b0]

def variance (cube : Box) (moments : Vector (Vector Int64 5) TOTAL_SIZE) : Float :=
  let d := (vol' cube moments).map Int64.toFloat
  let xx := d[4]
  let hypotenuse := d[0] * d[0] + d[1] * d[1] + d[2] * d[2]
  let volume := d[3]
  xx - hypotenuse / volume

def maximize (cube : Box) (direction : Direction) (first last : UInt32) (cut :ST.Ref σ Int32) (wholeRgbw : Vector Int64 4) (moments : Vector (Vector Int64 4) TOTAL_SIZE) : ST σ Float := do
  let bottomRgbw := bottom' cube direction moments
  let mut max := 0.0
  cut.set (-1)
  let mut halfRgbw : Vector Int64 4 := #v[0, 0, 0, 0]
  for i in [first.toNat : last.toNat] do
    halfRgbw := halfRgbw + top' cube direction (i.toUInt32) moments
    if halfRgbw[3] = 0 then
      continue
    let mut temp := ((halfRgbw.take 3).map (·^2)).sum.toFloat / halfRgbw[3].toFloat
    halfRgbw := wholeRgbw - halfRgbw
    if halfRgbw[3] = 0 then
      continue
    temp := temp + ((halfRgbw.take 3).map (·^2)).sum.toFloat / halfRgbw[3].toFloat
    if temp > max then
      max := temp
      cut.set i.toInt32
  return max

def cut (box1 box2 : ST.Ref σ Box) (moments : Vector (Vector Int64 4) TOTAL_SIZE) : ST σ Bool := do
  let wholeRgbw := vol'' (←box1.get) moments
  let cut_r : ST.Ref σ Int32 ← ST.mkRef 0
  let cut_g : ST.Ref σ Int32 ← ST.mkRef 0
  let cut_b : ST.Ref σ Int32 ← ST.mkRef 0
  let max_r ← maximize (←box1.get) Direction.kRed ((←box1.get).r0 + 1) (←box1.get).r1 cut_r wholeRgbw moments
  let max_g ← maximize (←box1.get) Direction.kGreen ((←box1.get).g0 + 1) (←box1.get).g1 cut_g wholeRgbw moments
  let max_b ← maximize (←box1.get) Direction.kBlue ((←box1.get).b0 + 1) (←box1.get).b1 cut_b wholeRgbw moments
  let directionRef : ST.Ref σ Direction ← ST.mkRef Direction.kBlue
  if max_r >= max_g && max_r >= max_b then
    directionRef.set Direction.kRed
    if max_r <= 0 then
      return false
  else if max_g >= max_r && max_g >= max_b then
    directionRef.set Direction.kGreen
  else
    directionRef.set Direction.kBlue

  box2.modify ({· with r1 := (←box1.get).r1, g1 := (←box1.get).g1, b1 := (←box1.get).b1})
  match ←directionRef.get with
  | .kRed =>
    box1.modify ({· with r1 := (←cut_r.get).toUInt32})
    box2.modify ({· with r0 := (←cut_r.get).toUInt32, g0 := (←box1.get).g0, b0 := (←box1.get).b0})
  | .kGreen =>
    box1.modify ({· with g1 := (←cut_g.get).toUInt32})
    box2.modify ({· with r0 := (←box1.get).r0, g0 := (←cut_g.get).toUInt32, b0 := (←box1.get).b0})
  | .kBlue =>
    box1.modify ({· with b1 := (←cut_b.get).toUInt32})
    box2.modify ({· with r0 := (←box1.get).r0, g0 := (←box1.get).g0, b0 := (←cut_b.get).toUInt32})

  box1.modify (fun x => {x with vol := (x.r1 - x.r0) * (x.g1 - x.g0) * (x.b1 - x.b0)})
  box2.modify (fun x => {x with vol := (x.r1 - x.r0) * (x.g1 - x.g0) * (x.b1 - x.b0)})
  return true

def QuantizerWu (pixels : Array UInt32) (max_colors : UInt8) : Array UInt32 := runST fun s => do
  let momentsRef : ST.Ref s (Vector (Vector Int64 5) TOTAL_SIZE) ← ST.mkRef (Vector.replicate TOTAL_SIZE #v[0, 0, 0, 0, 0])
  constructHistogram pixels momentsRef
  computeMoments momentsRef
  let cubes : Vector (ST.Ref s Box) MAX_COLOR := Vector.replicate MAX_COLOR (←(ST.mkRef {r0 := 0, r1 := 0, g0 := 0, g1 := 0, b0 := 0, b1 := 0, vol := 0}))
  let volumeVariance : ST.Ref s (Vector Float MAX_COLOR) ← ST.mkRef (Vector.replicate MAX_COLOR 0.0)
  let next : ST.Ref s (Fin MAX_COLOR) ← ST.mkRef 0
  let mut i : Fin MAX_COLOR := 1
  while h : i.toNat.toUInt8 < max_colors do
    if ←(cut cubes[←next.get] cubes[i] ((←momentsRef.get).map (·.take 4))) then
      volumeVariance.modify (·.set (←next.get) (if (←cubes[←next.get].get).vol > 1 then (variance (←cubes[←next.get].get) (←momentsRef.get)) else 0.0))
      volumeVariance.modify (·.set i (if (←cubes[i].get).vol > 1 then (variance (←cubes[i].get) (←momentsRef.get)) else 0.0))
    else
      volumeVariance.modify (·.set (←next.get) 0.0)
      i := i - 1
    next.set 0
    let mut temp := (←volumeVariance.get)[0]
    for j in [1:i+1] do
      if (←volumeVariance.get)[j] > temp then
        temp := (←volumeVariance.get)[j]
        next.set j
    sorry


def test1 (σ : Type)(ptr : ST.Ref σ Nat) : ST σ Unit :=
  ptr.set 100

def test2 : Nat := runST fun s => do
  let r ← ST.mkRef 0
  test1 s r
  r.get

#eval test2

end QuantizerWu
