import "hct"
import "../lib/github.com/diku-dk/sorts/radix_sort"

def target_chroma = 48.0f32
def weight_proportion = 0.7f32
def weight_chroma_above = 0.3f32
def weight_chroma_below = 0.1f32
def cutoff_chroma = 5.0f32
def cutoff_excited_proportion = 0.01f32

def ranked_suggestions (colors:[]u32)(populations:[]u32): ([]u32, []f32) =
  let colors_cam = map int_to_cam colors
  let hues = map (.hue) colors_cam
  let huesi64 = map i64.f32 hues
  let polulation_sum = f32.u32 (u32.sum populations)
  let hue_population = hist (+) 0 360 huesi64 populations
  let proportions = map (\hp -> f32.u32 hp / polulation_sum) hue_population
  let (indices, values) =
    tabulate_2d 360 30 (\hue offset ->
      (((hue + offset - 14)%360), proportions[hue])
    ) |> flatten |> unzip
  let hue_excited_proportions = hist (+) 0 360 indices values
  let (colors_cam_filted,
       huesi64_filted,
       hues_filted,
       colors_filted) = (filter (\x -> x.0.chroma >= cutoff_chroma
                                 && hue_excited_proportions[x.1] > cutoff_excited_proportion) (zip4 colors_cam huesi64 hues colors)) |> unzip4
  let scored_cams = map2 (\h hue ->
    let proportion = hue_excited_proportions[hue]
    let proportion_score = proportion * 100.0f32 * weight_proportion
    let chroma_weight = if h.chroma < target_chroma
                        then weight_chroma_below
                        else weight_chroma_above
    let chroma_score = (h.chroma - target_chroma) * chroma_weight
    in proportion_score + chroma_score
  ) colors_cam_filted huesi64_filted
  let (_, sorted_colors, sorted_hues) =
    unzip3 (radix_sort_float_by_key (\s -> -s.0) f32.num_bits f32.get_bit (zip3 scored_cams colors_filted hues_filted))
  in (sorted_colors, sorted_hues)
