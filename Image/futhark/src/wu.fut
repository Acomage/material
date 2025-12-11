-- Wu color quantisation in Futhark.
-- Entry point: quantize : [n][3]u8 -> (m, [m]i32) (ARGB packed)

def index_bits : i64 = 5
def index_count : i64 = 33
def max_color_slots : i64 = 256

type v5 = (i64, i64, i64, i64, i64)
type v4 = (i64, i64, i64, i64)
type cube = (i64, i64, i64, i64, i64, i64)

def zero5 : v5 = (0, 0, 0, 0, 0)
def zero4 : v4 = (0, 0, 0, 0)

def add5 (a: v5) (b: v5) : v5 =
  let (a0, a1, a2, a3, a4) = a
  let (b0, b1, b2, b3, b4) = b
  in (a0 + b0, a1 + b1, a2 + b2, a3 + b3, a4 + b4)

def sub5 (a: v5) (b: v5) : v5 =
  let (a0, a1, a2, a3, a4) = a
  let (b0, b1, b2, b3, b4) = b
  in (a0 - b0, a1 - b1, a2 - b2, a3 - b3, a4 - b4)

def add4 (a: v4) (b: v4) : v4 =
  let (a0, a1, a2, a3) = a
  let (b0, b1, b2, b3) = b
  in (a0 + b0, a1 + b1, a2 + b2, a3 + b3)

def sub4 (a: v4) (b: v4) : v4 =
  let (a0, a1, a2, a3) = a
  let (b0, b1, b2, b3) = b
  in (a0 - b0, a1 - b1, a2 - b2, a3 - b3)

def to4 (v: v5) : v4 =
  let (a0, a1, a2, a3, _) = v
  in (a0, a1, a2, a3)

def cube_volume ((r0, r1, g0, g1, b0, b1): cube) : i64 =
  (r1 - r0) * (g1 - g0) * (b1 - b0)

def dot_rgb4 ((r, g, b, _): v4) : i64 = r * r + g * g + b * b

def moments_prefix (m0: [index_count][index_count][index_count]v5) : [index_count][index_count][index_count]v5 =
  let zero_plane : [index_count][index_count]v5 =
    replicate index_count (replicate index_count zero5)

  let add_plane (a: [index_count][index_count]v5) (b: [index_count][index_count]v5) : [index_count][index_count]v5 =
    map2 (\row_a row_b -> map2 add5 row_a row_b) a b

  let add_line (a: [index_count]v5) (b: [index_count]v5) : [index_count]v5 =
    map2 add5 a b

  let m_r : [index_count][index_count][index_count]v5 =
    scan add_plane zero_plane m0

  let m_g : [index_count][index_count][index_count]v5 =
    map (\plane -> scan add_line (replicate index_count zero5) plane) m_r

  in map (\plane -> map (\line -> scan add5 zero5 line) plane) m_g

def compute_moments [n] (pixels: [n][3]u8) : [index_count][index_count][index_count]v5 =
  let shift : i64 = 8 - index_bits

  let zeros : [index_count][index_count][index_count]v5 =
    replicate index_count (replicate index_count (replicate index_count zero5))

  let rgb : [n](i64, i64, i64) =
    map (\pix -> (i64.u8 pix[0], i64.u8 pix[1], i64.u8 pix[2])) pixels

  let idxs : [n](i64, i64, i64) =
    map (\(r, g, b) -> ((r >> shift) + 1, (g >> shift) + 1, (b >> shift) + 1)) rgb

  let contribs : [n]v5 =
    map (\(r, g, b) ->
      let sq = r * r + g * g + b * b
      in (r, g, b, 1, sq)) rgb

  let m0 = reduce_by_index_3d zeros add5 zero5 idxs contribs

  in moments_prefix m0

def vol ((r0, r1, g0, g1, b0, b1): cube) (moment: [index_count][index_count][index_count]v4) : v4 =
  let m111 = moment[r1][g1][b1]
  let m110 = moment[r1][g1][b0]
  let m101 = moment[r1][g0][b1]
  let m100 = moment[r1][g0][b0]
  let m011 = moment[r0][g1][b1]
  let m010 = moment[r0][g1][b0]
  let m001 = moment[r0][g0][b1]
  let m000 = moment[r0][g0][b0]
  in add4 (sub4 (sub4 (sub4 m111 m110) m101) m011) (add4 (add4 m100 m010) (sub4 m001 m000))

def variance ((r0, r1, g0, g1, b0, b1): cube) (moments: [index_count][index_count][index_count]v5) : f32 =
  let m111 = moments[r1][g1][b1]
  let m110 = moments[r1][g1][b0]
  let m101 = moments[r1][g0][b1]
  let m100 = moments[r1][g0][b0]
  let m011 = moments[r0][g1][b1]
  let m010 = moments[r0][g1][b0]
  let m001 = moments[r0][g0][b1]
  let m000 = moments[r0][g0][b0]

  let d = add5 (sub5 (sub5 (sub5 m111 m110) m101) m011) (add5 (add5 m100 m010) (sub5 m001 m000))

  let (dr, dg, db, dw, dsum) = d
  in (if dw == 0 then 0.0
     else
       let hyp = dr * dr + dg * dg + db * db
       in f32.i64 dsum - (f32.i64 hyp) / f32.i64 dw)

