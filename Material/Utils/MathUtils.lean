namespace MathUtils

abbrev Pi := 3.14159265358979323846

abbrev Vec3 := Vector Float 3
abbrev Mat3 := Vector (Vector Float 3) 3

def toRadians (degrees : Float) : Float :=
  degrees * Pi / 180.0

def toDegrees (radians : Float) : Float :=
  radians * 180.0 / Pi

def hypot (a b : Float) : Float :=
  (a * a + b * b).sqrt

def signum (num : Float) : Float :=
  if num < 0 then -1
  else if num > 0 then 1
  else 0

def lerp (start stop amount : Float) : Float :=
  (1 - amount) * start + amount * stop

def clampInt (min max input : UInt32) : UInt32 :=
  if input < min then min
  else if input > max then max
  else input

def clampDouble (min max input : Float) : Float :=
  if input < min then min
  else if input > max then max
  else input

def sanitizeDegreesInt (degrees : UInt32) : UInt32 := degrees % 360

instance : Mod Float where
  mod a b := a - b * Float.floor (a / b)

def sanitizeDegreesDouble (degrees : Float) : Float := degrees % 360.0

def sanitizeRadians (angle : Float) : Float := angle % (2 * Pi)

def rotationDirection (current target : Float) : Float :=
  let delta := sanitizeDegreesDouble (target - current)
  if delta <= 180.0 then 1
  else -1

def differenceDegrees (a b : Float) : Float :=
  180.0 - ((a - b).abs - 180.0).abs

instance : Mul Vec3 where
  mul v1 v2 := v1.zipWith (·*·) v2

def matrixMultiply (row : Vec3) (matrix : Mat3) : Vec3 :=
  matrix.map (fun col => (row * col).sum)

instance : HMul Vec3 Mat3 Vec3 where
  hMul row matrix := matrixMultiply row matrix

end MathUtils

namespace Vector

instance : Add (UInt32 × UInt32 × UInt32 × UInt32 × Float) where
  add a b :=
    let (a0, a1, a2, a3, a4) := a
    let (b0, b1, b2, b3, b4) := b
    (a0 + b0, a1 + b1, a2 + b2, a3 + b3, a4 + b4)

def modify (v : Vector α n) (m : Fin n) (f : α → α) : Vector α n :=
  have h : (v.toArray.modify (↑m) f).size = n := by grind
  h ▸ (v.toArray.modify m f).toVector

end Vector
