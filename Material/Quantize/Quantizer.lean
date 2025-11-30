import Material.Quantize.QuantizerResult

class Quantizer (α : Type u) where
  quantize (pixels : Array UInt32) (maxColors : UInt8) : QuantizerResult