def calculate_axis_scores [n] (half: [n]v4) (leftover: [n]v4) : (i64, f32) =
  let neg_inf = f32.neg f32.inf

  let scores : [n]f32 =
    map2 (\h l ->
            let (hr, hg, hb, hw) = h
            let (lr, lg, lb, lw) = l
            let t_half = if hw != 0 then f32.i64 (hr * hr + hg * hg + hb * hb) / f32.i64 hw else neg_inf
            let t_left = if lw != 0 then f32.i64 (lr * lr + lg * lg + lb * lb) / f32.i64 lw else neg_inf
            in t_half + t_left)
         half leftover

  let indexed = zip (iota n) scores

  let (best, best_val) = reduce_comm (\(i1, v1) (i2, v2) -> 
                           if v1 > v2 || (v1 == v2 && i1 < i2) then (i1, v1) else (i2, v2)
                         ) (-1, neg_inf) indexed

  in (if f32.isinf best_val || f32.isnan best_val || best_val < 0.0
      then (-1, -1.0)
      else (best, best_val))

def maximize ((r0, r1, g0, g1, b0, b1): cube)
       (moments4: [index_count][index_count][index_count]v4)
       : ((i64, f32), (i64, f32), (i64, f32)) =
  let m000 = moments4[r0][g0][b0]
  let m001 = moments4[r0][g0][b1]
  let m010 = moments4[r0][g1][b0]
  let m011 = moments4[r0][g1][b1]
  let m100 = moments4[r1][g0][b0]
  let m101 = moments4[r1][g0][b1]
  let m110 = moments4[r1][g1][b0]
  let m111 = moments4[r1][g1][b1]

  let whole_rgbw = add4 (sub4 (sub4 (sub4 m111 m110) m101) m011) (add4 (add4 m100 m010) (sub4 m001 m000))

  let r_cut = r0 + 1
  let (cut_r, max_r) =
    if r1 > r_cut then
      let bottom_r = add4 (sub4 m010 m011) (sub4 m001 m000)
      let r_span = r1 - r_cut
      let r_slices : [r_span]v4 =
        map (\i ->
               let idx = r_cut + i
               let m111 = moments4[idx][g1][b1]
               let m110 = moments4[idx][g1][b0]
               let m101 = moments4[idx][g0][b1]
               let m100 = moments4[idx][g0][b0]
               in add4 (sub4 (sub4 m111 m110) m101) m100) (iota r_span)
      let half = map (\x -> sub4 x bottom_r) r_slices
      let leftover = map (\x -> sub4 whole_rgbw x) half
      let (best_idx, score) = calculate_axis_scores half leftover
      in if score >= 0.0 then (r_cut + best_idx, score) else (-1, -1.0)
    else (-1, -1.0)

  let g_cut = g0 + 1
  let (cut_g, max_g) =
    if g1 > g_cut then
      let bottom_g = add4 (sub4 m100 m101) (sub4 m001 m000)
      let g_span = g1 - g_cut
      let g_slices : [g_span]v4 =
        map (\i ->
               let idx = g_cut + i
               let m111 = moments4[r1][idx][b1]
               let m110 = moments4[r1][idx][b0]
               let m011 = moments4[r0][idx][b1]
               let m010 = moments4[r0][idx][b0]
               in add4 (sub4 (sub4 m111 m110) m011) m010) (iota g_span)
      let half = map (\x -> sub4 x bottom_g) g_slices
      let leftover = map (\x -> sub4 whole_rgbw x) half
      let (best_idx, score) = calculate_axis_scores half leftover
      in if score >= 0.0 then (g_cut + best_idx, score) else (-1, -1.0)
    else (-1, -1.0)

  let b_cut = b0 + 1
  let (cut_b, max_b) =
    if b1 > b_cut then
      let bottom_b = add4 (sub4 m100 m110) (sub4 m010 m000)
      let b_span = b1 - b_cut
      let b_slices : [b_span]v4 =
        map (\i ->
               let idx = b_cut + i
               let m111 = moments4[r1][g1][idx]
               let m101 = moments4[r1][g0][idx]
               let m011 = moments4[r0][g1][idx]
               let m001 = moments4[r0][g0][idx]
               in add4 (sub4 (sub4 m111 m101) m011) m001) (iota b_span)
      let half = map (\x -> sub4 x bottom_b) b_slices
      let leftover = map (\x -> sub4 whole_rgbw x) half
      let (best_idx, score) = calculate_axis_scores half leftover
      in if score >= 0.0 then (b_cut + best_idx, score) else (-1, -1.0)
    else (-1, -1.0)

  in ((cut_r, max_r), (cut_g, max_g), (cut_b, max_b))

