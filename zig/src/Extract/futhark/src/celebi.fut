import "wu"
import "wsmeans"

entry quantize_celebi (max_color: i64) (input_pixels: [][3]u8): ([]u32, []u32) =
  let palette = quantize_wu max_color input_pixels
  let (colors, counts) = quantize_wsmeans input_pixels palette
  in (colors, counts)
