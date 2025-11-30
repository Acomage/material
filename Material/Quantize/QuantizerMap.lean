import Material.Quantize.Quantizer
import Material.Quantize.QuantizerResult

-- TODO : delete Quantizer if not used elsewhere

/--
  I don't know if the QuantizerMap is the only
  instance of Quantizer. If it is, I will delete Quantizer.
  just use QuantizerMap directly.
-/
def QuantizerMap := PUnit

namespace QuantizerMap

def quantize (pixels : Array UInt32) (_ : UInt8) : QuantizerResult := runST fun s => do
  let pixelByCountRef : (ST.Ref s (Std.HashMap UInt32 UInt32)) ← ST.mkRef Std.HashMap.emptyWithCapacity
  for pixel in pixels do
    let currentPixelCount := (←pixelByCountRef.get)[pixel]?
    let newPixelCount := match currentPixelCount with
      | none => 1
      | some count => count + 1
    pixelByCountRef.modify (fun map => map.insert pixel newPixelCount)
  return ⟨←pixelByCountRef.get⟩

instance : Quantizer QuantizerMap where
  quantize := quantize

end QuantizerMap
