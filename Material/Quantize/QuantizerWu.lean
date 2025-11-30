import Material.Utils.ColorUtils
import Material.Quantize.QuantizerResult
import Material.Utils.MathUtils

open ColorUtils

def QuantizerWu := PUnit

namespace QuantizerWu

abbrev INDEX_BITS : UInt32 := 5

abbrev INDEX_COUNT := 33

abbrev TOTAL_SIZE := 35937

-- TODO: prove this

/--
  since r g b is less or equal to 2^5, so ((r <<< (INDEX_BITS * 2)) + (r <<< (INDEX_BITS + 1)) + (g <<< INDEX_BITS) + r + g + b) <= 2^5*2^10 + 2^5*2^6 + 2^5*2^5 + 3*2^5 = 35936 < 35937
-/
def getIndex (r g b : UInt32) : Fin TOTAL_SIZE :=
  let n := ((r <<< (INDEX_BITS * 2)) + (r <<< (INDEX_BITS + 1)) + (g <<< INDEX_BITS) + r + g + b).toNat
  have h : n < TOTAL_SIZE := by sorry
  ⟨n, h⟩

def constructHistogram (pixels : Array UInt32) (moments : ST.Ref σ (Vector (UInt32 × UInt32 × UInt32 × UInt32 × Float) TOTAL_SIZE)) : ST σ Unit := do
  for pixel in pixels do
    let rgb := rgbFromArgb pixel
    let bitsToRemove := 8 - INDEX_BITS
    let indexRGB := rgb.map (fun c => (c >>> bitsToRemove) + 1)
    let index := getIndex indexRGB[0] indexRGB[1] indexRGB[2]
    moments.modify (fun m => m.modify index fun (w, mr, mg, mb, ms) => (w + 1, mr + rgb[0], mg + rgb[1], mb + rgb[2], ms + (rgb[0] * rgb[0] + rgb[1] * rgb[1] + rgb[2] * rgb[2]).toFloat))


/- def computeMoments (weights momentsR momentsG momentsB : ST.Ref σ (Vector UInt32 TOTAL_SIZE)) (moments : ST.Ref σ (Vector Float TOTAL_SIZE)): ST σ Unit := sorry -/
def computeMoments (moments : ST.Ref σ (Vector (UInt32 × UInt32 × UInt32 × UInt32 × Float) TOTAL_SIZE)): ST σ Unit := do
    for hr : r in [1:INDEX_COUNT] do
      let mut area : Vector (UInt32 × UInt32 × UInt32 × UInt32 × Float) INDEX_COUNT := Vector.replicate INDEX_COUNT (0, 0, 0, 0, 0.0)
      for hg : g in [1:INDEX_COUNT] do
        let mut line : UInt32 × UInt32 × UInt32 × UInt32 × Float := (0, 0, 0, 0, 0.0)
        for b in ((Array.finRange (INDEX_COUNT))[1:]) do
          let index := getIndex r.toUInt32 g.toUInt32 b.toNat.toUInt32
          line := line + ((←moments.get)[index])
          area := area.modify b (fun v => v + line)
          let prevIndex := getIndex (r-1).toUInt32 g.toUInt32 b.toNat.toUInt32
          moments.modify (fun m => m.modify index (fun x => m[prevIndex] + area[b]))

def QuantizerWu (pixels : Array UInt32) (max_colors : UInt8) : Array UInt32 := runST fun s => do
  let momentsRef : ST.Ref s (Vector (UInt32 × UInt32 × UInt32 × UInt32 × Float) TOTAL_SIZE) ← ST.mkRef (Vector.replicate TOTAL_SIZE (0, 0, 0, 0, 0.0))
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
