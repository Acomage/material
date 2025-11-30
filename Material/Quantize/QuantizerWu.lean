import Material.Utils.ColorUtils
import Material.Quantize.QuantizerResult
import Material.Utils.MathUtils

open ColorUtils

def QuantizerWu := PUnit

namespace QuantizerWu

def INDEX_BITS : UInt32 := 5

def INDEX_COUNT := 33

def TOTAL_SIZE := 35937

-- TODO: prove this

/--
  since r g b is less or equal to 2^5, so ((r <<< (INDEX_BITS * 2)) + (r <<< (INDEX_BITS + 1)) + (g <<< INDEX_BITS) + r + g + b) <= 2^5*2^10 + 2^5*2^6 + 2^5*2^5 + 3*2^5 = 35936 < 35937
-/
def getIndex (r g b : UInt32) : Fin TOTAL_SIZE :=
  let n := ((r <<< (INDEX_BITS * 2)) + (r <<< (INDEX_BITS + 1)) + (g <<< INDEX_BITS) + r + g + b).toNat
  have h : n < TOTAL_SIZE := by sorry
  ⟨n, h⟩

def constructHistogram (pixels : Array UInt32) (weights momentsR momentsG momentsB : ST.Ref σ (Vector UInt32 TOTAL_SIZE)) (moments : ST.Ref σ (Vector Float TOTAL_SIZE)) : ST σ Unit := do
  for pixel in pixels do
    let r := redFromArgb pixel
    let g := greenFromArgb pixel
    let b := blueFromArgb pixel
    let bitsToRemove := 8 - INDEX_BITS
    let indexR := (r >>> bitsToRemove) + 1
    let indexG := (g >>> bitsToRemove) + 1
    let indexB := (b >>> bitsToRemove) + 1
    let index := getIndex indexR indexG indexB
    weights.modify (fun w => w.modify index (· + 1))
    momentsR.modify (fun m => m.modify index (· + r))
    momentsG.modify (fun m => m.modify index (· + g))
    momentsB.modify (fun m => m.modify index (· + b))
    moments.modify (fun m => m.modify index (· + (r * r + g * g + b * b).toFloat))


def computeMoments (weights momentsR momentsG momentsB : ST.Ref σ (Vector UInt32 TOTAL_SIZE)) (moments : ST.Ref σ (Vector Float TOTAL_SIZE)): ST σ Unit := sorry


def QuantizerWu (pixels : Array UInt32) (max_colors : UInt8) : Array UInt32 := runST fun s => do
  let weightsRef : ST.Ref s (Vector UInt32 TOTAL_SIZE) ← ST.mkRef (Vector.replicate TOTAL_SIZE 0)
  let momentsRedRef : ST.Ref s (Vector UInt32 TOTAL_SIZE) ← ST.mkRef (Vector.replicate TOTAL_SIZE 0)
  let momentsGreenRef : ST.Ref s (Vector UInt32 TOTAL_SIZE) ← ST.mkRef (Vector.replicate TOTAL_SIZE 0)
  let momentsBlueRef : ST.Ref s (Vector UInt32 TOTAL_SIZE) ← ST.mkRef (Vector.replicate TOTAL_SIZE 0)
  let momentsRef : ST.Ref s (Vector Float TOTAL_SIZE) ← ST.mkRef (Vector.replicate TOTAL_SIZE 0.0)
  constructHistogram pixels weightsRef momentsRedRef momentsGreenRef momentsBlueRef momentsRef
  computeMoments weightsRef momentsRedRef momentsGreenRef momentsBlueRef momentsRef
  sorry


def test1 (σ : Type)(ptr : ST.Ref σ Nat) : ST σ Unit :=
  ptr.set 100

def test2 : Nat := runST fun s => do
  let r ← ST.mkRef 0
  test1 s r
  r.get

#eval test2

end QuantizerWu
