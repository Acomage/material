import Material.Utils.ColorUtils
import Material.Quantize.QuantizerResult
import Material.Utils.MathUtils

open ColorUtils

def QuantizerWu := PUnit

namespace QuantizerWu

abbrev INDEX_BITS : UInt32 := 5

abbrev INDEX_COUNT := 33

abbrev TOTAL_SIZE := 35937

structure Box where
  r0 : UInt32
  r1 : UInt32
  g0 : UInt32
  g1 : UInt32
  b0 : UInt32
  b1 : UInt32

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

def variance (cube : Box) (moments : Vector (Vector Int64 5) TOTAL_SIZE) : Float :=
  let d := (vol' cube moments).map Int64.toFloat
  let xx := d[4]
  let hypotenuse := d[0] * d[0] + d[1] * d[1] + d[2] * d[2]
  let volume := d[3]
  xx - hypotenuse / volume

def maximize (cube : Box) (direction : Direction) (first last : UInt32) (cut :ST.Ref σ UInt32) (whole_w whole_r whole_g whole_b : Int64) (moments : Vector (Vector Int64 5) TOTAL_SIZE) : ST σ Float := sorry

def cut (box1 box2 : Box) (moments : Vector (Vector Int64 5) TOTAL_SIZE) : Bool := sorry

def QuantizerWu (pixels : Array UInt32) (max_colors : UInt8) : Array UInt32 := runST fun s => do
  let momentsRef : ST.Ref s (Vector (Vector Int64 5) TOTAL_SIZE) ← ST.mkRef (Vector.replicate TOTAL_SIZE #v[0, 0, 0, 0, 0])
  constructHistogram pixels momentsRef
  computeMoments momentsRef
  sorry


def test1 (σ : Type)(ptr : ST.Ref σ Nat) : ST σ Unit :=
  ptr.set 100

def test2 : Nat := runST fun s => do
  let r ← ST.mkRef 0
  test1 s r
  r.get

#eval test2

end QuantizerWu
