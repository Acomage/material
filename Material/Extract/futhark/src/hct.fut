import "color"

type cam = {
  hue:f32,
  chroma:f32,
}

def int_to_cam(color: i32):cam =
  let rgb = int_to_rgb color
  let linear_rgb = map srgb_to_linear rgb
  let pre_af = mul linear_to_pre_af linear_rgb
  let rgb_af = map (\paf -> (f32.abs paf) ** 0.42) pre_af
  let rgb_a = map2 (\paf af -> (f32.sgn paf) * 400 * af / (af + 27.13)) pre_af rgb_af
  let abuac = mul' rgb_a_to_abuac rgb_a
  let a = abuac[0]
  let b = abuac[1]
  let u = abuac[2]
  let ac = abuac[3]
  let radians = f32.atan2 b a
  let degrees = radians * 180f32 / f32.pi
  -- let hue = degrees % 360.0
  let hue = if degrees < 0f32 then degrees + 360f32 else degrees
  let hue_radians = hue * f32.pi / 180f32
  let jdiv100 = ac ** 1.317326989131661
  let sqrtjdiv100 = f32.sqrt jdiv100
  let hue_prime = if hue < 20.14f32 then hue_radians + 2 * f32.pi + 2 else hue_radians + 2
  let p1 = 977.8069759615383 * (f32.cos hue_prime) + 3715.666508653846
  let t = p1 * (f32.sqrt (a * a + b * b)) / (u + 0.305f32)
  let c = (t ** 0.9) * 0.8834525553575613 * sqrtjdiv100
  in {hue=hue, chroma=c}
