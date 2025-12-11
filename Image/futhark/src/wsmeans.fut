import "color"
import "../lib/github.com/diku-dk/sorts/radix_sort"
-- import "../lib/github.com/diku-dk/containers/arraymap"

def MAX_ITERATIONS: i32 = 50
def MIN_MOVE_RATIO: f32 = 0.005f32  -- 0.5% movement threshold

def dist_sq (p1: [3]f32) (p2: [3]f32): f32 =
  let d0 = p1[0] - p2[0]
  let d1 = p1[1] - p2[1]
  let d2 = p1[2] - p2[2]
  in d0 * d0 + d1 * d1 + d2 * d2

def unique [n] (pixels: [n]i32): (i64, []i32, []i32) =
  let sorted = radix_sort_int i32.num_bits i32.get_bit pixels
  let flags = map2 (!=) sorted (rotate (-1) sorted)
  let flags = [true] ++ (drop 1 flags) :> [n]bool
  let indices = scan (+) 0 (map i64.bool flags)
  let num_unique = last indices
  let indices = map (\x -> x - 1) indices
  let dest_vals = replicate num_unique 0i32
  let dest_counts = replicate num_unique 0i32
  let unique_vals = reduce_by_index dest_vals (\_ y -> y) 0 indices sorted
  let unique_counts = reduce_by_index dest_counts (+) 0 indices (replicate n 1)
  in (num_unique, unique_vals, unique_counts)

def build_point_data (input_pixels: []i32): (i64, [][3]f32, []i32) =
  let (num_pixels, pixels, counts) = unique input_pixels
  let points = map int_to_lab pixels
  in (num_pixels, points, counts)

-- Find nearest cluster for each point (used for initialization)
def assign_nearest [n] [k] (points: [n][3]f32) (clusters: [k][3]f32): [n]i64 =
  map (\p ->
    let (best_idx, _) = reduce_comm (\(bi, bd) (idx, d) -> if d < bd then (idx, d) else (bi, bd))
                                    (0i64, f32.inf)
                                    (zip (iota k) (map (\c -> dist_sq p c) clusters))
    in best_idx
  ) points

def quantize_wsmeans(input_pixels: [][3]u8)(starting_clusters: []i32): (i64, []i32, []i32) =
    let input_pixels = map (\rgb -> rgb_to_int (map i32.u8 rgb)) input_pixels
    let (num_points, points, counts) = build_point_data input_pixels
    let points = points :> [num_points][3]f32
    let counts = counts :> [num_points]i32
    let cluster_init = map int_to_lab starting_clusters
    let cluster_count = length cluster_init
    let cluster_init = cluster_init :> [cluster_count][3]f32
    -- Use nearest-neighbor initialization instead of random
    let cluster_indices_init = assign_nearest points cluster_init
    let total_weight = reduce_comm (+) 0 counts
    let (final_indices, final_clusters, _, _) =
      loop (cluster_indices, cluster, iteration, converged) =
        (cluster_indices_init, cluster_init, 0i32, false)
      while iteration < MAX_ITERATIONS && !converged do
        let distances: [num_points][cluster_count]f32 =
          map (\p -> map (\c -> dist_sq p c) cluster) points
        let (best_indices, _) = unzip (
          map (\ds ->
            reduce_comm (\(bi, bd) (idx, d) -> if d < bd then (idx, d) else (bi, bd))
                   (0i64, f32.inf)
                   (zip (iota cluster_count) ds)
          ) distances)
        -- Calculate weight of moved points
        let move_mask = map2 (!=) best_indices cluster_indices
        let moved_weight = reduce_comm (+) 0 (map3 (\m c w -> if m then w else 0) move_mask cluster_indices counts)
        let move_ratio = f32.i32 moved_weight / f32.i32 total_weight
        let converged' = move_ratio < MIN_MOVE_RATIO
        in if converged' && iteration > 0 then
          (cluster_indices, cluster, iteration + 1, true)
          else
            let zero_cluster = [0f32, 0f32, 0f32]
            let cluster_weights =
              reduce_by_index (replicate cluster_count 0i32) (+) 0 best_indices counts
            let sum_l = reduce_by_index (replicate cluster_count 0f32) (+) 0 best_indices (map2 (\p c -> p[0] * f32.i32 c) points counts)
            let sum_a = reduce_by_index (replicate cluster_count 0f32) (+) 0 best_indices (map2 (\p c -> p[1] * f32.i32 c) points counts)
            let sum_b = reduce_by_index (replicate cluster_count 0f32) (+) 0 best_indices (map2 (\p c -> p[2] * f32.i32 c) points counts)
            let safe_weights = map (\w -> if w == 0 then 1i32 else w) cluster_weights
            let cluster' =
            map4 (\sl sa sb w -> if w == 0 then zero_cluster else [sl / f32.i32 w, sa / f32.i32 w, sb / f32.i32 w])
                 sum_l sum_a sum_b safe_weights
            in (best_indices, cluster', iteration + 1, false)
    let final_counts = hist (+) 0 cluster_count final_indices counts
    let final_colors = map lab_to_int final_clusters
    let (colors_out, counts_out) = unzip (filter (\(_, c) -> c > 0) (zip final_colors final_counts))
    let len = length colors_out
    in (len, colors_out, counts_out)