def argmax_prefix (vals: [max_color_slots]f32) (n: i64) : i64 =
  let indexed = zip (iota n) (take n vals)
  in (reduce_comm (\(i1, v1) (i2, v2) -> 
       if v1 > v2 || (v1 == v2 && i1 < i2) then (i1, v1) else (i2, v2)
     ) (-1, f32.neg f32.inf) indexed).0

def pack_argb ((r, g, b, w): v4) : i32 =
  let r' = if w > 0 then r / w else 0
  let g' = if w > 0 then g / w else 0
  let b' = if w > 0 then b / w else 0
  let argb64 = (255i64 << 24) | (r' << 16) | (g' << 8) | b'
  in i32.i64 argb64

def quantize_wu [n] (max_colors: i64) (pixels: [n][3]u8) : []i32 =
  let invalid = max_colors <= 0 || max_colors >= 256 || n == 0
  in if invalid then (replicate 0 0i32)
  else
    let moments = compute_moments pixels
    let moments4 : [index_count][index_count][index_count]v4 =
      map (\plane -> map (\line -> map to4 line) plane) moments

    let init_cubes : [max_color_slots]cube =
      replicate max_color_slots (0, 0, 0, 0, 0, 0)
      with [0] = (0, index_count - 1, 0, index_count - 1, 0, index_count - 1)

    let init_var : [max_color_slots]f32 =
      replicate max_color_slots 0.0
      with [0] = variance (init_cubes[0]) moments

    let loop_state =
      loop (cubes, vars, next_idx, i, max_eff, done) = (init_cubes, init_var, 0i64, 1i64, max_colors, false)
      while i < max_eff && not done do
        let cube_curr = cubes[next_idx]
        let ((cut_r, max_r), (cut_g, max_g), (cut_b, max_b)) = maximize cube_curr moments4

        let (cubes1, vars1, i_adj) =
          if max_r >= max_g && max_r >= max_b then
            let (r0, r1, g0, g1, b0, b1) = cube_curr
            in if cut_r < 0 then
                 let vars' = vars with [next_idx] = 0.0
                 in (cubes, vars', i - 1)
               else
                 let cube_new : cube = (cut_r, r1, g0, g1, b0, b1)
                 let cube_old : cube = (r0, cut_r, g0, g1, b0, b1)
                 let cubes' = cubes with [next_idx] = cube_old with [i] = cube_new
                 let vols_old = cube_volume cube_old
                 let vols_new = cube_volume cube_new
                 let vars' = vars
                             with [next_idx] = (if vols_old > 1 then variance cube_old moments else 0.0)
                             with [i] = (if vols_new > 1 then variance cube_new moments else 0.0)
                 in (cubes', vars', i)

          else if max_g >= max_r && max_g >= max_b then
            let (r0, r1, g0, g1, b0, b1) = cube_curr
            in if cut_g < 0 then
                 let vars' = vars with [next_idx] = 0.0
                 in (cubes, vars', i - 1)
               else
                 let cube_new : cube = (r0, r1, cut_g, g1, b0, b1)
                 let cube_old : cube = (r0, r1, g0, cut_g, b0, b1)
                 let cubes' = cubes with [next_idx] = cube_old with [i] = cube_new
                 let vols_old = cube_volume cube_old
                 let vols_new = cube_volume cube_new
                 let vars' = vars
                             with [next_idx] = (if vols_old > 1 then variance cube_old moments else 0.0)
                             with [i] = (if vols_new > 1 then variance cube_new moments else 0.0)
                 in (cubes', vars', i)

          else
            let (r0, r1, g0, g1, b0, b1) = cube_curr
            in if cut_b < 0 then
                 let vars' = vars with [next_idx] = 0.0
                 in (cubes, vars', i - 1)
               else
                 let cube_new : cube = (r0, r1, g0, g1, cut_b, b1)
                 let cube_old : cube = (r0, r1, g0, g1, b0, cut_b)
                 let cubes' = cubes with [next_idx] = cube_old with [i] = cube_new
                 let vols_old = cube_volume cube_old
                 let vols_new = cube_volume cube_new
                 let vars' = vars
                             with [next_idx] = (if vols_old > 1 then variance cube_old moments else 0.0)
                             with [i] = (if vols_new > 1 then variance cube_new moments else 0.0)
                 in (cubes', vars', i)

        let next_i = i_adj + 1
        let next_choice = argmax_prefix vars1 (i_adj + 1)
        let done' = vars1[next_choice] <= 0.0
        let max_eff' = if done' then i_adj + 1 else max_eff
        in (cubes1, vars1, next_choice, next_i, max_eff', done')

      let (final_cubes, _, _, _, max_eff_final, _) = loop_state
      let used = max_eff_final

    let colors =
      map (\idx -> pack_argb (vol (final_cubes[idx]) moments4)) (iota used)

    in colors
