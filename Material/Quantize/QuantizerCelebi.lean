import Material.Quantize.QuantizerResult
import Material.Quantize.QuantizerWu
import Material.Quantize.QuantizerWsmeans

def quantizeCelebi (pixels : Array UInt32) (max_colors : UInt8) : QuantizerResult :=
  let wu_result := quantizeWu pixels max_colors
  quantizeWsmeans pixels wu_result max_colors
