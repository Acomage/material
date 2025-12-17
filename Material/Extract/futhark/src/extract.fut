import "celebi"
import "score"

entry extract_colors_and_scores(max_color: i64)(input_pixels: [][3]u8): (i64, []i32, []f32) =
  let (colors, counts) = quantize_celebi max_color input_pixels
  let (sorted_colors, sorted_hues) = ranked_suggestions colors counts
  let num = length sorted_colors
  in (num, sorted_colors, sorted_hues)
