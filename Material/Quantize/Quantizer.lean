import Material.Quantize.QuantizerResult

class Quantizer (α : Type u) where
  quantize (pixels : Array Int32) (maxColors : Int32) : QuantizerResult
