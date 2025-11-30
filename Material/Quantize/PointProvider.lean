import Material.Utils.MathUtils

open MathUtils

class PointProvider (α : Type u) where
  fromInt (argb : UInt32) : Vec3
  toInt (point : Vec3) : UInt32
  distance (c1 c2 : Vec3) : Float
