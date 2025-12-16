import "wu"
import "wsmeans"

def quantize_celebi (max_color: i64) (input_pixels: [][3]u8): (i64, []i32, []i32) =
  let palette = quantize_wu max_color input_pixels
  let (num, colors, counts) = quantize_wsmeans input_pixels palette
  in (num, colors, counts)
