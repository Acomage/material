import "color"
import "../lib/github.com/diku-dk/cpprandom/random"
import "../lib/github.com/diku-dk/sorts/radix_sort"

def MAX_ITERATIONS: u32 = 100
def MIN_DELTA_E: f32 = 3.0f32

def dist_sq (p1: [3]f32) (p2: [3]f32): f32 =
  let d0 = p1[0] - p2[0]
  let d1 = p1[1] - p2[1]
  let d2 = p1[2] - p2[2]
  in d0 * d0 + d1 * d1 + d2 * d2

def unique [n] (pixels: [n]u32): (i64, []u32, []u32) =
  let sorted = radix_sort_int u32.num_bits u32.get_bit pixels
  let flags = map2 (!=) sorted (rotate (-1) sorted)
  let flags = [false] ++ (drop 1 flags) :> [n]bool
  let indices = scan (+) 0 (map i64.bool flags)
  let num_unique = (last indices) + 1
  let unique_vals = hist (\ _ y -> y) 0 num_unique indices sorted
  let unique_counts = hist (+) 0 num_unique indices (replicate n 1u32)
  in (num_unique, unique_vals, unique_counts)

def unique' [n] (colors_out:[n]u32) (counts_out:[n]u32): ([]u32, []u32) =
  let (sorted, sorted_counts) = unzip (radix_sort_int_by_key (\s -> s.0) u32.num_bits u32.get_bit (zip colors_out counts_out))
  let flags = map2 (!=) sorted (rotate (-1) sorted)
  let flags = [false] ++ (drop 1 flags) :> [n]bool
  let indices = scan (+) 0 (map i64.bool flags)
  let num_unique = (last indices) + 1
  let unique_vals = hist (\_ y -> y) 0 num_unique indices sorted
  let unique_counts = hist (+) 0 num_unique indices sorted_counts
  in (unique_vals, unique_counts)

def build_point_data (input_pixels: []u32): (i64, [][3]f32, []u32) =
  let (num_pixels, pixels, counts) = unique input_pixels
  let points = map int_to_lab pixels
  in (num_pixels, points, counts)

module d = uniform_int_distribution i64 u32 minstd_rand
def initialize_assignments(point_count: i64)(cluster_count: i64): [point_count]i64 =
  let rng = minstd_rand.rng_from_seed [42688]
  let rngs = minstd_rand.split_rng point_count rng
  in (unzip (map (\rng -> d.rand (0, cluster_count-1) rng) rngs)).1

def best_center_pruned [k] (cc_row: [k]f32) (p: [3]f32) (cluster: [k][3]f32) (ci: i64) (dcur_sq: f32)
  : (i64, f32) =
  let thresh = 4f32 * dcur_sq
  let idxs: [k]i64 = iota k
  let (best_i, best_d) =
    reduce (\(bi, bd) (j, cc_sq) ->
              if cc_sq < thresh then
                let d = dist_sq p cluster[j]
                in if d < bd then (j, d) else (bi, bd)
              else
                (bi, bd))
           (ci, dcur_sq)
           (zip idxs cc_row)
  in (best_i, best_d)

def quantize_wsmeans (input_pixels: [][3]u8) (starting_clusters: [][3]f32): ([]u32, []u32) =
  let input_pixels = map (\rgb -> rgb_to_int (map u32.u8 rgb)) input_pixels
  let (num_points, points, counts) = build_point_data input_pixels
  let points = points :> [num_points][3]f32
  let counts = counts :> [num_points]u32
  let cluster_init = map rgb_to_lab starting_clusters
  let cluster_count = length cluster_init
  let cluster_init = cluster_init :> [cluster_count][3]f32
  let cluster_indices_init = initialize_assignments num_points cluster_count
  let (final_indices, final_clusters, _, _) =
    loop (cluster_indices, cluster, iteration, converged) =
      (cluster_indices_init, cluster_init, 0u32, false)
    while iteration < MAX_ITERATIONS && !converged do
      let cc_dist_sq : [cluster_count][cluster_count]f32 =
        map (\ci -> map (\cj -> dist_sq ci cj) cluster) cluster
      let cur_dists_sq : [num_points]f32 =
        map2 (\p ci -> dist_sq p cluster[ci]) points cluster_indices
      let (best_indices, best_dists_sq) =
        unzip <|
        map3 (\p ci dcur_sq ->
                best_center_pruned cc_dist_sq[ci] p cluster ci dcur_sq)
             points cluster_indices cur_dists_sq
      let dist_change =
        map2 (\new old -> f32.abs (f32.sqrt new - f32.sqrt old)) best_dists_sq cur_dists_sq
      let move_mask = map (\d -> d > MIN_DELTA_E) dist_change
      let any_moved = reduce (||) false move_mask
      let updated_indices = map3 (\m bi old -> if m then bi else old) move_mask best_indices cluster_indices
      let should_stop = (!any_moved) && (iteration > 0)
      in if should_stop then
           (updated_indices, cluster, iteration + 1, true)
         else
           let zero_cluster = [0f32, 0f32, 0f32]
           let cluster_weights =
             reduce_by_index (replicate cluster_count 0u32) (+) 0 updated_indices counts
           let sum_l =
             reduce_by_index (replicate cluster_count 0f32) (+) 0 updated_indices
                             (map2 (\p c -> p[0] * f32.u32 c) points counts)
           let sum_a =
             reduce_by_index (replicate cluster_count 0f32) (+) 0 updated_indices
                             (map2 (\p c -> p[1] * f32.u32 c) points counts)
           let sum_b =
             reduce_by_index (replicate cluster_count 0f32) (+) 0 updated_indices
                             (map2 (\p c -> p[2] * f32.u32 c) points counts)
           let cluster' =
             map4 (\sl sa sb w ->
                     if w == 0u32
                     then zero_cluster
                     else [sl / f32.u32 w, sa / f32.u32 w, sb / f32.u32 w])
                  sum_l sum_a sum_b cluster_weights
           in (updated_indices, cluster', iteration + 1, false)
  let final_counts = hist (+) 0 cluster_count final_indices counts
  let final_colors = map lab_to_int final_clusters
  let (colors_out, counts_out) = unzip (filter (\(_, c) -> c > 0) (zip final_colors final_counts))
  let (unique_colors, unique_counts) = unique' colors_out counts_out
  in (unique_colors, unique_counts)
