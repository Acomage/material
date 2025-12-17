-- Constants (f32 for throughput)
def eps        : f32 = (6f32/29f32) ** 3f32      -- 0.008856
def kappa      : f32 = 903.3f32                  -- 29^3/3^3
def delta      : f32 = 6f32/29f32
def delta2     : f32 = delta * delta
def inv_116    : f32 = 1f32/116f32
def pow_24     : f32 = 2.4f32
def inv_pow24  : f32 = 1f32/2.4f32
def inv_3294_6 : f32 = 1f32 / 3294.6f32
def inv_269_025: f32 = 1f32 / 269.025f32
def linear_to_xyz: [3][3]f32 = [
        [0.43394994055572506, 0.37620976990331095, 0.18984028954096394],
        [0.2126729, 0.7151522, 0.0721750],
        [0.017756582753965265, 0.10946796102238182, 0.8727754562236529]]
def xyz_to_linear: [3][3]f32 = [
        [3.079954503474, -1.5371385, -0.542815944262],
        [-0.92125825502, 1.8760108, 0.045247419479999995],
        [0.052887382398, -0.2040259, 1.151138514516]]
def linear_to_pre_af: [3][3]f32 = [
        [0.12008336906363107,  0.23896947346596065,  0.027957431695526624],
        [0.05891086930158274,  0.29785503982969913,  0.03270666258785232 ],
        [0.010146692740499652, 0.05364214490750101,  0.32979402579569106 ]]
def rgb_a_to_abuac:[4][3]f32 = [
        [1.0,                 -12.0/11.0,          1/11.0               ],
        [1.0/9.0,             1.0/9.0,             -2.0/9.0             ],
        [1.0,                 1.0,                 1.05                 ],
        [0.06783757876475698, 0.03391878938237849, 0.0016959394691189245]]


-- Too small, manully unrolled matrix-vector multiplication
def mul (mat: [3][3]f32) (vec: [3]f32) =
  [ mat[0,0]*vec[0] + mat[0,1]*vec[1] + mat[0,2]*vec[2],
    mat[1,0]*vec[0] + mat[1,1]*vec[1] + mat[1,2]*vec[2],
    mat[2,0]*vec[0] + mat[2,1]*vec[1] + mat[2,2]*vec[2]]

def mul' (mat: [4][3]f32) (vec: [3]f32) =
  [ mat[0,0]*vec[0] + mat[0,1]*vec[1] + mat[0,2]*vec[2],
    mat[1,0]*vec[0] + mat[1,1]*vec[1] + mat[1,2]*vec[2],
    mat[2,0]*vec[0] + mat[2,1]*vec[1] + mat[2,2]*vec[2],
    mat[3,0]*vec[0] + mat[3,1]*vec[1] + mat[3,2]*vec[2]]

def clamp (x: f32) : i32 = if x < 0f32 then 0i32 else if x > 255f32 then 255i32 else i32.f32 x

-- sRGB transfer
def srgb_to_linear (c: f32) : f32 =
  if c <= 10.31475f32 then c * inv_3294_6
  else ((c + 14.025f32) * inv_269_025) ** pow_24

def linear_to_srgb (c: f32) : f32 =
  if c <= 0.0031308f32 then 3294.6f32 * c
  else 269.025f32 * (c ** inv_pow24) - 14.025f32

def f_xyz (t: f32) : f32 =
  if t > eps then t ** (1f32/3f32) else (kappa * t + 16f32) * inv_116

def f_inv (t: f32) : f32 =
  if t > delta then t * t * t else 3f32 * delta2 * (t - 4f32/29f32)

def rgb_to_lab (rgb: [3]f32) : [3]f32 =
  let rgb = map srgb_to_linear rgb
  let XYZ = mul linear_to_xyz rgb
  let fxyz = map f_xyz XYZ
  let L = 116f32 * fxyz[1] - 16f32
  let a = 500f32 * (fxyz[0] - fxyz[1])
  let b2 = 200f32 * (fxyz[1] - fxyz[2])
  in [L, a, b2]

def lab_to_rgb (lab: [3]f32) : [3]i32 =
  let fy = (lab[0] + 16f32) * inv_116
  let fx = fy + lab[1] / 500f32
  let fz = fy - lab[2] / 200f32
  let XYZ = map f_inv [fx, fy, fz]
  let rgbl = mul xyz_to_linear XYZ
  in map (linear_to_srgb >-> clamp) rgbl

def int_to_rgb (c: i32) : [3]f32 =
  [ f32.i32 ((c >> 16) & 0xFF),
    f32.i32 ((c >> 8) & 0xFF),
    f32.i32 (c & 0xFF) ]

def rgb_to_int (rgb: [3]i32) : i32 =
  -16777216i32 | ((rgb[0] & 0xFF) << 16) | ((rgb[1] & 0xFF) << 8) | (rgb[2] & 0xFF)

def int_to_lab : i32 -> [3]f32 =
  int_to_rgb >-> rgb_to_lab

def lab_to_int : [3]f32 -> i32 =
  lab_to_rgb >-> rgb_to_int
