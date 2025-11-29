import Material.Utils.ColorUtils
import Material.Quantize.QuantizerMap
import Material.Quantize.QuantizerResult
import Material.Utils.ColorUtils

def QuantizerWu := PUnit

namespace QuantizerWu

def INDEX_BITS := 5

def INDEX_COUNT := 33

def TOTAL_SIZE := 35937

def ConstructHistogram (pixels : Array Int32) (weights momentsR momentsG momentsB : ST.Ref σ (Array Int32)) (moments : ST.Ref σ (Array Float)) : ST σ Unit :=
  sorry



def test1 (σ : Type)(ptr : ST.Ref σ Nat) : ST σ Unit :=
  ptr.set 100

def test2 : Nat := runST fun s => do
  let r ← ST.mkRef 0
  test1 s r
  r.get

#eval test2





































































































end QuantizerWu
